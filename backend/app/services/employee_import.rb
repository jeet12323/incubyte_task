require "csv"

# Imports employees from the Excel workbook that the export produces (or a CSV with the same
# EmployeeSpreadsheet columns). Rows are matched on email: a known email updates that employee, a
# new one creates an employee.
#
# All or nothing: every row is validated first, and if any row is invalid nothing is written and the
# row-numbered errors are returned so HR can fix the file in Excel and upload it again.
class EmployeeImport
  REQUIRED_HEADERS = (EmployeeSpreadsheet::HEADERS - [ "currency" ]).freeze
  MAX_ROWS = 20_000
  MAX_ERRORS_REPORTED = 100
  SALARY_FORMAT = /\A\d+(\.\d{1,2})?\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/
  XLSX_SIGNATURE = "PK\x03\x04".b # .xlsx files are zip archives
  XLS_SIGNATURE = "\xD0\xCF\x11\xE0".b # the old binary .xls format

  class InvalidFile < StandardError; end

  Result = Data.define(:created, :updated, :unchanged, :errors, :error_count) do
    def success? = error_count.zero?
  end

  def initialize(content)
    @content = content.to_s
  end

  def call
    rows = parse
    emails = rows.map { |_line, row| normalize_email(row["email"]) }.uniq
    existing = Employee.where(email: emails).index_by(&:email)
    seen_emails = {}
    errors = []
    to_create = []
    to_update = []
    unchanged = 0

    rows.each do |line, row|
      employee, messages = build(row, existing, seen_emails, line)
      if messages.any?
        errors << { row: line, email: row["email"].to_s.strip, messages: }
      elsif employee.new_record?
        to_create << employee
      elsif employee.changed?
        to_update << employee
      else
        unchanged += 1
      end
    end

    return Result.new(0, 0, 0, errors.first(MAX_ERRORS_REPORTED), errors.size) if errors.any?

    write(to_create, to_update)
    Result.new(to_create.size, to_update.size, unchanged, [], 0)
  end

  private

  attr_reader :content

  def xlsx?
    content.b.start_with?(XLSX_SIGNATURE)
  end

  # Returns [[spreadsheet row number, { "header" => "text" }], ...]. The header is row 1, as in Excel.
  def parse
    if content.b.start_with?(XLS_SIGNATURE)
      raise InvalidFile, "This is an old .xls file. Save it as .xlsx (Excel Workbook) and upload it again"
    end

    headers, rows = xlsx? ? read_xlsx : read_csv
    missing = REQUIRED_HEADERS - headers
    raise InvalidFile, "Missing columns: #{missing.join(', ')}" if missing.any?
    raise InvalidFile, "The file has no employee rows" if rows.empty?
    raise InvalidFile, "The file has more than #{MAX_ROWS} rows" if rows.size > MAX_ROWS

    rows
  end

  def read_xlsx
    Tempfile.create([ "employee-import", ".xlsx" ], binmode: true) do |file|
      file.write(content)
      file.flush
      sheet = Roo::Excelx.new(file.path).sheet(0)
      return [ [], [] ] unless sheet.first_row

      headers = sheet.row(sheet.first_row).map { |header| header.to_s.strip.downcase }
      rows = ((sheet.first_row + 1)..sheet.last_row).filter_map do |line|
        values = sheet.row(line).map { |value| cell_text(value) }
        [ line, headers.zip(values).to_h ] if values.any?(&:present?)
      end
      [ headers, rows ]
    end
  rescue StandardError => error
    raise if error.is_a?(InvalidFile)

    raise InvalidFile, "This Excel file couldn't be read. Export a fresh file and try again"
  end

  # Excel cells come back typed; turn them into the same text a CSV cell would hold.
  def cell_text(value)
    case value
    when Date then value.iso8601 # also DateTime
    when Time then value.to_date.iso8601
    when Float then value == value.floor ? value.to_i.to_s : value.to_s
    else value.to_s
    end
  end

  def read_csv
    text = content.dup.force_encoding(Encoding::UTF_8)
    raise InvalidFile, "Save the file as \"CSV UTF-8\" and upload it again" unless text.valid_encoding?

    table = CSV.parse(text.delete_prefix("﻿"), headers: true, skip_blanks: true)
    headers = table.headers.compact.map { |header| header.strip.downcase }
    rows = table.each.with_index(2).map do |row, line|
      [ line, row.to_h.transform_keys { |key| key.to_s.strip.downcase } ]
    end
    [ headers, rows ]
  rescue CSV::MalformedCSVError => error
    raise InvalidFile, "This is not a valid CSV file (#{error.message})"
  end

  def build(row, existing, seen_emails, line)
    values = row.transform_values { |value| value.to_s.strip }
    email = normalize_email(values["email"])
    messages = []

    if email.present? && seen_emails.key?(email)
      messages << "Email is also used on row #{seen_emails[email]}"
    elsif email.present?
      seen_emails[email] = line
    end

    employee = existing[email] || Employee.new
    employee.skip_email_uniqueness_check = true
    employee.assign_attributes(values.slice("email", "full_name", "job_title", "department", "country_code"))
    employee.employment_type = values["employment_type"].downcase.tr(" -", "__") if values["employment_type"].present?

    salary = values["salary"].delete(", ")
    if salary.match?(SALARY_FORMAT)
      employee.salary = salary
    else
      messages << "Salary must be a number like 85000 or 85000.50"
    end

    if (date = parse_date(values["hire_date"]))
      employee.hire_date = date
    else
      messages << date_message
    end

    employee.validate
    skipped = messages.any? { |m| m.start_with?("Salary") } ? [ :salary ] : []
    skipped << :hire_date if messages.any? { |m| m.start_with?("Hire date") }
    messages += employee.errors.reject { |error| skipped.include?(error.attribute) }.map(&:full_message)

    currency = values["currency"]
    if currency.present? && employee.currency && currency.upcase != employee.currency
      messages << "Currency #{currency} doesn't match #{employee.country.name} (#{employee.currency})"
    end

    [ employee, messages ]
  end

  def write(to_create, to_update)
    columns = %w[email full_name job_title department country_code salary employment_type hire_date]

    Employee.transaction do
      Employee.insert_all!(to_create.map { |employee| employee.attributes.slice(*columns) }) if to_create.any?
      if to_update.any?
        Employee.upsert_all(to_update.map { |employee| employee.attributes.slice("id", *columns) },
                            unique_by: :id, update_only: columns)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    raise InvalidFile, "Someone added one of these emails while the file was importing. Upload it again."
  end

  def date_message
    message = "Hire date must be a date in YYYY-MM-DD format"
    return message if xlsx?

    # Excel rewrites dates in the user's locale when it saves CSV, which is the usual cause.
    "#{message}. Excel changes dates when it saves CSV, so import the .xlsx export instead"
  end

  def parse_date(value)
    Date.iso8601(value) if value.match?(DATE_FORMAT)
  rescue Date::Error
    nil
  end

  def normalize_email(email)
    email.to_s.strip.downcase
  end
end

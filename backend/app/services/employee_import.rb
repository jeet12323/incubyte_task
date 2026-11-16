require "csv"

# Imports employees from a CSV file (the EmployeeCsv format). Rows are matched on email: a known email
# updates that employee, a new one creates an employee.
#
# All or nothing: every row is validated first, and if any row is invalid nothing is written and the
# row-numbered errors are returned so HR can fix the file in Excel and upload it again.
class EmployeeImport
  REQUIRED_HEADERS = (EmployeeCsv::HEADERS - [ "currency" ]).freeze
  MAX_ROWS = 20_000
  MAX_ERRORS_REPORTED = 100
  SALARY_FORMAT = /\A\d+(\.\d{1,2})?\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  class InvalidFile < StandardError; end

  Result = Data.define(:created, :updated, :unchanged, :errors, :error_count) do
    def success? = error_count.zero?
  end

  def initialize(csv_text)
    @csv_text = csv_text
  end

  def call
    rows = parse
    existing = Employee.where(email: rows.map { |row| normalize_email(row["email"]) }.uniq).index_by(&:email)
    seen_emails = {}
    errors = []
    to_create = []
    to_update = []
    unchanged = 0

    rows.each.with_index(2) do |row, line| # line 1 is the header, as in Excel
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

  attr_reader :csv_text

  def parse
    text = csv_text.to_s.dup.force_encoding(Encoding::UTF_8)
    raise InvalidFile, "Save the file as \"CSV UTF-8\" and upload it again" unless text.valid_encoding?

    table = CSV.parse(text.delete_prefix("﻿"), headers: true, skip_blanks: true)
    headers = table.headers.compact.map { |header| header.strip.downcase }
    missing = REQUIRED_HEADERS - headers
    raise InvalidFile, "Missing columns: #{missing.join(', ')}" if missing.any?
    raise InvalidFile, "The file has no employee rows" if table.empty?
    raise InvalidFile, "The file has more than #{MAX_ROWS} rows" if table.size > MAX_ROWS

    table.map { |row| row.to_h.transform_keys { |key| key.to_s.strip.downcase } }
  rescue CSV::MalformedCSVError => error
    raise InvalidFile, "This is not a valid CSV file (#{error.message})"
  end

  def build(row, existing, seen_emails, line)
    values = row.transform_values { |value| EmployeeCsv.unescape_formula(value.to_s.strip) }
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
      messages << "Hire date must be a date in YYYY-MM-DD format"
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

  def parse_date(value)
    Date.iso8601(value) if value.match?(DATE_FORMAT)
  rescue Date::Error
    nil
  end

  def normalize_email(email)
    email.to_s.strip.downcase
  end
end

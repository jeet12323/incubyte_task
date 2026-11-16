# The employee file HR moves in and out of Excel. Export writes it and EmployeeImport reads it,
# so an exported workbook can be edited and imported back unchanged.
#
# It is a real .xlsx rather than CSV because Excel rewrites CSV dates in the user's locale
# (2024-03-01 comes back as 01-03-2024) and CSV can't carry column widths or cell types.
module EmployeeSpreadsheet
  Column = Data.define(:key, :width, :type)

  COLUMNS = [
    Column.new(:email, 34, :string),
    Column.new(:full_name, 26, :string),
    Column.new(:job_title, 28, :string),
    Column.new(:department, 20, :string),
    Column.new(:country_code, 14, :string),
    Column.new(:currency, 11, :string),
    Column.new(:salary, 16, :salary),
    Column.new(:employment_type, 18, :string),
    Column.new(:hire_date, 14, :date)
  ].freeze
  HEADERS = COLUMNS.map { |column| column.key.to_s }.freeze
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  module_function

  # Returns the .xlsx file as a binary string.
  def generate(scope)
    rows = scope.pluck(:email, :full_name, :job_title, :department, :country_code,
                       :salary, :employment_type, :hire_date)

    package = Axlsx::Package.new
    package.use_shared_strings = true
    workbook = package.workbook
    styles = cell_styles(workbook)

    workbook.add_worksheet(name: "Employees") do |sheet|
      sheet.add_row HEADERS, style: styles[:header]
      rows.each do |email, full_name, job_title, department, country_code, salary, employment_type, hire_date|
        sheet.add_row [ email, full_name, job_title, department, country_code,
                        Country.find(country_code)&.currency, salary.to_f, employment_type, hire_date ],
                      # Explicit types: text is never read as a formula, dates are real date cells.
                      types: COLUMNS.map { |column| cell_type(column) },
                      style: COLUMNS.map { |column| styles[column.type] }
      end
      sheet.column_widths(*COLUMNS.map(&:width))
      sheet.sheet_view.pane do |pane|
        pane.state = :frozen
        pane.y_split = 1
        pane.top_left_cell = "A2"
      end
      sheet.auto_filter = "A1:#{Axlsx.cell_r(COLUMNS.size - 1, [ rows.size, 1 ].max)}"
    end

    package.to_stream.read
  end

  def cell_styles(workbook)
    workbook.styles.then do |s|
      { header: s.add_style(b: true, bg_color: "E7ECF7"),
        string: nil,
        salary: s.add_style(num_fmt: 4), # #,##0.00
        date: s.add_style(format_code: "yyyy-mm-dd") }
    end
  end

  def cell_type(column)
    { string: :string, salary: :float, date: :date }.fetch(column.type)
  end
end

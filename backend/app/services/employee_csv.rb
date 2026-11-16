require "csv"

# The CSV format HR uses to move data in and out of Excel. Export and import share these columns,
# so an exported file can be edited and imported back unchanged.
module EmployeeCsv
  HEADERS = %w[email full_name job_title department country_code currency salary employment_type hire_date].freeze
  # A cell starting with one of these is run as a formula by Excel, so it's prefixed with a quote on export.
  FORMULA_PREFIXES = [ "=", "+", "-", "@", "\t", "\r" ].freeze

  module_function

  def generate(scope)
    rows = scope.pluck(:email, :full_name, :job_title, :department, :country_code,
                       :salary, :employment_type, :hire_date)

    CSV.generate(headers: HEADERS, write_headers: true) do |csv|
      rows.each do |email, full_name, job_title, department, country_code, salary, employment_type, hire_date|
        csv << [ email, full_name, job_title, department, country_code, Country.find(country_code)&.currency,
                 format("%.2f", salary), employment_type, hire_date.iso8601 ].map { |value| escape_formula(value) }
      end
    end
  end

  def escape_formula(value)
    value.is_a?(String) && value.start_with?(*FORMULA_PREFIXES) ? "'#{value}" : value
  end

  def unescape_formula(value)
    value.start_with?("'") && value[1..].start_with?(*FORMULA_PREFIXES) ? value[1..] : value
  end
end

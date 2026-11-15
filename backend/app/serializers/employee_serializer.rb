# Shapes an Employee for the API. Kept explicit so the JSON contract is visible in one place.
module EmployeeSerializer
  module_function

  def call(employee)
    {
      id: employee.id,
      full_name: employee.full_name,
      email: employee.email,
      job_title: employee.job_title,
      department: employee.department,
      country_code: employee.country_code,
      country_name: employee.country&.name,
      currency: employee.currency,
      salary: employee.salary.to_f,
      salary_usd: employee.salary_in_usd,
      employment_type: employee.employment_type,
      hire_date: employee.hire_date&.iso8601,
      updated_at: employee.updated_at&.iso8601
    }
  end
end

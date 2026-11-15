class Employee < ApplicationRecord
  DEPARTMENTS = [
    "Customer Support", "Engineering", "Finance", "Human Resources",
    "Legal", "Marketing", "Operations", "Product", "Sales"
  ].freeze
  MAX_SALARY = 100_000_000

  enum :employment_type,
       { full_time: "full_time", part_time: "part_time", contract: "contract" },
       validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :country_code, with: ->(code) { code.strip.upcase }
  normalizes :full_name, :job_title, with: ->(value) { value.squish }

  validates :full_name, :job_title, :hire_date, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :department, presence: true, inclusion: { in: DEPARTMENTS, allow_blank: true }
  validates :country_code, presence: true
  validates :salary, presence: true,
                     numericality: { greater_than: 0, less_than: MAX_SALARY }
  validate :country_must_be_supported
  validate :hire_date_cannot_be_in_the_future

  def country
    Country.find(country_code)
  end

  def currency
    country&.currency
  end

  def salary_in_usd
    country&.to_usd(salary)
  end

  private

  def country_must_be_supported
    return if country_code.blank? || country

    errors.add(:country_code, "is not a supported country")
  end

  def hire_date_cannot_be_in_the_future
    return if hire_date.blank? || hire_date <= Date.current

    errors.add(:hire_date, "can't be in the future")
  end
end

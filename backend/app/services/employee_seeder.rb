# Generates a realistic, reproducible workforce for demos and performance checks.
#
# Salary model: each role has a US base salary; a country pay factor scales it for the local
# labour market, the result is converted to local currency and given +/-15% noise.
# A fixed Random seed means every run produces the same people.
class EmployeeSeeder
  BATCH_SIZE = 1_000
  EARLIEST_HIRE_DATE = Date.new(2012, 1, 1)
  LATEST_HIRE_DATE = Date.new(2026, 10, 31)

  Role = Data.define(:title, :department, :us_base, :weight)
  ROLES = [
    Role.new("Software Engineer", "Engineering", 115_000, 22),
    Role.new("Senior Software Engineer", "Engineering", 150_000, 12),
    Role.new("Staff Engineer", "Engineering", 195_000, 3),
    Role.new("Engineering Manager", "Engineering", 180_000, 3),
    Role.new("QA Engineer", "Engineering", 90_000, 5),
    Role.new("DevOps Engineer", "Engineering", 125_000, 4),
    Role.new("Product Manager", "Product", 140_000, 4),
    Role.new("Product Designer", "Product", 115_000, 3),
    Role.new("Sales Development Representative", "Sales", 60_000, 6),
    Role.new("Account Executive", "Sales", 95_000, 6),
    Role.new("Sales Manager", "Sales", 140_000, 2),
    Role.new("Marketing Specialist", "Marketing", 75_000, 4),
    Role.new("Marketing Manager", "Marketing", 120_000, 2),
    Role.new("Support Specialist", "Customer Support", 52_000, 8),
    Role.new("Support Team Lead", "Customer Support", 72_000, 2),
    Role.new("Accountant", "Finance", 78_000, 3),
    Role.new("Financial Analyst", "Finance", 92_000, 2),
    Role.new("HR Generalist", "Human Resources", 70_000, 2),
    Role.new("Recruiter", "Human Resources", 75_000, 2),
    Role.new("Legal Counsel", "Legal", 160_000, 1),
    Role.new("Operations Analyst", "Operations", 72_000, 3),
    Role.new("Office Manager", "Operations", 62_000, 1)
  ].freeze

  CountryProfile = Data.define(:share, :pay_factor, :name_locale)
  COUNTRY_PROFILES = {
    "US" => CountryProfile.new(30, 1.00, "english"),
    "IN" => CountryProfile.new(25, 0.32, "indian"),
    "GB" => CountryProfile.new(12, 0.72, "english"),
    "DE" => CountryProfile.new(10, 0.78, "german"),
    "CA" => CountryProfile.new(8, 0.80, "english"),
    "FR" => CountryProfile.new(5, 0.68, "french"),
    "AU" => CountryProfile.new(5, 0.82, "english"),
    "SG" => CountryProfile.new(5, 0.85, "singaporean")
  }.freeze

  EMPLOYMENT_TYPE_WEIGHTS = { "full_time" => 88, "contract" => 7, "part_time" => 5 }.freeze
  PART_TIME_FACTOR = 0.5

  def self.names
    @names ||= YAML.load_file(Rails.root.join("db/seed_data/names.yml"))
  end

  def initialize(count: 10_000, seed: 42)
    @count = count
    @random = Random.new(seed)
    @used_emails = Set.new
  end

  # Replaces all employees with a freshly generated set, in one transaction.
  def call
    Employee.transaction do
      Employee.delete_all
      rows.each_slice(BATCH_SIZE) { |batch| Employee.insert_all!(batch) }
    end
  end

  def rows
    @rows ||= begin
      now = Time.current.change(usec: 0)
      Array.new(@count) { build_row.merge(created_at: now, updated_at: now) }
    end
  end

  private

  def build_row
    country_code = weighted_pick(COUNTRY_PROFILES.transform_values(&:share))
    profile = COUNTRY_PROFILES.fetch(country_code)
    role = weighted_pick(ROLES.to_h { |r| [ r, r.weight ] })
    employment_type = weighted_pick(EMPLOYMENT_TYPE_WEIGHTS)
    first, last = random_name(profile.name_locale)

    {
      full_name: "#{first} #{last}",
      email: unique_email(first, last),
      job_title: role.title,
      department: role.department,
      country_code:,
      salary: local_salary(role, country_code, profile.pay_factor, employment_type),
      employment_type:,
      hire_date: EARLIEST_HIRE_DATE + @random.rand((LATEST_HIRE_DATE - EARLIEST_HIRE_DATE).to_i + 1)
    }
  end

  def local_salary(role, country_code, pay_factor, employment_type)
    usd = role.us_base * pay_factor * @random.rand(0.85..1.15)
    usd *= PART_TIME_FACTOR if employment_type == "part_time"
    local = usd / Country.find(country_code).usd_rate
    (local / 100).round * 100
  end

  def random_name(locale)
    names = self.class.names.fetch(locale)
    [ names["first"].sample(random: @random), names["last"].sample(random: @random) ]
  end

  def unique_email(first, last)
    base = I18n.transliterate("#{first}.#{last}").downcase.delete(" ").gsub(/[^a-z.]/, "")
    candidate = "#{base}@acme.example"
    suffix = 1
    while @used_emails.include?(candidate)
      suffix += 1
      candidate = "#{base}#{suffix}@acme.example"
    end
    @used_emails << candidate
    candidate
  end

  def weighted_pick(weights)
    target = @random.rand(weights.values.sum)
    weights.each do |item, weight|
      return item if target < weight

      target -= weight
    end
  end
end

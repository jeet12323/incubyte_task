require "rails_helper"

RSpec.describe Employee do
  subject(:employee) { build(:employee) }

  it "is valid with the factory defaults" do
    expect(employee).to be_valid
  end

  %i[full_name email job_title department country_code salary hire_date employment_type].each do |attribute|
    it "requires #{attribute}" do
      employee[attribute] = nil

      expect(employee).not_to be_valid
      expect(employee.errors[attribute]).to be_present
    end
  end

  describe "email" do
    it "is normalized to lowercase without surrounding spaces" do
      employee.email = "  Jane.Doe@ACME.com "

      expect(employee.email).to eq("jane.doe@acme.com")
    end

    it "must look like an email address" do
      employee.email = "not-an-email"

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("is invalid")
    end

    it "must be unique regardless of case" do
      create(:employee, email: "jane@acme.com")
      employee.email = "JANE@acme.com"

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to include("has already been taken")
    end
  end

  describe "salary" do
    it "must be positive" do
      employee.salary = 0

      expect(employee).not_to be_valid
      expect(employee.errors[:salary]).to include("must be greater than 0")
    end

    it "rejects absurdly large values that are likely typos" do
      employee.salary = 1_000_000_000

      expect(employee).not_to be_valid
    end
  end

  describe "country" do
    it "must be a configured country" do
      employee.country_code = "XX"

      expect(employee).not_to be_valid
      expect(employee.errors[:country_code]).to include("is not a supported country")
    end

    it "is normalized to uppercase" do
      employee.country_code = "in"

      expect(employee.country_code).to eq("IN")
    end

    it "derives the salary currency from the country" do
      employee.country_code = "IN"

      expect(employee.currency).to eq("INR")
    end
  end

  describe "department" do
    it "must be one of the known departments" do
      employee.department = "Underwater Basket Weaving"

      expect(employee).not_to be_valid
      expect(employee.errors[:department]).to include("is not included in the list")
    end
  end

  describe "employment_type" do
    it "rejects unknown types" do
      employee.employment_type = "volunteer"

      expect(employee).not_to be_valid
      expect(employee.errors[:employment_type]).to be_present
    end
  end

  describe "hire_date" do
    it "cannot be in the future" do
      employee.hire_date = Date.current + 1

      expect(employee).not_to be_valid
      expect(employee.errors[:hire_date]).to include("can't be in the future")
    end
  end

  describe "#salary_in_usd" do
    it "converts the local salary using the country's rate" do
      employee.country_code = "US"
      employee.salary = 120_000

      expect(employee.salary_in_usd).to eq(120_000)
    end
  end
end

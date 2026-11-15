require "rails_helper"

RSpec.describe SalaryInsights do
  subject(:insights) { described_class.new }

  before do
    # India: 3 engineers + 1 HR. Numbers chosen so min/max/avg/median are easy to check by hand.
    create(:employee, country_code: "IN", job_title: "Software Engineer", department: "Engineering", salary: 1_000_000)
    create(:employee, country_code: "IN", job_title: "Software Engineer", department: "Engineering", salary: 2_000_000)
    create(:employee, country_code: "IN", job_title: "Software Engineer", department: "Engineering", salary: 6_000_000)
    create(:employee, country_code: "IN", job_title: "HR Generalist", department: "Human Resources", salary: 800_000)
    # US: 2 engineers.
    create(:employee, country_code: "US", job_title: "Software Engineer", department: "Engineering", salary: 100_000)
    create(:employee, country_code: "US", job_title: "Software Engineer", department: "Engineering", salary: 140_000)
  end

  describe "#summary" do
    it "returns org-wide headcount, countries and payroll in USD" do
      # India total 9.8M INR * 0.012 = 117,600 USD; US total 240,000 USD.
      expect(insights.summary).to eq(headcount: 6, countries: 2, total_payroll_usd: 357_600)
    end
  end

  describe "#by_country" do
    it "returns local-currency stats per country, largest headcount first" do
      india, us = insights.by_country

      expect(india).to include(
        country_code: "IN", country_name: "India", currency: "INR", headcount: 4,
        min_salary: 800_000, max_salary: 6_000_000, avg_salary: 2_450_000, median_salary: 1_500_000,
        total_payroll_usd: 117_600, avg_salary_usd: 29_400
      )
      expect(us).to include(country_code: "US", headcount: 2, median_salary: 120_000, total_payroll_usd: 240_000)
    end
  end

  describe "#job_titles_in" do
    it "returns per-title stats within one country" do
      engineers, hr = insights.job_titles_in("IN")

      expect(engineers).to include(
        job_title: "Software Engineer", headcount: 3, min_salary: 1_000_000,
        max_salary: 6_000_000, avg_salary: 3_000_000, median_salary: 2_000_000
      )
      expect(hr).to include(job_title: "HR Generalist", headcount: 1, median_salary: 800_000)
    end

    it "accepts a lowercase country code" do
      expect(insights.job_titles_in("us").map { |row| row[:job_title] }).to eq([ "Software Engineer" ])
    end

    it "returns nothing for an unsupported country" do
      expect(insights.job_titles_in("XX")).to eq([])
    end
  end

  describe "#by_department" do
    it "returns headcount and USD payroll per department, biggest payroll first" do
      engineering, hr = insights.by_department

      # Engineering: 9.0M INR -> 108,000 USD + 240,000 USD = 348,000 USD over 5 people.
      expect(engineering).to eq(department: "Engineering", headcount: 5,
                                total_payroll_usd: 348_000, avg_salary_usd: 69_600)
      expect(hr).to eq(department: "Human Resources", headcount: 1,
                       total_payroll_usd: 9_600, avg_salary_usd: 9_600)
    end
  end

  context "with no employees" do
    before { Employee.delete_all }

    it "returns zeroes and empty lists instead of failing" do
      expect(insights.summary).to eq(headcount: 0, countries: 0, total_payroll_usd: 0)
      expect(insights.by_country).to eq([])
      expect(insights.by_department).to eq([])
    end
  end
end

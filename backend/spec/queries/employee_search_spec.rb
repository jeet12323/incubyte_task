require "rails_helper"

RSpec.describe EmployeeSearch do
  def search(**params)
    described_class.new(params).call
  end

  describe "filtering" do
    let!(:us_engineer) { create(:employee, country_code: "US", department: "Engineering", job_title: "Software Engineer") }
    let!(:in_engineer) { create(:employee, country_code: "IN", department: "Engineering", job_title: "Software Engineer", salary: 2_000_000) }
    let!(:us_sales) { create(:employee, country_code: "US", department: "Sales", job_title: "Account Executive", employment_type: "contract") }

    it "returns everyone when no filters are given" do
      expect(search.records).to contain_exactly(us_engineer, in_engineer, us_sales)
    end

    it "filters by country" do
      expect(search(country: "IN").records).to contain_exactly(in_engineer)
    end

    it "filters by department" do
      expect(search(department: "Sales").records).to contain_exactly(us_sales)
    end

    it "filters by job title" do
      expect(search(job_title: "Software Engineer").records).to contain_exactly(us_engineer, in_engineer)
    end

    it "filters by employment type" do
      expect(search(employment_type: "contract").records).to contain_exactly(us_sales)
    end

    it "combines filters" do
      expect(search(country: "US", department: "Engineering").records).to contain_exactly(us_engineer)
    end

    it "ignores blank filters" do
      expect(search(country: "", department: nil).records.size).to eq(3)
    end
  end

  describe "text search" do
    let!(:priya) { create(:employee, full_name: "Priya Sharma", email: "priya.sharma@acme.test") }
    let!(:john) { create(:employee, full_name: "John Smith", email: "jsmith@acme.test") }

    it "matches part of the name, case-insensitively" do
      expect(search(q: "sharm").records).to contain_exactly(priya)
    end

    it "matches the email" do
      expect(search(q: "jsmith@").records).to contain_exactly(john)
    end

    it "treats SQL wildcard characters literally" do
      expect(search(q: "%").records).to be_empty
    end
  end

  describe "sorting" do
    let!(:low) { create(:employee, full_name: "Zed", salary: 50_000, hire_date: Date.new(2020, 1, 1)) }
    let!(:high) { create(:employee, full_name: "Amy", salary: 150_000, hire_date: Date.new(2023, 1, 1)) }
    let!(:mid) { create(:employee, full_name: "Mia", salary: 90_000, hire_date: Date.new(2021, 1, 1)) }

    it "sorts by name ascending by default" do
      expect(search.records).to eq([ high, mid, low ])
    end

    it "sorts by salary descending" do
      expect(search(sort: "salary", direction: "desc").records).to eq([ high, mid, low ])
    end

    it "sorts by hire date ascending" do
      expect(search(sort: "hire_date", direction: "asc").records).to eq([ low, mid, high ])
    end

    it "falls back to the default for unknown sort columns and directions" do
      expect(search(sort: "password; DROP TABLE", direction: "sideways").records).to eq([ high, mid, low ])
    end
  end

  describe "pagination" do
    before { create_list(:employee, 7) }

    it "returns the requested page and metadata" do
      result = search(page: 2, per_page: 3)

      expect(result.records.size).to eq(3)
      expect(result.meta).to eq(page: 2, per_page: 3, total_count: 7, total_pages: 3)
    end

    it "returns a partial last page" do
      expect(search(page: 3, per_page: 3).records.size).to eq(1)
    end

    it "caps per_page to protect the server" do
      expect(search(per_page: 10_000).meta[:per_page]).to eq(EmployeeSearch::MAX_PER_PAGE)
    end

    it "treats invalid page values as the first page" do
      expect(search(page: -4, per_page: "abc").meta).to include(page: 1, per_page: EmployeeSearch::DEFAULT_PER_PAGE)
    end
  end
end

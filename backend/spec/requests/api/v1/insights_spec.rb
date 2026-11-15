require "rails_helper"

RSpec.describe "Insights API", type: :request do
  let(:json) { response.parsed_body }

  before do
    create(:employee, country_code: "IN", job_title: "Software Engineer", salary: 2_000_000)
    create(:employee, country_code: "US", job_title: "Product Manager", department: "Product", salary: 150_000)
  end

  it "GET /api/v1/insights/summary returns org-wide totals" do
    get "/api/v1/insights/summary"

    expect(json["data"]).to eq("headcount" => 2, "countries" => 2, "total_payroll_usd" => 174_000)
  end

  it "GET /api/v1/insights/countries returns one row per country" do
    get "/api/v1/insights/countries"

    expect(json["data"].map { |row| row["country_code"] }).to contain_exactly("IN", "US")
  end

  it "GET /api/v1/insights/countries/:code/job_titles returns title stats for that country" do
    get "/api/v1/insights/countries/in/job_titles"

    expect(json["data"]).to contain_exactly(include("job_title" => "Software Engineer", "currency" => "INR"))
  end

  it "returns 404 for job titles in an unsupported country" do
    get "/api/v1/insights/countries/XX/job_titles"

    expect(response).to have_http_status(:not_found)
  end

  it "GET /api/v1/insights/departments returns payroll per department" do
    get "/api/v1/insights/departments"

    expect(json["data"].map { |row| row["department"] }).to eq(%w[Product Engineering])
  end
end

require "rails_helper"

RSpec.describe "Meta API", type: :request do
  before { sign_in }

  it "returns reference data for filters and forms" do
    create(:employee, job_title: "Data Analyst")
    create(:employee, job_title: "Accountant")

    get "/api/v1/meta"

    data = response.parsed_body["data"]
    expect(data["countries"]).to include("code" => "IN", "name" => "India", "currency" => "INR")
    expect(data["departments"]).to include("Engineering", "Sales")
    expect(data["employment_types"]).to eq(%w[full_time part_time contract])
    expect(data["job_titles"]).to eq([ "Accountant", "Data Analyst" ])
  end
end

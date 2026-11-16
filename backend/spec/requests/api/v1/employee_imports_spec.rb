require "rails_helper"

RSpec.describe "Employee import", type: :request do
  before { sign_in }

  let(:header) { "email,full_name,job_title,department,country_code,salary,employment_type,hire_date\n" }

  def upload(content, filename: "employees.csv", type: "text/csv")
    post "/api/v1/employees/import",
         params: { file: Rack::Test::UploadedFile.new(StringIO.new(content), type, original_filename: filename) }
  end

  it "imports the file and returns the counts" do
    upload(header + "a@acme.test,A Person,Analyst,Finance,US,50000,full_time,2024-01-01\n")

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"]).to include("created" => 1, "updated" => 0, "error_count" => 0)
  end

  it "returns 422 with row errors and saves nothing when a row is invalid" do
    upload(header + "a@acme.test,A Person,Analyst,Finance,US,-1,full_time,2024-01-01\n")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["data"]["errors"].first).to include("row" => 2)
    expect(Employee.count).to eq(0)
  end

  it "returns 422 with a message for a file it can't read" do
    upload("name\nx\n")

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to start_with("Missing columns")
  end

  it "returns 400 without a file" do
    post "/api/v1/employees/import"

    expect(response).to have_http_status(:bad_request)
  end
end

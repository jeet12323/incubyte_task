require "rails_helper"
require "csv"

RSpec.describe "Employee CSV export and import", type: :request do
  before { sign_in }

  describe "GET /api/v1/employees/export" do
    it "downloads the filtered employees as CSV in the current sort order" do
      create(:employee, full_name: "Zed", country_code: "IN", salary: 900_000)
      create(:employee, full_name: "Amy", country_code: "IN", salary: 1_200_000)
      create(:employee, full_name: "Bob", country_code: "US")

      get "/api/v1/employees/export", params: { country: "IN", sort: "salary", direction: "desc" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to match(/attachment; filename="acme-employees-\d{4}-\d{2}-\d{2}\.csv"/)
      rows = CSV.parse(response.body, headers: true)
      expect(rows.headers).to eq(EmployeeCsv::HEADERS)
      expect(rows.map { |row| [ row["full_name"], row["currency"], row["salary"] ] })
        .to eq([ [ "Amy", "INR", "1200000.00" ], [ "Zed", "INR", "900000.00" ] ])
    end

    it "prefixes cells that Excel would run as formulas" do
      create(:employee, full_name: "=cmd|' /C calc'!A0")

      get "/api/v1/employees/export"

      expect(CSV.parse(response.body, headers: true).first["full_name"]).to eq("'=cmd|' /C calc'!A0")
    end
  end

  describe "POST /api/v1/employees/import" do
    def upload(content)
      post "/api/v1/employees/import",
           params: { file: Rack::Test::UploadedFile.new(StringIO.new(content), "text/csv", original_filename: "employees.csv") }
    end

    let(:header) { "email,full_name,job_title,department,country_code,salary,employment_type,hire_date\n" }

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
end

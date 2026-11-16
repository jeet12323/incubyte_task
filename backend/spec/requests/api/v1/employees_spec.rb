require "rails_helper"

RSpec.describe "Employees API", type: :request do
  before { sign_in }

  let(:json) { response.parsed_body }

  describe "GET /api/v1/employees" do
    it "returns a page of employees with pagination metadata" do
      create_list(:employee, 3)

      get "/api/v1/employees", params: { per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(2)
      expect(json["meta"]).to eq("page" => 1, "per_page" => 2, "total_count" => 3, "total_pages" => 2)
    end

    it "passes filters through to the search" do
      create(:employee, country_code: "IN", salary: 1_500_000)
      create(:employee, country_code: "US")

      get "/api/v1/employees", params: { country: "IN" }

      expect(json["data"].map { |e| e["country_code"] }).to eq([ "IN" ])
    end

    it "serializes the fields the UI needs, including currency and USD salary" do
      create(:employee, full_name: "Priya Sharma", country_code: "IN", salary: 2_000_000)

      get "/api/v1/employees"

      expect(json["data"].first).to include(
        "full_name" => "Priya Sharma",
        "country_code" => "IN",
        "country_name" => "India",
        "currency" => "INR",
        "salary" => 2_000_000.0,
        "salary_usd" => 24_000
      )
    end
  end

  describe "GET /api/v1/employees/:id" do
    it "returns the employee" do
      employee = create(:employee)

      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"]).to eq(employee.id)
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/employees/0"

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Employee not found")
    end
  end

  describe "POST /api/v1/employees" do
    let(:valid_params) do
      { employee: { full_name: "Ana Lima", email: "ana@acme.test", job_title: "Data Analyst",
                    department: "Finance", country_code: "DE", salary: 65_000,
                    employment_type: "full_time", hire_date: "2024-03-01" } }
    end

    it "creates the employee" do
      expect { post "/api/v1/employees", params: valid_params }.to change(Employee, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["data"]).to include("full_name" => "Ana Lima", "currency" => "EUR")
    end

    it "returns field errors for invalid input" do
      post "/api/v1/employees", params: { employee: valid_params[:employee].merge(salary: -5, email: "") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("salary", "email")
    end

    it "returns 400 when the employee payload is missing" do
      post "/api/v1/employees", params: {}

      expect(response).to have_http_status(:bad_request)
    end

    it "ignores attributes that are not permitted" do
      post "/api/v1/employees", params: { employee: valid_params[:employee].merge(id: 999_999) }

      expect(json["data"]["id"]).not_to eq(999_999)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee, salary: 100_000) }

    it "updates the salary" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary: 110_000 } }

      expect(response).to have_http_status(:ok)
      expect(employee.reload.salary).to eq(110_000)
    end

    it "rejects invalid changes without saving them" do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { country_code: "XX" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.country_code).to eq("US")
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    it "deletes the employee" do
      employee = create(:employee)

      expect { delete "/api/v1/employees/#{employee.id}" }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end

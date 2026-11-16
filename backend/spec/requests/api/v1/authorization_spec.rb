require "rails_helper"

RSpec.describe "API access control", type: :request do
  let(:employee) { create(:employee) }

  context "when not signed in" do
    it "rejects every API endpoint with 401" do
      [ "/api/v1/employees", "/api/v1/employees/#{employee.id}", "/api/v1/meta",
        "/api/v1/insights/summary", "/api/v1/employees/export" ].each do |path|
        get path
        expect(response).to have_http_status(:unauthorized), "expected 401 for #{path}"
      end
    end

    it "still serves the health check" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end

  context "when signed in as a viewer" do
    before { sign_in(create(:user, :viewer)) }

    it "can read salaries" do
      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
    end

    it "cannot create, update, delete or import employees" do
      post "/api/v1/employees", params: { employee: { full_name: "X" } }
      expect(response).to have_http_status(:forbidden)

      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary: 1 } }
      expect(response).to have_http_status(:forbidden)

      delete "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:forbidden)

      post "/api/v1/employees/import", params: { file: Rack::Test::UploadedFile.new(StringIO.new("email\n"), "text/csv", original_filename: "x.csv") }
      expect(response).to have_http_status(:forbidden)

      expect(employee.reload.salary).not_to eq(1)
    end
  end
end

require "rails_helper"

RSpec.describe "SPA fallback", type: :request do
  let(:index_file) { Rails.public_path.join("index.html") }

  context "when the frontend has been built" do
    before { File.write(index_file, "<!doctype html><title>ACME Salaries</title>") }
    after { FileUtils.rm_f(index_file) }

    it "serves index.html for client-side routes so deep links work" do
      get "/insights", headers: { "Accept" => "text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ACME Salaries")
    end

    it "serves index.html at the root" do
      get "/", headers: { "Accept" => "text/html" }

      expect(response.body).to include("ACME Salaries")
    end
  end

  it "does not swallow unknown API routes" do
    get "/api/v1/nope", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("ACME Salaries")
  end
end

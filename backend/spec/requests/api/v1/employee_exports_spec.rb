require "rails_helper"

RSpec.describe "Employee export", type: :request do
  before { sign_in }

  def rows_from(body)
    file = Tempfile.new([ "export", ".xlsx" ], binmode: true)
    file.write(body)
    file.flush
    Roo::Excelx.new(file.path).sheet(0).parse(headers: true).drop(1)
  end

  it "downloads the filtered employees as an Excel workbook in the current sort order" do
    create(:employee, full_name: "Zed", country_code: "IN", salary: 900_000)
    create(:employee, full_name: "Amy", country_code: "IN", salary: 1_200_000)
    create(:employee, full_name: "Bob", country_code: "US")

    get "/api/v1/employees/export", params: { country: "IN", sort: "salary", direction: "desc" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(EmployeeSpreadsheet::CONTENT_TYPE)
    expect(response.headers["Content-Disposition"])
      .to match(/attachment; filename="acme-employees-\d{4}-\d{2}-\d{2}\.xlsx"/)
    expect(rows_from(response.body).map { |row| [ row["full_name"], row["currency"], row["salary"] ] })
      .to eq([ [ "Amy", "INR", 1_200_000 ], [ "Zed", "INR", 900_000 ] ])
  end
end

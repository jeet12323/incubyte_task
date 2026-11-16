require "rails_helper"
require "zip"

RSpec.describe EmployeeSpreadsheet do
  def workbook(scope = Employee.all)
    file = Tempfile.new([ "employees", ".xlsx" ], binmode: true)
    file.write(described_class.generate(scope))
    file.flush
    Roo::Excelx.new(file.path)
  end

  def sheet_xml(scope = Employee.all)
    Zip::InputStream.open(StringIO.new(described_class.generate(scope))) do |zip|
      while (entry = zip.get_next_entry)
        return zip.read if entry.name == "xl/worksheets/sheet1.xml"
      end
    end
  end

  it "writes a header row with the import column names, then one row per employee" do
    create(:employee, email: "ana@acme.test", full_name: "Ana Lima", job_title: "Data Analyst",
                      department: "Finance", country_code: "DE", salary: 65_000.5,
                      employment_type: "part_time", hire_date: "2024-03-01")

    sheet = workbook.sheet(0)

    expect(sheet.row(1)).to eq(EmployeeSpreadsheet::HEADERS)
    expect(sheet.row(2)).to eq([ "ana@acme.test", "Ana Lima", "Data Analyst", "Finance", "DE", "EUR",
                                 65_000.5, "part_time", Date.new(2024, 3, 1) ])
  end

  it "stores hire dates as real dates shown as YYYY-MM-DD, so Excel never rewrites them" do
    create(:employee, hire_date: "2024-03-01")

    sheet = workbook.sheet(0)

    expect(sheet.cell(2, 9)).to eq(Date.new(2024, 3, 1))
    expect(sheet.excelx_format(2, 9)).to eq("yyyy-mm-dd")
  end

  it "sizes every column so values are readable without resizing (hire date included)" do
    create(:employee)

    widths = sheet_xml.scan(/<col [^>]*width="([\d.]+)"/).flatten.map(&:to_f)

    expect(widths).to eq(EmployeeSpreadsheet::COLUMNS.map { |column| column.width.to_f })
    expect(widths.last).to be >= 12
  end

  it "keeps text that looks like a formula as plain text" do
    create(:employee, full_name: "=HYPERLINK(\"http://evil.test\")")

    xml = sheet_xml

    expect(xml).not_to include("<f>")
    expect(workbook.sheet(0).cell(2, 2)).to eq("=HYPERLINK(\"http://evil.test\")")
  end

  it "freezes the header row and turns on filters" do
    create(:employee)

    xml = sheet_xml

    expect(xml).to include('state="frozen"')
    expect(xml).to match(/<autoFilter ref=["']A1:I2["']/)
  end
end

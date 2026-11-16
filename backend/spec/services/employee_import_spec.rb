require "rails_helper"

RSpec.describe EmployeeImport do
  let(:header) { "email,full_name,job_title,department,country_code,currency,salary,employment_type,hire_date\n" }

  def import(rows)
    described_class.new(header + rows).call
  end

  it "creates new employees and reports the counts" do
    result = import(<<~CSV)
      ana@acme.test,Ana Lima,Data Analyst,Finance,DE,EUR,65000.00,full_time,2024-03-01
      raj@acme.test,Raj Patel,Software Engineer,Engineering,IN,INR,"18,50,000",Full-time,2023-07-15
    CSV

    expect(result.to_h).to include(created: 2, updated: 0, unchanged: 0, error_count: 0)
    expect(Employee.find_by(email: "raj@acme.test")).to have_attributes(salary: 1_850_000, employment_type: "full_time")
  end

  it "updates employees matched by email (case-insensitive) and counts unchanged rows" do
    changed = create(:employee, email: "ana@acme.test", salary: 60_000, country_code: "DE")
    same = create(:employee, email: "li@acme.test", full_name: "Li Wei", job_title: "Accountant",
                             department: "Finance", country_code: "SG", salary: 90_000,
                             employment_type: "contract", hire_date: "2022-01-10")

    result = import(<<~CSV)
      ANA@acme.test,#{changed.full_name},#{changed.job_title},#{changed.department},DE,EUR,70000,#{changed.employment_type},#{changed.hire_date}
      li@acme.test,Li Wei,Accountant,Finance,SG,SGD,90000.00,contract,2022-01-10
    CSV

    expect(result.to_h).to include(created: 0, updated: 1, unchanged: 1)
    expect(changed.reload.salary).to eq(70_000)
    expect(same.reload.updated_at).to eq(same.updated_at)
  end

  it "saves nothing when any row is invalid and reports each problem by spreadsheet row" do
    result = import(<<~CSV)
      ok@acme.test,Ok Person,Analyst,Finance,US,USD,50000,full_time,2024-01-01
      bad@acme.test,,Analyst,Finance,XX,USD,abc,full_time,01/02/2024
      ok@acme.test,Dup Person,Analyst,Finance,US,USD,50000,full_time,2024-01-01
    CSV

    expect(Employee.count).to eq(0)
    expect(result.success?).to be(false)
    expect(result.error_count).to eq(2)
    expect(result.errors).to contain_exactly(
      { row: 3, email: "bad@acme.test", messages: [
        "Salary must be a number like 85000 or 85000.50",
        "Hire date must be a date in YYYY-MM-DD format",
        "Full name can't be blank",
        "Country code is not a supported country"
      ] },
      { row: 4, email: "ok@acme.test", messages: [ "Email is also used on row 2" ] }
    )
  end

  it "rejects a currency that doesn't match the country" do
    result = import("a@acme.test,A Person,Analyst,Finance,IN,USD,50000,full_time,2024-01-01\n")

    expect(result.errors.first[:messages]).to eq([ "Currency USD doesn't match India (INR)" ])
  end

  it "accepts files saved by Excel with a byte-order mark and no currency column" do
    csv = "﻿email,full_name,job_title,department,country_code,salary,employment_type,hire_date\r\n" \
          "a@acme.test,A Person,Analyst,Finance,US,50000,contract,2024-01-01\r\n"

    expect(described_class.new(csv).call.created).to eq(1)
  end

  it "rejects files with missing columns, no rows, or bad CSV" do
    expect { described_class.new("email,full_name\n").call }
      .to raise_error(EmployeeImport::InvalidFile, /Missing columns: job_title, department/)
    expect { described_class.new(header).call }.to raise_error(EmployeeImport::InvalidFile, /no employee rows/)
    expect { described_class.new(header + "a,\"b\n").call }.to raise_error(EmployeeImport::InvalidFile, /not a valid CSV/)
    expect { described_class.new("email\xFF".b).call }.to raise_error(EmployeeImport::InvalidFile, /CSV UTF-8/)
  end
end

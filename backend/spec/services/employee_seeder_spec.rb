require "rails_helper"

RSpec.describe EmployeeSeeder do
  it "inserts exactly the requested number of employees" do
    expect { described_class.new(count: 250).call }.to change(Employee, :count).from(0).to(250)
  end

  it "only produces records that pass model validations" do
    described_class.new(count: 200).call

    invalid = Employee.all.reject(&:valid?)
    expect(invalid.map { |e| e.errors.full_messages }).to be_empty
  end

  it "is deterministic for the same random seed" do
    first_run = described_class.new(count: 50, seed: 7).rows
    second_run = described_class.new(count: 50, seed: 7).rows

    expect(first_run.map { |row| row.except(:created_at, :updated_at) })
      .to eq(second_run.map { |row| row.except(:created_at, :updated_at) })
  end

  it "replaces existing employees so it can be re-run safely" do
    create(:employee, email: "old@acme.test")

    described_class.new(count: 10).call

    expect(Employee.count).to eq(10)
    expect(Employee.exists?(email: "old@acme.test")).to be(false)
  end

  it "spreads employees across every configured country and department" do
    described_class.new(count: 500).call

    expect(Employee.distinct.pluck(:country_code)).to match_array(Country.codes)
    expect(Employee.distinct.pluck(:department)).to match_array(Employee::DEPARTMENTS)
  end

  it "pays senior roles more than junior ones in the same country" do
    described_class.new(count: 2_000).call
    us = Employee.where(country_code: "US")

    expect(us.where(job_title: "Staff Engineer").average(:salary))
      .to be > us.where(job_title: "Software Engineer").average(:salary)
  end
end

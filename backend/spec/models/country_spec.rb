require "rails_helper"

RSpec.describe Country do
  describe ".find" do
    it "returns the country for a known code" do
      india = Country.find("IN")

      expect(india.name).to eq("India")
      expect(india.currency).to eq("INR")
    end

    it "is case-insensitive" do
      expect(Country.find("in")).to eq(Country.find("IN"))
    end

    it "returns nil for an unknown code" do
      expect(Country.find("XX")).to be_nil
      expect(Country.find(nil)).to be_nil
    end
  end

  describe ".all" do
    it "lists every configured country sorted by name" do
      names = Country.all.map(&:name)

      expect(names).to eq(names.sort)
      expect(Country.all.map(&:code)).to include("US", "IN", "GB")
    end
  end

  describe "#to_usd" do
    it "converts a local amount into USD using the configured rate" do
      us = Country.find("US")

      expect(us.to_usd(1000)).to eq(1000)
    end

    it "rounds to whole dollars" do
      country = Country.new(code: "ZZ", name: "Test", currency: "TST", usd_rate: 0.333)

      expect(country.to_usd(100)).to eq(33)
    end
  end
end

# A country ACME employs people in. Static reference data loaded from config/countries.yml,
# so currency and USD rate live in one versioned place instead of on every employee row.
Country = Data.define(:code, :name, :currency, :usd_rate) do
  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/countries.yml"))
                 .map { |attrs| new(**attrs.symbolize_keys) }
                 .sort_by(&:name)
                 .freeze
  end

  def self.find(code)
    return if code.blank?

    all.find { |country| country.code == code.to_s.upcase }
  end

  def self.codes
    all.map(&:code)
  end

  def to_usd(amount)
    (amount * usd_rate).round
  end
end

# The date the rates in config/countries.yml were taken. Shown next to every converted figure.
Country::RATES_AS_OF = Date.new(2026, 11, 1)

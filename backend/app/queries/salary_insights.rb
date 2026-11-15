# Answers "how does the org pay people?" with SQL aggregates, so each insight is a single query
# regardless of headcount. Local-currency stats are only computed within one country; anything
# that crosses countries is converted to USD with the fixed rates from config/countries.yml.
class SalaryInsights
  def summary
    row = Employee.pick(Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT country_code)"),
                        Arel.sql("COALESCE(SUM(#{usd_salary_sql}), 0)"))
    { headcount: row[0], countries: row[1], total_payroll_usd: row[2].round }
  end

  def by_country
    rows = Employee.group(:country_code)
                   .order(Arel.sql("COUNT(*) DESC"), :country_code)
                   .pluck(:country_code, *local_stat_columns,
                          Arel.sql("SUM(#{usd_salary_sql})"), Arel.sql("AVG(#{usd_salary_sql})"))

    rows.map do |code, *stats, total_usd, avg_usd|
      country = Country.find(code)
      { country_code: code, country_name: country.name, currency: country.currency,
        **local_stats(stats), total_payroll_usd: total_usd.round, avg_salary_usd: avg_usd.round }
    end
  end

  def job_titles_in(country_code)
    country = Country.find(country_code)
    return [] unless country

    Employee.where(country_code: country.code)
            .group(:job_title)
            .order(Arel.sql("AVG(salary) DESC"), :job_title)
            .pluck(:job_title, *local_stat_columns)
            .map { |title, *stats| { job_title: title, currency: country.currency, **local_stats(stats) } }
  end

  def by_department
    Employee.group(:department)
            .order(Arel.sql("SUM(#{usd_salary_sql}) DESC"), :department)
            .pluck(:department, Arel.sql("COUNT(*)"),
                   Arel.sql("SUM(#{usd_salary_sql})"), Arel.sql("AVG(#{usd_salary_sql})"))
            .map do |department, headcount, total_usd, avg_usd|
              { department:, headcount:, total_payroll_usd: total_usd.round, avg_salary_usd: avg_usd.round }
            end
  end

  private

  def local_stat_columns
    [ Arel.sql("COUNT(*)"), Arel.sql("MIN(salary)"), Arel.sql("MAX(salary)"), Arel.sql("AVG(salary)"),
      Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary)") ]
  end

  def local_stats((headcount, min, max, avg, median))
    { headcount:, min_salary: min.round, max_salary: max.round,
      avg_salary: avg.round, median_salary: median.round }
  end

  # CASE expression converting each row's local salary to USD. Built only from config values,
  # quoted through the connection, so no user input reaches it.
  def usd_salary_sql
    @usd_salary_sql ||= begin
      connection = Employee.connection
      branches = Country.all.map do |country|
        "WHEN #{connection.quote(country.code)} THEN #{Float(country.usd_rate)}"
      end
      "(salary * CASE country_code #{branches.join(' ')} END)"
    end
  end
end

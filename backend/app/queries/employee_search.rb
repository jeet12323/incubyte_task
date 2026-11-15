# Filters, searches, sorts and paginates employees for the directory screen.
# Every user-supplied value is whitelisted or parameterized, never interpolated into SQL.
class EmployeeSearch
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  SORTABLE_COLUMNS = %w[full_name salary hire_date job_title country_code department].freeze
  DIRECTIONS = %w[asc desc].freeze
  EXACT_FILTERS = { country: :country_code, department: :department,
                    job_title: :job_title, employment_type: :employment_type }.freeze

  Result = Data.define(:records, :meta)

  def initialize(params = {})
    @params = params.to_h.symbolize_keys
  end

  def call
    scope = sorted(searched(filtered(Employee.all)))
    total_count = scope.count

    Result.new(
      records: scope.offset((page - 1) * per_page).limit(per_page).to_a,
      meta: { page:, per_page:, total_count:, total_pages: (total_count.to_f / per_page).ceil }
    )
  end

  private

  attr_reader :params

  def filtered(scope)
    EXACT_FILTERS.reduce(scope) do |current, (param, column)|
      value = params[param]
      value.present? ? current.where(column => value) : current
    end
  end

  def searched(scope)
    term = params[:q].to_s.strip
    return scope if term.empty?

    pattern = "%#{Employee.sanitize_sql_like(term)}%"
    scope.where("employees.full_name ILIKE :pattern OR employees.email ILIKE :pattern", pattern:)
  end

  def sorted(scope)
    column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "full_name"
    direction = DIRECTIONS.include?(params[:direction]) ? params[:direction] : "asc"
    # Secondary sort on id keeps paging stable when many rows share a value.
    scope.order(column => direction, id: :asc)
  end

  def page
    [ params[:page].to_i, 1 ].max
  end

  def per_page
    requested = params[:per_page].to_i
    requested.positive? ? [ requested, MAX_PER_PAGE ].min : DEFAULT_PER_PAGE
  end
end

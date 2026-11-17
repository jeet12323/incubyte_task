module Api
  module V1
    # Reference data for form dropdowns and filters.
    class MetaController < ApplicationController
      def show
        render json: {
          data: {
            countries: Country.all.map { |c| { code: c.code, name: c.name, currency: c.currency, usd_rate: c.usd_rate } },
            exchange_rates_as_of: Country::RATES_AS_OF.iso8601,
            departments: Employee::DEPARTMENTS,
            employment_types: Employee.employment_types.keys,
            job_titles: Employee.distinct.order(:job_title).pluck(:job_title)
          }
        }
      end
    end
  end
end

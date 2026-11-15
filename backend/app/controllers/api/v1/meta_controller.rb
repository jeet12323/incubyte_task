module Api
  module V1
    # Reference data for form dropdowns and filters.
    class MetaController < ApplicationController
      def show
        render json: {
          data: {
            countries: Country.all.map { |c| { code: c.code, name: c.name, currency: c.currency } },
            departments: Employee::DEPARTMENTS,
            employment_types: Employee.employment_types.keys,
            job_titles: Employee.distinct.order(:job_title).pluck(:job_title)
          }
        }
      end
    end
  end
end

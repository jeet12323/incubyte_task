module Api
  module V1
    # Downloads the employees matching the directory's current filters and sort as CSV.
    class EmployeeExportsController < ApplicationController
      def show
        scope = EmployeeSearch.new(params.permit(:q, :country, :department, :job_title, :employment_type,
                                                 :sort, :direction)).scope
        send_data EmployeeCsv.generate(scope),
                  type: "text/csv; charset=utf-8",
                  filename: "acme-employees-#{Date.current.iso8601}.csv"
      end
    end
  end
end

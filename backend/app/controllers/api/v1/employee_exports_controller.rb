module Api
  module V1
    # Downloads the employees matching the directory's current filters and sort as an Excel workbook.
    class EmployeeExportsController < ApplicationController
      def show
        scope = EmployeeSearch.new(params.permit(:q, :country, :department, :job_title, :employment_type,
                                                 :sort, :direction)).scope
        send_data EmployeeSpreadsheet.generate(scope),
                  type: EmployeeSpreadsheet::CONTENT_TYPE,
                  filename: "acme-employees-#{Date.current.iso8601}.xlsx"
      end
    end
  end
end

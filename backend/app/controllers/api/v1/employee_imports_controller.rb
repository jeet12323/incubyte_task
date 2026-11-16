module Api
  module V1
    # Creates or updates employees from an uploaded .xlsx (or .csv). Nothing is saved unless every
    # row is valid.
    class EmployeeImportsController < ApplicationController
      MAX_FILE_SIZE = 5.megabytes

      before_action :require_editor

      def create
        file = params.require(:file)
        unless file.respond_to?(:read)
          return render json: { error: "Attach an .xlsx or .csv file" }, status: :bad_request
        end
        if file.size > MAX_FILE_SIZE
          return render json: { error: "The file is larger than 5 MB" }, status: :content_too_large
        end

        result = EmployeeImport.new(file.read).call
        render json: { data: result.to_h }, status: result.success? ? :ok : :unprocessable_content
      rescue EmployeeImport::InvalidFile => error
        render json: { error: error.message }, status: :unprocessable_content
      end
    end
  end
end

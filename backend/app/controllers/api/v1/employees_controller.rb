module Api
  module V1
    class EmployeesController < ApplicationController
      PERMITTED_ATTRIBUTES = %i[full_name email job_title department country_code
                                salary employment_type hire_date].freeze

      before_action :set_employee, only: %i[show update destroy]

      def index
        result = EmployeeSearch.new(search_params).call
        render json: { data: result.records.map { |employee| EmployeeSerializer.call(employee) }, meta: result.meta }
      end

      def show
        render json: { data: EmployeeSerializer.call(@employee) }
      end

      def create
        employee = Employee.new(employee_params)
        if employee.save
          render json: { data: EmployeeSerializer.call(employee) }, status: :created
        else
          render_validation_errors(employee)
        end
      end

      def update
        if @employee.update(employee_params)
          render json: { data: EmployeeSerializer.call(@employee) }
        else
          render_validation_errors(@employee)
        end
      end

      def destroy
        @employee.destroy!
        head :no_content
      end

      private

      def set_employee
        @employee = Employee.find_by(id: params[:id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def employee_params
        params.expect(employee: PERMITTED_ATTRIBUTES)
      end

      def search_params
        params.permit(:q, :country, :department, :job_title, :employment_type,
                      :sort, :direction, :page, :per_page)
      end

      def render_validation_errors(employee)
        render json: { errors: employee.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end

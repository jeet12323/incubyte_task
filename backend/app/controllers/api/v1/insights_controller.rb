module Api
  module V1
    class InsightsController < ApplicationController
      def summary
        render json: { data: insights.summary }
      end

      def countries
        render json: { data: insights.by_country }
      end

      def country_job_titles
        country = Country.find(params[:country_code])
        return render json: { error: "Country not found" }, status: :not_found unless country

        render json: { data: insights.job_titles_in(country.code) }
      end

      def departments
        render json: { data: insights.by_department }
      end

      private

      def insights
        @insights ||= SalaryInsights.new
      end
    end
  end
end

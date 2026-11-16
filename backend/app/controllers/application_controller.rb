class ApplicationController < ActionController::API
  before_action :require_authentication

  rescue_from ActionController::ParameterMissing do |error|
    render json: { error: error.message }, status: :bad_request
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def require_authentication
    render json: { error: "Please sign in" }, status: :unauthorized unless current_user
  end

  def require_editor
    return if current_user&.can_edit?

    render json: { error: "Your role can view salaries but not change them" }, status: :forbidden
  end
end

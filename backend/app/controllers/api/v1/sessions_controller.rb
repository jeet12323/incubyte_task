module Api
  module V1
    # Sign in / sign out for HR staff, backed by the encrypted session cookie.
    class SessionsController < ApplicationController
      skip_before_action :require_authentication, only: %i[create destroy]
      rate_limit to: 10, within: 3.minutes, only: :create,
                 with: -> { render json: { error: "Too many attempts. Try again in a few minutes." }, status: :too_many_requests }

      def show
        render json: { data: UserSerializer.call(current_user) }
      end

      def create
        user = User.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)

        if user
          reset_session # new session id on sign-in (prevents session fixation)
          session[:user_id] = user.id
          render json: { data: UserSerializer.call(user) }, status: :created
        else
          render json: { error: "Email or password is incorrect" }, status: :unauthorized
        end
      end

      def destroy
        reset_session
        head :no_content
      end
    end
  end
end

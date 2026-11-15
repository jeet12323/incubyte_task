Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :employees, only: %i[index show create update destroy]
      resource :meta, only: :show, controller: :meta

      scope :insights, controller: :insights, as: :insights do
        get :summary
        get :countries
        get "countries/:country_code/job_titles", action: :country_job_titles, as: :country_job_titles
        get :departments
      end
    end
  end
end

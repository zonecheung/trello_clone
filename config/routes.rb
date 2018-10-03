Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :boards do
      resources :task_groups do
        resources :tasks
      end
    end
  end
end

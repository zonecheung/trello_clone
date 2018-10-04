Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    resources :boards do
      resources :task_groups do
        patch :move_to_position, on: :member

        resources :tasks do
          patch :move_to_position, on: :member
        end
      end
    end
  end
end

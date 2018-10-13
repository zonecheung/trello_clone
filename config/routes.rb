Rails.application.routes.draw do
  apipie
  namespace :api, defaults: { format: :json } do
    resources :boards do
      get :latest, on: :collection

      resources :task_groups do
        patch :move_to_position, on: :member

        resources :tasks do
          patch :move_to_position, on: :member
        end
      end
    end
  end

  root to: 'welcome#index'
end

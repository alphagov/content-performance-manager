Rails.application.routes.draw do
  root to: 'content/items#index'

  namespace :content do
    resources :items, only: %w(index show), param: :content_id
  end

  get '/api/v1/metrics/:content_id', to: "metrics#show"

  if Rails.env.development?
    mount GovukAdminTemplate::Engine, at: "/style-guide"
  end
end

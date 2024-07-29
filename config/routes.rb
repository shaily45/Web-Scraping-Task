Rails.application.routes.draw do
  root 'api/v1/scraping#index'

  namespace :api do
    namespace :v1 do
      get 'scraping/scrape'
      post 'scrape', to: 'scraping#scrape'
    end
  end
end
Rails.application.routes.draw do
  get '/proxy', to: 'proxy#fetch_url'
end
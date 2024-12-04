Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '/proxy',
      headers: :any,
      methods: [:get, :options],
      max_age: 86400
  end
end
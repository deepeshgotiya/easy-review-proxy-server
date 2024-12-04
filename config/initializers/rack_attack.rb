class Rack::Attack
  throttle('proxy_requests_by_ip', limit: 100, period: 1.hour) do |req|
    req.ip if req.path == '/proxy'
  end
end
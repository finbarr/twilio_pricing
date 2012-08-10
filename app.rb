require 'sinatra'
require 'redis'
require 'json'

get %r{^/(\d{1,15})$} do |number|
  redis = Redis.new
  prices = redis.pipelined do
    until number.empty?
      redis.get number.dup.to_s
      number.chop!
    end
  end
  prices.compact!
  return 400 if prices.empty?
  country, alpha2, price = prices.first.split(':')
  content_type :json
  {country: country, alpha2: alpha2, price: price}.to_json
end

get '/' do
  "Twilio Pricing"
end

get '*' do
  404
end

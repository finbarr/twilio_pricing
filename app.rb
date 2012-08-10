require 'json'
require 'redis'
require 'sinatra'

get %r{^/(\d{1,15})$} do |number|
  redis = Redis.new
  prefixes = []
  prices = redis.pipelined do
    number.tap do |n|
      redis.get (prefixes << n.dup).last
    end.chop! until number.empty?
  end
  index = prices.find_index {|p| !p.nil?}
  return 400 if index.nil?
  price = prices[index]
  prefix = prefixes[index]
  countries = redis.sget prefix
  content_type :json
  {countries: countries, price: price}.to_json
end

get '/' do
  "Twilio Pricing"
end

get '*' do
  404
end

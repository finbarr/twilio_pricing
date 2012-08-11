require 'json'
require 'redis'
require 'sinatra'

configure do
  if ENV['RACK_ENV'] == 'production'
    uri = URI.parse(ENV['REDISTOGO_URL'])
    REDIS = Redis.new(host: uri.host, port: uri.port, password: uri.password)
  else
    REDIS = Redis.new
  end
end

get %r{^/(\d{1,15})$} do |number|
  prefixes = []
  prices = REDIS.pipelined do
    number.tap do |n|
      REDIS.get (prefixes << n.dup).last
    end.chop! until number.empty?
  end
  index = prices.find_index {|p| !p.nil?}
  return 400 if index.nil?
  price = prices[index]
  prefix = prefixes[index]
  countries = REDIS.smembers("countries:#{prefix}").map do |country|
    alpha2, name = country.split(':')
    {alpha2: alpha2, name: name}
  end
  content_type :json
  {price: price, countries: countries}.to_json
end

get '/' do
  erb :index
end

get '*' do
  404
end

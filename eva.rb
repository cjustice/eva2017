require 'sinatra'
require 'json'
require 'net/http'
require 'sinatra/base'
require 'active_support/core_ext/hash'
require 'nokogiri'
require 'csv'

class EVAServer < Sinatra::Base
	def self.parse_sst_csv()
		arr = Array.new
		CSV.foreach("time_series_from_netcdf.csv") do |row|
			arr.push(row[1])
		end
		set :sst_array, arr
	end

	get '/sst' do
		content_type :json
		return settings.sst_array.to_json
	end

	get '/planetos' do
		puts "newone"
		my_response = {:response => settings.planetOSKey}
		return JSON.generate(my_response)
	end

	# Returns JSON with AQI for SF
	get '/airquality' do
		uri = URI.parse("http://api.airvisual.com/v1/nearest?lat=37.8044&lon=-122.411&key=JnFtBkMz896gGn3qk")
		response = Net::HTTP.get_response(uri)
		json = JSON.parse(response.body)
		aqi = json["data"]["current"]["pollution"]["aqius"]
		location = json["data"]["city"]

		myresponse = Hash.new
		myresponse["aqi"] = aqi
		myresponse["location"] = location

		content_type :json
		return myresponse.to_json
	end

	get '/flights' do
	end

	configure do
		enable :logging
		self.parse_sst_csv()
		puts settings.sst_array
		set :planetOSKey, "38e36fc58dcf4d119c96313bf63e992b"
		set :flightAwareKey, "dde0d7a719093916699a91219c72c1bf6f06c3ec"
	end

	run!
end
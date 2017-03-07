require 'sinatra'
require 'json'
require 'net/http'
require 'sinatra/base'
require 'active_support/core_ext/hash'
require 'nokogiri'
require 'csv'
require 'geocoder'
require 'FlightXML2RESTDriver'

class EVAServer < Sinatra::Base
	def self.parse_sst_csv()
		arr = Array.new
		CSV.foreach("time_series_from_netcdf.csv") do |row|
			arr.push(row[1])
		end
		set :sst_array, arr
	end

	def self.rad(scalar)
		return scalar * Math::PI / 180
	end

	def getDistance(point1, point2)
		radius = 6378137
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

	def self.enrouteFlights()
		results = settings.flightAwareAPI.Enroute(EnrouteRequest.new("KSFO", 10, "", 0))
		cityList = Array.new()
		results.enrouteResult.enroute.each do |enroute|
			cityList << enroute.originCity
		end
	end

	get '/flight_emissions' do
		#cityList = self.enrouteFlights()
		cityList = ["Santa Fe, NM", "New York, NY", "Los Angeles, CA", "Salt Lake City, UT", "Kahului, HI", "Charlotte, NC", "Newark, NJ", "Los Angeles, CA", "Phoenix, AZ"]
		emissionsArr = Array.new()
		cityList.each do |location|
			originPoint = Geocoder.coordinates(location)
			distance = Geocoder::Calculations.distance_between(settings.sfo_coordinates, originPoint)
			if (distance < 300)
				emissionsArr << distance * 0.251
			elsif (distance < 2300)
				emissionsArr << distance * 0.143
			else
				emissionsArr << distance * 0.167
			end
		end
		#Returns a list of carbon emissions per passenger from city list to SFO
		content_type :json
		return emissionsArr.to_s
	end

	configure do
		enable :logging
		self.parse_sst_csv()
		set :planetOSKey, "38e36fc58dcf4d119c96313bf63e992b"
		set :flightAwareKey, "dde0d7a719093916699a91219c72c1bf6f06c3ec"

		flightaware_user = "connorjustice"
		flightaware_key = "dde0d7a719093916699a91219c72c1bf6f06c3ec"
		set :flightAwareAPI, FlightXML2REST.new(flightaware_user, flightaware_key)
		set :sfo_coordinates, [37.7749295, -122.4194155]
	end

	run!
end
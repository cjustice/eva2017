require 'csv'

CSV.foreach("sea_temps.csv", :headers => true) do |row|
  # use row here...
  puts row['NHem']
end
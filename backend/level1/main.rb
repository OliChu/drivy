require 'json'
require 'date'

# OPEN JSON AND PARSE
filepath = 'data/input.json'
serialized_input = File.read(filepath)
input = JSON.parse(serialized_input)

# CREATE VARIABLES
cars = input['cars']
rentals = input['rentals']
prices = {}

# SETTING PRICES
rentals.each do |rental|
  number_of_days = (DateTime.strptime(rental['end_date'], '%Y-%m-%d') - DateTime.strptime(rental['start_date'], '%Y-%m-%d') + 1).to_i
  car = cars.detect{ |car| car['id'] == rental['id'] }
  price = (number_of_days * car['price_per_day'].to_i) + (rental['distance'].to_i * car['price_per_km'].to_i)
  if prices['rentals'].nil?
    prices['rentals'] = [{ id: car['id'], price: price }]
  else
    prices['rentals'] << { id: car['id'], price: price }
  end
end

# WRITE JSON
output_filepath = 'data/output.json'
File.open(output_filepath, 'wb') do |file|
  file.write(JSON.pretty_generate(prices))
end

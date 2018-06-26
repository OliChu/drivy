require 'json'
require 'date'


def weighting_coefficient(number_of_days)
  coefficient = 1
  if 1 < number_of_days && number_of_days <= 4
    coefficient -= 0.10
  elsif 4 < number_of_days && number_of_days <= 10
    coefficient -= 0.30
  elsif number_of_days > 10
    coefficient -= 0.5
  end
  return coefficient
end

def calcul_rental_price(number_of_days, price_per_day)
  (1..number_of_days).to_a.reduce(0){ |sum, day| sum + price_per_day * weighting_coefficient(day) }
end

def calcul_commission_fees(price, number_of_days)
  commission = (price * 0.30).to_i
  insurance_fee = (commission * 0.50).to_i
  assistance_fee = 100 * number_of_days
  drivy_fee = commission - (insurance_fee + assistance_fee)
  {
    "insurance_fee": insurance_fee,
    "assistance_fee": assistance_fee,
    "drivy_fee": drivy_fee
  }
end

# OPEN JSON AND PARSE
filepath = 'data/input.json'
serialized_input = File.read(filepath)
input = JSON.parse(serialized_input)

# CREATE VARIABLES
cars = input['cars']
rentals = input['rentals']
prices = { 'rentals' => []}

# SETTING PRICES
rentals.each do |rental|
  number_of_days = (DateTime.strptime(rental['end_date'], '%Y-%m-%d') - DateTime.strptime(rental['start_date'], '%Y-%m-%d') + 1).to_i
  car = cars.detect{ |car| car['id'] == rental['car_id'] }
  price = (calcul_rental_price(number_of_days, car['price_per_day'].to_i) + (rental['distance'].to_i * car['price_per_km'].to_i)).to_i
  commission = calcul_commission_fees(price, number_of_days)
  prices['rentals'] << { id: rental['id'], price: price, commission: commission }
end

# WRITE JSON
output_filepath = 'data/output.json'
File.open(output_filepath, 'wb') do |file|
  file.write(JSON.pretty_generate(prices))
end

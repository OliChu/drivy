require 'json'
require 'date'

def write_output_json(data, output_filepath)
  File.open(output_filepath, 'wb') do |file|
    file.write(JSON.pretty_generate(data))
  end
end

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

def calcul_rental_price(number_of_days, price_per_day, distance, price_per_km)
  price_total_days = (1..number_of_days).to_a.reduce(0){ |sum, day| sum + price_per_day * weighting_coefficient(day) }
  price_for_km = distance * price_per_km
  price_total_days + price_for_km
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

def calcul_options_price(rental_options, number_of_days)
  price_for_options = { 'drivy' => 0, 'owner' => 0 , 'driver' => 0 }
  rental_options.each do |option|
    if option['type'] == 'gps'
      price_for_options['owner'] += number_of_days * 500
      price_for_options['driver'] += number_of_days * 500
    elsif option['type'] == 'baby_seat'
      price_for_options['owner'] += number_of_days * 200
      price_for_options['driver'] += number_of_days * 200
    else
      price_for_options['drivy'] += number_of_days * 1000
      price_for_options['driver'] += number_of_days * 1000
    end
  end
  p price_for_options
end

# OPEN JSON AND PARSE
filepath = 'data/input.json'
serialized_input = File.read(filepath)
input = JSON.parse(serialized_input)

# CREATE VARIABLES
cars = input['cars']
rentals = input['rentals']
options = input['options']
prices = { 'rentals' => [] }

# SETTING PRICES
rentals.each do |rental|
  number_of_days = (DateTime.strptime(rental['end_date'], '%Y-%m-%d') - DateTime.strptime(rental['start_date'], '%Y-%m-%d') + 1).to_i
  car = cars.detect{ |car| car['id'] == rental['car_id'] }
  rental_options = options.select{ |option| option['rental_id'] == rental['id'] }
  price = calcul_rental_price(number_of_days, car['price_per_day'].to_i, rental['distance'].to_i, car['price_per_km'].to_i)
  commission = calcul_commission_fees(price, number_of_days)
  price_for_options = calcul_options_price(rental_options, number_of_days)
  actions = [
    {
      "who": "driver",
      "type": "debit",
      "amount": (price + price_for_options['driver']).to_i
    },
    {
      "who": "owner",
      "type": "credit",
      "amount": (price * 0.7).to_i + price_for_options['owner']
    }]
    commission.each do |type, amount|
      action = {
        "who": type.to_s.gsub('_fee', ''),
        "type": "credit",
        "amount": amount + price_for_options[type.to_s.gsub('_fee', '')].to_i
      }
      actions << action
    end
  prices['rentals'] << { id: rental['id'], options: rental_options.map { |option| option['type']}, actions: actions }
end

# WRITE JSON
output_filepath = 'data/output.json'
write_output_json(prices, output_filepath)

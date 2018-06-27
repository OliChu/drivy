require 'json'
require 'date'

# DECLARING KM WEIGHTING CONSTANTS
WEIGHT_1 = 0.10
WEIGHT_2 = 0.30
WEIGHT_3 = 0.50

# DECLARING COMMISION RATES
COMMISSION_RATE  = 0.30
INSURANCE_RATE   = 0.50
ASSISTANCE_PRICE = 100

#####################
# DECLARING METHODS #
#####################

def load_data_from_json(filepath)
  begin
    serialized_input = File.read(filepath)
    input = JSON.parse(serialized_input)
  rescue Exception => e
    puts e.message
  end
end

def write_data_to_json(filepath, output)
  begin
    File.open(filepath, 'wb') do |file|
      file.write(JSON.pretty_generate(output))
    end
  rescue Exception => e
    puts e.message
  end
end

def calculate_rental_days(start_date, end_date)
  (DateTime.strptime(end_date, '%Y-%m-%d') - DateTime.strptime(start_date, '%Y-%m-%d') + 1).to_i
end

def weighting_coefficient(number_of_days)
  coefficient = 1
  if 1 < number_of_days && number_of_days <= 4
    coefficient -= WEIGHT_1
  elsif 4 < number_of_days && number_of_days <= 10
    coefficient -= WEIGHT_2
  elsif number_of_days > 10
    coefficient -= WEIGHT_3
  end
  return coefficient
end

def calcul_rental_price(number_of_days, price_per_day, distance, price_per_km, weighting)
  price_total_days = (1..number_of_days).to_a.reduce(0) do |sum, day|
    weighting ? sum + price_per_day * weighting_coefficient(day) : sum + price_per_day
  end
  price_for_km = distance * price_per_km
  (price_total_days + price_for_km).to_i
end

def calcul_commission_fees(price, number_of_days)
  commission = (price * COMMISSION_RATE).to_i
  insurance_fee = (commission * INSURANCE_RATE).to_i
  assistance_fee = ASSISTANCE_PRICE * number_of_days
  drivy_fee = commission - (insurance_fee + assistance_fee)
  {
    "insurance_fee": insurance_fee,
    "assistance_fee": assistance_fee,
    "drivy_fee": drivy_fee
  }
end

def generate_actions(price, commission, options: price_for_options)
  actions = [
    {
      "who": "driver",
      "type": "debit",
      "amount": options.nil? ? price : (price + options['driver']).to_i
    },
    {
      "who": "owner",
      "type": "credit",
      "amount": options.nil? ? (price * (1 - COMMISSION_RATE)).to_i : (price * (1 - COMMISSION_RATE)).to_i + options['owner']
    }]
  commission.each do |type, amount|
    action = {
      "who": type.to_s.gsub('_fee', ''),
      "type": "credit",
      "amount": options.nil? ? amount : amount + options[type.to_s.gsub('_fee', '')].to_i
    }
    actions << action
  end
  actions
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
  price_for_options
end

require '../common_methods'

# OPEN JSON AND PARSE
input_filepath = 'data/input.json'
input = load_data_from_json(input_filepath)

unless input.nil?
  # CREATE VARIABLES
  cars = input['cars']
  rentals = input['rentals']
  output = { 'rentals' => [] }

  # SETTING PRICES
  rentals.each do |rental|
    number_of_days = calculate_rental_days(rental['start_date'], rental['end_date'])
    car = cars.detect{ |car| car['id'] == rental['car_id'] }
    price = calcul_rental_price(number_of_days, car['price_per_day'], rental['distance'], car['price_per_km'], false) unless car.nil?

    if number_of_days < 0 || car.nil? || price < 0
      puts "Incorrect unput data for rental id:#{rental['id']}"
    else
      output['rentals'] << { id: rental['id'], price: price }
    end
  end

  # WRITE JSON
  output_filepath = 'data/output.json'
  write_data_to_json(output_filepath, output)
end

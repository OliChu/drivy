require '../common_methods'

# OPEN JSON AND PARSE
input_filepath = 'data/input.json'
input = load_data_from_json(input_filepath)

unless input.nil?
  # CREATE VARIABLES
  cars = input['cars']
  rentals = input['rentals']
  options = input['options']
  output = { 'rentals' => [] }

  # SETTING PRICES
  rentals.each do |rental|
    number_of_days = calculate_rental_days(rental['start_date'], rental['end_date'])
    car = cars.detect{ |car| car['id'] == rental['car_id'] }
    rental_options = options.select{ |option| option['rental_id'] == rental['id'] }

    unless car.nil?
      price = calcul_rental_price(number_of_days, car['price_per_day'], rental['distance'], car['price_per_km'], true)
      commission = calcul_commission_fees(price, number_of_days)
      price_for_options = calcul_options_price(rental_options, number_of_days)
      actions = generate_actions(price, commission, options: price_for_options)
    end

    if number_of_days < 0 || car.nil?
      puts "Incorrect input data for rental id:#{rental['id']}"
    else
      output['rentals'] << { id: rental['id'], options: rental_options.map { |option| option['type']}, actions: actions }
    end
  end

  # WRITE JSON
  output_filepath = 'data/output.json'
  write_data_to_json(output_filepath, output)
end

require 'json'
require 'pry'
load 'merge_results.rb'

class FormatResults
  def initialize(input, keys_to_format, start_year, remove_keys, merge_keys)
    @input = JSON.parse(File.read(input))
    @file_path = input
    @keys_to_format = keys_to_format
    @start_year = start_year
    @output = Hash.new
    @earliest_year = 2016
    @latest_year = 0
    @formatted_out = Array.new
    @remove_keys = remove_keys
    @merge_keys = merge_keys
  end

  # Put the years in numerical order in hash
  def order_years(item)
    return item.sort_by{|k, v| k.to_i}
  end

  # Remove the urls from the item, leaving only the counts
  def remove_urls(item)
    itemhash = Hash.new
    item.each do |k,v|
      itemhash[k] = v[0]
    end
    return itemhash
  end

  # Remove year 0 if it exists
  def remove_year_zero(item)
    item.delete("0")
    return item
  end

  # Do some basic cleaning of item
  def basic_parsing(item)
    remove_year_zero(remove_urls(order_years(item)))
  end

  # Reorder dates
  def reorder_dates
    @output.each do |key, value|
      itemhash = Hash.new
      order_years(value).each do |k, v|
        itemhash[k] = v
      end
      @output[key] = itemhash
    end
  end

  # Get earliest and latest years in set
  def get_earliest_latest
    @output.each do |key, value|
      value.each do |k, v|
        year = k.to_i
        @earliest_year = year if year < @earliest_year
        @latest_year = year if year > @latest_year
      end
    end
    @earliest_year = @start_year if @start_year > @earliest_year
  end

  # Fill in blank years for each item
  def fill_in_blanks
    @output.each do |key, value|
      (@earliest_year..@latest_year).each do |year|
        @output[key][year.to_s] = 0 if !value[year.to_s]
      end
      remove_earlier(key, @output[key])
    end
  end

  # Remove earlier than earliest
  def remove_earlier(key, val)
    @output[key] = val.keep_if{|k, v| k.to_i > @earliest_year}
  end

  # Add up all and get top x
  def add_all
    outputhash = Hash.new

    # Count up all values
    @output.each do |key, value|
      count = 0
      value.each{|k,v| count+= v}
      outputhash[key] = count
    end

    keeparr = Array.new
    outputhash.sort_by{|k, v| v}.reverse[0..@keys_to_format].each{|i| keeparr.push(i[0])}
    @output = @output.keep_if{|k, v| keeparr.include?(k)}
  end

  # Cut all values except certain keys
  def cut_except
    if @keys_to_format.is_a?(Integer)
      add_all
      # Get top x by overall count
    elsif @keys_to_format != "all"
      @output = @output.keep_if{|k, v| @keys_to_format.include?(k)}
    end
  end

  # Make array of all years
  def year_array
    return ['x'] +(@earliest_year..@latest_year).to_a
  end

  # Parse the output into an array that works with the js
  def parse_out(key, value)
    @formatted_out.push(([key]+value.values))
  end

  # Format outut
  def format_output
    @formatted_out.push(year_array)
    @output.each do |key, value|
      parse_out(key, value)
    end
  end

  # Preprocess the input data
  def preprocess_data
    # Remove things if needed
    if @remove_keys
      @input = @input.delete_if{|k, v| @remove_keys.include?(k)}
    end
    
    # Merge results
    if @merge_keys
      m = MergeResults.new(@file_path, @merge_keys, "crossreference_merge")
      merged = JSON.parse(m.merge)

      # Change keys in input
      merge_values = Array.new
      @merge_keys.each{|k,v| merge_values+=v}
      @input.delete_if{|k, v| merge_values.include?(k)}
      merged.each{|k,v| @input[k] = v}
    end
  end

  # Format files
  def format
    preprocess_data
    
    @input.each do |key, value|
      @output[key] = basic_parsing(value)
    end

    # Reorder the dates and fill in blanks
    get_earliest_latest
    fill_in_blanks
    reorder_dates
    cut_except

    format_output
    return JSON.pretty_generate(@formatted_out)
  end
end

f = FormatResults.new("../results/languages3_trend.json", 10, 1990, ["Latin"], {"Farsi" => ["Farsi", "Persian"]})
puts f.format



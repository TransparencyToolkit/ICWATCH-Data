require 'json'

class FormatResults
  def initialize(input, keys_to_format)
    @input = JSON.parse(File.read(input))
    @keys_to_format = keys_to_format
  end

  def order_years(item)
  end

  def format
  end
end




# Take a JSON file with key: year:[count, urls] and return in format needed for c3
# Take list of keys to format or just all

# Format needed-
#['x', '2000', '2001', '2002']
#['name', val2000, val2001, val2002]

# Put years in order for each item
# Remove URLs
# Remove year 0 key

# Get earliest and latest years in set
# Fill in blank years as needed in all items
# Make array of all years in range
# Make array of each item
# Return array of arrays


# Load in array of arrays

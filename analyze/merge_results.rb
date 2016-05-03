require 'json'
require 'pry'

class MergeResults
  def initialize(file, merge_these, merge_type)
    @file = JSON.parse(File.read(file))
    @merge_these = merge_these
    @merge_type = merge_type
    @output = Hash.new
  end

  def merge
    @merge_these.each do |k, v|
      if v.length > 1
        # Merge losslessly
        if @merge_type == "add_merge"
          @output[k] = lossless_merge(v)
          
        # Merge match by ID
        elsif @merge_type == "crossreference_merge"
          @output[k] = crossreference_merge(v)
        end
      else
        @output[k] = @file[v[0]]
      end
    end

    JSON.pretty_generate(@output)                    
  end

  # Merge by only adding new ones
  def crossreference_merge(terms_to_merge)
    # Get an array of hashes to add together
    hashes_to_merge = Array.new
    terms_to_merge.each{|t| hashes_to_merge.push(@file[t])}
    final_hash = Hash.new

    # Get a list of all the keys in each
    all_keys = Array.new
    hashes_to_merge.each{|h| all_keys += h.keys}
    all_keys = all_keys.uniq
    
    all_keys.each do |key|
      final_hash[key] = [0, []]

      # Go through all hashes
      hashes_to_merge.each do |h|
        # Go through all IDs in hash
        if h[key]
          h[key][1].each do |id|
            # Increment if ID is not already in list for key
            if !final_hash[key][1].include?(id)
              final_hash[key][0] += 1
              final_hash[key][1].push(id)
            end
          end
        end
      end
    end
    return final_hash
  end

  # Add values when merging instead of losing elements
  def lossless_merge(terms_to_merge)
    # Get an array of hashes to add together
    hashes_to_merge = Array.new
    terms_to_merge.each{|t| hashes_to_merge.push(@file[t])}
    final_hash = Hash.new

    # Get a list of all the keys in each
    all_keys = Array.new
    hashes_to_merge.each{|h| all_keys += h.keys}
    all_keys = all_keys.uniq

    # Add value for each key
    all_keys.each do |key|
      final_hash[key] = 0

      # Add hashes
      hashes_to_merge.each do |hash|
        final_hash[key] += hash[key].to_i
      end
    end

    return final_hash
  end
end

m = MergeResults.new("/home/shidash/Data/ICWATCH-Data/analyze/test_merge.json", {
                       "SIGINT" => ["signals intelligence", "SIGINT"],
                       "Intercept" => ["intercept", "interception"],
                       "xkeyscore" => ["xkeyscore", "xks"]}, "crossreference_merge")
puts m.merge

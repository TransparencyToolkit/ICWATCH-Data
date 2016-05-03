require 'json'
require 'pry'
load 'timeline.rb'

class MultipleTimeline
  def initialize(datasets)
    @datasets = datasets
    @output
  end

  # Loop through terms instead of datasets
#  def run_terms
 #  @datasets.each do |dataset|
  #    @dataset[:search_word_list].each do |term|
   #     system("cd /home/shidash/PI/LookingGlass/lib; rails runner 'RunTrends.get_all_with_term(#{dataset}, #{term})'")
   #   end
   # end
 # end

  # Run one for each dataset
  def run_all
    # Loop through each dataset and run
    @datasets.each do |dataset|
      system("cd /home/shidash/PI/LookingGlass/lib; rails runner 'RunTrends.get_all_of_type(#{dataset})'")
    end

    # Group and print output
    @output = aggregate_output(load_all_raw)
    print_output
  end

  # Load raw output for each dataset
  def load_all_raw
    raw_output = Array.new
    @datasets.each do |dataset|
      file_name = "/home/shidash/PI/LookingGlass/lib/trends/"+dataset[:index]+"_"+dataset[:trend_name]+".json"
      raw_output.push(File.read(file_name))
    end
    return raw_output
  end

  # Add values when merging instead of losing elements
  def lossless_merge(hash1, hash2)
    final_hash = Hash.new
    all_keys = hash1.keys + hash2.keys # Get all keys

    # Add value for each key
    all_keys.each do |key|
      if hash1[key].is_a?(Array) || hash2[key].is_a?(Array)
        if !hash1.empty? && !hash2.empty? && hash1[key] && hash2[key]
          overall_count = hash1[key][0].to_i + hash2[key][0].to_i
          all_ids = hash1[key][1] + hash2[key][1]
          final_hash[key] = [overall_count, all_ids]
        else
          non_empty = (hash1.empty? || !hash1[key]) ? hash2 : hash1
          final_hash[key] = non_empty[key]
        end
      else # Just normal num
        final_hash[key] = hash1[key].to_i + hash2[key].to_i
      end
    end

    return final_hash
  end

  # Aggregate output across years
  def aggregate_output(raw_output)
    aggregate_hash = Hash.new

    raw_output.each do |output|
      parsed_out = JSON.parse(output)
      parsed_out.each do |key, value|

        # First time key was seen
        if !aggregate_hash[key]
          aggregate_hash[key] = value
        else # Merge- does not exist
          aggregate_hash[key] = lossless_merge(aggregate_hash[key], parsed_out[key])
        end
      end
    end

    return aggregate_hash
  end

  # Print out the full output
  def print_output
    JSON.pretty_generate(@output)
  end
end

list_path = "/home/shidash/Data/ICWATCH-Data/term_lists/sector.json"

li_sector = {ignore_incl: "_terms.json",
             search_word_list: ["SIGINT", "signals intelligence", "interception", "intercept", "xkeyscore", "xks"],
             date_field: ["start_date", "end_date"],
             id_field: "profile_url",
             extract_field: ["type"],
             case_sensitive: false,
             individual_stats: true,
             index: "icwatch_linkedin",
             trend_name: "sector",
             trend_type: "timeline",
             output_format: "split"}

linkedin = {ignore_incl: "_terms.json",
            search_word_list: JSON.parse(File.read(list_path)),
            date_field: ["start_date", "end_date"],
            id_field: "profile_url",
            extract_field: ["description"],
            case_sensitive: false,
            individual_stats: true,
            index: "icwatch_linkedin",
            trend_name: "sector4",
            trend_type: "timeline",
            output_format: "with_id"}

indeed = {ignore_incl: "_terms.json",
          search_word_list: JSON.parse(File.read(list_path)),
          date_field: ["start_date", "end_date"],
          id_field: "url",
          extract_field: ["job_description"],
          case_sensitive: false,
          individual_stats: true,
          index: "icwatch_indeed",
          trend_name: "sector4",
          trend_type: "timeline",
          output_format: "with_id" }

m = MultipleTimeline.new([linkedin, indeed])
puts m.run_all

require 'json'
require 'pry'
require 'date'

class Timeline
  def initialize(ignore_incl, search_word, date_field, id_field, extract_field, case_sensitive, individual_stats)
    @ignore_incl = ignore_incl
    @search_word = search_word
    @date_field = date_field.map{|d| d}
    @id_field = id_field
    @extract_field = extract_field
    @case_sensitive = case_sensitive
    @individual_stats = individual_stats

    # Create a hash for each search term if individual_stats true
    if !@individual_stats
      @date_hash = Hash.new
    elsif @individual_stats
      @term_hash = Hash.new
      @search_word.each{|term| @term_hash[term] = {}}
    end
  end

  # Go through all JSON files in dir and subdirs
  def timelineAll(dir)
    Dir.foreach(dir) do |file|
      next if file == '.' || file == '..' || file.include?(@ignore_incl)
      if File.directory?(dir+"/"+file)
        timelineAll(dir+"/"+file)
      elsif file.include? ".json"
        json = JSON.parse(File.read(dir+"/"+file))
        json.each do |item|
          processItem(item)
        end
      end
    end
  end

  # Extracts codewords from item
  def processItem(item, word)
    # Check all fields for term
    @extract_field.each do |field|
      # @search_word.each do |word|
        if matchTerm?(word, item[field])
          addDate(item, word)
        end
     # end
    end
  end

  # Check if the term appears in the text
  def matchTerm?(term, text)
    # Downcase term and text if not case sensitive
    if @case_sensitive == false
      term = term.to_s.downcase
      text = text.to_s.downcase
    end
  #  binding.pry if text.include?("xkeyscore")
    # Return if it maches
    if text.to_s.match(/\b(#{term})\b/)
      return true
    end
  end

  # Increment/add date if not already added for that profile
  def addDate(item, word)
    # Return if no date field
    return if !(item[@date_field[0]])
    toadd = processDate(item)

    # Increment in save hash
    toadd.each do |date|
      if @individual_stats
        add_by_term(date, item, word)
      else
        add_aggregate(date, item)
      end
    end
  end

  # Add by term hash if not already added
  def add_by_term(date, item, word)
#    binding.pry if @term_hash[word].length > 0
    if @term_hash[word][date]
      # Increment if ID not already listed, otherwise do nothing
      if !@term_hash[word][date][1].include?(item[@id_field])
        @term_hash[word][date][0] += 1
        @term_hash[word][date][1].push(item[@id_field])
      end
    else # Add first for field if already added
      @term_hash[word][date] = [1, [item[@id_field]]]
    end
  end
  
  # Add in aggregate if not added already for profile
  def add_aggregate(date, item)
    if @date_hash[date]
      if !@date_hash[date][1].include?(item[@id_field])
        @date_hash[date][0] += 1
        @date_hash[date][1].push(item[@id_field])
      end
    else
      @date_hash[date] = [1, [item[@id_field]]]
    end
  end

  # Figure out what years to add
  def processDate(item)
    # Get start and end years
    start_year = item[@date_field[0]].to_s.split("-")[0].to_i
    datearr = [start_year]
    if item[@date_field[1]].to_s
      endd = item[@date_field[1]].to_s.split("-")[0].to_i
      # Check that it isn't an impossible date (was before scraped) if not current
      if endd.to_i > Time.now.to_s.split("-")[0].to_i || endd.to_i == 0 # Remove grossly incorrect dates
        end_year = start_year
      elsif item["current"] == "No"
        # Add end dates only if not current year
        if endd != Time.now.to_s.split("-")[0].to_i
          end_year = item[@date_field[1]].to_s.split("-")[0].to_i
          datearr.push(end_year)
        else
          end_year = start_year
        end
      else
        end_year = item[@date_field[1]].to_s.split("-")[0].to_i
        datearr.push(end_year)
      end
    elsif item["current"] == "Yes" # Get year for current positions
      end_year = Time.now.to_s.split("-")[0].to_i
      datearr.push(end_year)
    else
      end_year = start_year
    end

    # Get the years in between
    difference = (end_year - start_year)
   
    cur_year = start_year
    difference.times do
      cur_year += 1
      datearr.push(cur_year)
    end
    
    return datearr.uniq
  end

  # Keep the ID when returning output
  def output_keep_id
    JSON.pretty_generate(@term_hash)
  end

  # Formats output in JSON
  def format_output_aggregate
    # Remove list of profiles
    @outhash = Hash.new
      
    @date_hash.each do |key, val|
      @outhash[key] = val[0]
    end

    JSON.pretty_generate(@outhash.sort)
  end

  # Formats output for split output
  def format_output_split
    # Remove list of profiles
    @outhash = Hash.new
    
    @term_hash.each do |key, val|
      temphash = Hash.new
      val.each do |k, v|
        temphash[k] = v[0]
      end
      @outhash[key] = temphash
    end

    return JSON.pretty_generate(@outhash)
  end
end
#t = Timeline.new("_terms.json", ["UTT", "Unified Targeting Tool"], ["start_date", "end_date"], "profile_url", ["description"], false)
#t.timelineAll("/home/gh/data/disk/sigint/li_data")
#puts t.formatOutput

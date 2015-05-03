require 'json'
require 'pry'
require 'date'

class Timeline
  def initialize(ignore_incl, search_word, date_field, id_field, extract_field, case_sensitive)
    @ignore_incl = ignore_incl
    @search_word = search_word
    @date_field = date_field
    @id_field = id_field
    @extract_field = extract_field
    @case_sensitive = case_sensitive

    @date_hash = Hash.new
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
  def processItem(item)
    # Check all fields for term
    @extract_field.each do |field|
      @search_word.each do |word|
        if matchTerm?(word, item[field])
          addDate(item)
        end
      end
    end
  end

  # Check if the term appears in the text
  def matchTerm?(term, text)
    # Downcase term and text if not case sensitive
    if @case_sensitive == false
      term = term.to_s.downcase
      text = text.to_s.downcase
    end
    # Return if it maches
    if text.to_s.match(/\b(#{term})\b/)
      return true
    end
  end

  # Increment/add date if not already added for that profile
  def addDate(item)
    return if !(item[@date_field[0]])
    toadd = processDate(item)
    
    toadd.each do |date|
      if @date_hash[date]
        if !@date_hash[date][1].include?(item[@id_field])
          @date_hash[date][0] += 1
          @date_hash[date][1].push(item[@id_field])
        end
      else
        @date_hash[date] = [1, [item[@id_field]]]
      end
    end
  end

  # Figure out what years to add
  def processDate(item)
    # Get start and end years
    start_year = item[@date_field[0]].split("-")[0].to_i
    datearr = [start_year]
    if item[@date_field[1]]
      # Check that it isn't an impossible date (was before scraped) if not current
      if item["current"] == "No"
        endd = item[@date_field[1]].split("-")[0].to_i

        # Add end dates only if not current year
        if endd != Time.now.to_s.split("-")[0].to_i
          end_year = item[@date_field[1]].split("-")[0].to_i
          datearr.push(end_year)
        else
          end_year = start_year
        end
      else
        end_year = item[@date_field[1]].split("-")[0].to_i
        datearr.push(end_year)
      end
    elsif item["current"] == "Yes" # Get year for current positions
      end_year = Time.now.to_s.split("-")[0].to_i
      datearr.push(end_year)
    else
      end_year = start_year
    end

    # Get the years in between
    difference = start_year - end_year - 1
    cur_year = start_year
    difference.times do
      cur_year += 1
      datearr.push(cur_year)
    end
    
    return datearr.uniq
  end

  # Formats output in JSON
  def formatOutput
    # Remove list of profiles
    @outhash = Hash.new
    @date_hash.each do |key, val|
      @outhash[key] = val[0]
    end

    JSON.pretty_generate(@outhash.sort)
  end
end
t = Timeline.new("_terms.json", ["SIGINT", "signals intelligence", "signals analysis", "signal analysis", "signal analyst", "signals analyst"], ["start_date", "end_date"], "profile_url", ["description"], false)
t.timelineAll("/home/gh/data/disk/sigint/li_data")
puts t.formatOutput

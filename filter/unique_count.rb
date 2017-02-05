require 'json'

class UniqueCount
  def initialize(unique_id, ignore_include)
    @unique_id = unique_id
    @ignore_include = ignore_include
    @profile_list = Array.new
  end

  # Go through all JSON files in dir and subdirs
  def getAll(dir)
    Dir.foreach(dir) do |file|
      next if file == '.' || file == '..' || file.include?(@ignore_include)
      if File.directory?(dir+"/"+file)
        getAll(dir+"/"+file)
      elsif file.include? ".json"
        json = JSON.parse(File.read(dir+"/"+file))
        json.each do |item|
          if !@profile_list.include?(item[@unique_id])
            @profile_list.push(item[@unique_id])
          end
        end
      end
    end
  end

  def getCount
    @profile_list.length
  end
end
u = UniqueCount.new("url", "_terms.json")
u.getAll("../../indeed_fix_test/smaller")
puts u.getCount

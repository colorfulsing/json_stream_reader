require './lib/json_stream_parser'
require 'json'

# Usage:
#   $ ruby get_sample.rb my_big_file.json [limit] [offset] [sample_file_name]

# get params and set default values
file_path = ARGV[0].to_s.strip
raise StandardError.new('Must specify filepath') if file_path.length < 1
limit = ARGV[1].to_i rescue 0
limit = 10 if limit < 1
offset = ARGV[2].to_i rescue 0
sample_path = ARGV[3].to_s.strip
sample_path = './sample.json' if sample_path.length < 1

# create sample file
real_counter = 0
counter = 0
File.open(sample_path, 'w') do |f|
  f.puts '['
  
  JsonStreamParser.parse(file_path) do |data|
    # skip until offset
    real_counter += 1
    next unless real_counter > offset

    # exit on sample limit
    break unless counter < limit

    # write element to sample file
    f.write ', ' if counter > 0
    f.write JSON.pretty_generate(data)

    # count elements on sample
    counter += 1
  end

  f.puts ']'
end

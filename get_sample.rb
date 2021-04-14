require './lib/json_stream_parser'
require 'json'

file_path = ARGV[0].to_s.strip
raise StandardError.new('Must specify filepath') if file_path.length < 1
limit = ARGV[1].to_i rescue 0
limit = 10 if limit < 1
offset = ARGV[2].to_i rescue 0
real_counter = 0
counter = 0
File.open('sample.json', 'w') do |f|
  f.write '['
  f.puts ""
  
  JsonStreamParser.parse('./test.json') do |data|
    real_counter += 1
    if real_counter > offset
        unless counter < limit
            break
        end
        
        f.write ',' if counter > 0
        
        f.write JSON.pretty_generate(data)
        counter += 1
    end
  end
  
  f.puts ""
  f.write ']'
end

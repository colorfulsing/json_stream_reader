require './lib/json_stream_parser'

JsonStreamParser.parse('./test.json') do |data|
  puts data
end

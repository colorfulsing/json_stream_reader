require 'json/stream'

class JsonStreamParser
  # Parse a JSON file and execute a block for each level 1 object.
  #
  # @param [String] JSON file path to parse.
  # @yield [data] Provide the latest parsed element at level 1.
  def self.parse file_path, &block
    parser = self.new &block
    parser.parse file_path
  end

  # Build a streamed json parser.
  #
  # @yield [data] Provide the latest parsed element at level 1.
  def initialize &block
    config!
    self.process_data = block
  end

  # Object stack.
  #
  # @return [Array]
  def stack
    @stack ||= []
  end

  # Object stack.
  #
  # @return [Array]
  def key_stack
    @key_stack ||= []
  end

  # Block to be executed when an item on from #levels_to_process is fully parsed.
  #
  # @return [Lambda,Proc] Event block.
  def process_data
    @process_data || nil
  end

  # Set the block to be executed when an item is processed.
  #
  # @param [Lambda,Proc] value Block to set. It should have 1 argument.
  def process_data= value
    if value.nil? || value.class != Proc
      raise ArgumentError.new("\"process_data\" has to be a Proc or Lambda.")
    end
    # Check for argument quantity
    if value.arity != 1 || value.arity < -1
      raise ArgumentError.new("\"process_data\" requires 1 argument.")
    end
    @process_data = value
  end

  # Process an item and execute #process_data when a single first level object
  #  is parsed.
  #
  # @return [Boolean] `true` when level 0 or level 1 object processed, else `false`.
  def process_on_item
    # Assume first level to be array so ignore it
    return true if stack.count < 1

    # Process only top level items
    return false if stack.count > 1

    raise ArgumentError.new("\"process_data\" can't be null!") if process_data.nil?
    process_data.call stack.pop, stack.count
    true
  end

  # Process a single parsed object from a single level.
  def process_item
    return if process_on_item

    # Save child on parent
    object = stack.pop
    parent = stack.last
    if parent.is_a? Array
      parent << object
      return
    end
    parent[key_stack.pop] = object
  end

  # Parser object.
  #
  # @return [JSON::Stream::Parser] Parser object.
  def parser
    @parser ||= JSON::Stream::Parser.new
  end

  # Config the parser object.
  def config!
    # start_document { puts "start document" }
    # end_document   { puts "end document" }
    parser.start_object{ stack << {} }
    parser.end_object{ process_item }
    parser.start_array{ stack << [] if stack.count > 0 }
    parser.end_array{ process_item }
    parser.key{|k| key_stack << k }
    parser.value{|v| stack.last[key_stack.pop] = v }
  end

  # Reset the parser object and configure it.
  def reset!
    @parser = nil
    config!
  end

  # Parse a JSON file.
  #
  # @param [String] JSON file path to parse.
  def parse file_path
    raise ArgumentError.new("\"file_path\" can't be null.") if file_path.nil?
    raise ArgumentError.new("File \"#{file_path}\" not exists!") unless File.exist? file_path

    stream = nil
    begin
      stream = File.open(file_path)
      count = 0
      stream.each_line do |line|
        parser << line
        count += 1

        # Collect garbage to prevent memory overflow
        next if count < 5000
        GC.start
        count = 0
      end
    ensure
      stream.close unless stream.nil?
    end
  end
end

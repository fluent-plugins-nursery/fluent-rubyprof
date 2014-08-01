require 'optparse'
require 'drb/drb'

def parse_options
  op = OptionParser.new
  op.banner += ' <start/stop> [output_file]'

  (class<<self;self;end).module_eval do
    define_method(:usage) do |msg|
      puts op.to_s
      puts "error: #{msg}" if msg
      exit 1
    end
  end

  opts = {
    host: '127.0.0.1',
    port: 24230,
    unix: nil,
    command: nil, # start or stop
    output: '/tmp/fluent-rubyprof.txt'
  }

  op.on('-h', '--host HOST', "fluent host (default: #{opts[:host]})") {|v|
    opts[:host] = v
  }

  op.on('-p', '--port PORT', "debug_agent tcp port (default: #{opts[:host]})", Integer) {|v|
    opts[:port] = v
  }

  op.on('-u', '--unix PATH', "use unix socket instead of tcp") {|v|
    opts[:unix] = v
  }

  op.on('-o', '--output PATH', "output path (default: #{opts[:output]})") {|v|
    opts[:output] = v
  }

  begin
    op.parse!(ARGV)
    opts[:command] = ARGV.shift
    unless %w[start stop].include?(opts[:command])
      usage "`start` or `stop` must be specified as the 1st argument"
    end
  rescue
    usage $!.to_s
  end

  opts
end

def main
  opts = parse_options

  unless opts[:unix].nil?
    uri = "drbunix:#{opts[:unix]}"
  else
    uri = "druby://#{opts[:host]}:#{opts[:port]}"
  end

  $remote_engine = DRb::DRbObject.new_with_uri(uri)

  case opts[:command]
  when 'start'
    remote_code = <<-CODE
      require 'ruby-prof'
      RubyProf.start
    CODE
  when 'stop'
    remote_code = <<-"CODE"
      result = RubyProf.stop
      File.open('#{opts[:output]}', 'w') {|f|
        RubyProf::FlatPrinter.new(result).print(f)
      }
    CODE
  end

  $remote_engine.method_missing(:instance_eval, remote_code)
end

main

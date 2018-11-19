require 'optparse'
require 'drb/drb'

module Fluent
  class Rubyprof

    PRINTERS = {
      'flat' => 'FlatPrinter',
      'flat_with_line_numbers' => 'FlatPrinterWithLineNumbers',
      'graph' => 'GraphPrinter',
      'graph_html' => 'GraphHtmlPrinter',
      'call_stack' => 'CallStackPrinter',
      'dot' => 'DotPrinter',
    }

    def parse_options(argv = ARGV)
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
        output: '/tmp/fluent-rubyprof.txt',
        measure_mode: 'PROCESS_TIME',
        printer: 'flat',
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

      op.on('-m', '--measure_mode MEASURE_MODE', "ruby-prof measure mode (default: #{opts[:measure_mode]})") {|v|
        opts[:measure_mode] = v
      }

      op.on('-P', '--printer PRINTER', PRINTERS.keys,
                "ruby-prof print format (default: #{opts[:printer]})",
                "currently one of: #{PRINTERS.keys.join(', ')}") {|v|
        opts[:printer] = v
      }
      op.parse!(argv)

      opts[:command] = argv.shift
      unless %w[start stop].include?(opts[:command])
        raise OptionParser::InvalidOption.new("`start` or `stop` must be specified as the 1st argument")
      end

      measure_modes = %w[PROCESS_TIME WALL_TIME CPU_TIME ALLOCATIONS MEMORY GC_RUNS GC_TIME] 
      unless measure_modes.include?(opts[:measure_mode])
        raise OptionParser::InvalidOption.new("-m allows one of #{measure_modes.join(', ')}")
      end

      opts
    end

    def run
      begin
        opts = parse_options
      rescue OptionParser::InvalidArgument, OptionParser::InvalidOption => e
        usage e.message
      end

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
        RubyProf.measure_mode = eval("RubyProf::#{opts[:measure_mode]}")
        RubyProf.start
        CODE
      when 'stop'
        remote_code = <<-"CODE"
        result = RubyProf.stop
        File.open('#{opts[:output]}', 'w') {|f|
          RubyProf::#{PRINTERS[opts[:printer]]}.new(result).print(f)
        }
        CODE
      end

      $remote_engine.method_missing(:instance_eval, remote_code)

      case opts[:command]
      when 'start'
        $stdout.puts 'fluent-rubyprof: started'
      when 'stop'
        $stdout.puts "fluent-rubyprof: outputs to #{opts[:output]}"
      end
    end
  end
end

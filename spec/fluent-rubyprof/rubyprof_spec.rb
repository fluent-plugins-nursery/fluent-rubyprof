require 'json'
require 'spec_helper'
require 'fluent/rubyprof'

describe Fluent::Rubyprof do
  CONFIG_PATH = File.join(File.dirname(__FILE__), 'fluent.conf')
  BIN_DIR = File.join(ROOT, 'bin')
  OUTPUT_FILE = File.join(File.dirname(__FILE__), 'test.txt')

  context '#parse_options' do
    it 'incorrect subcommand' do
      expect { Fluent::Rubyprof.new.parse_options(['foo']) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'correct measure_mode' do
      expect { Fluent::Rubyprof.new.parse_options(['start', '-m', 'PROCESS_TIME']) }.not_to raise_error
    end

    it 'incorrect measure_mode' do
      expect { Fluent::Rubyprof.new.parse_options(['start', '-m', 'foo']) }.to raise_error(OptionParser::InvalidOption)
    end

    it 'correct printer' do
      expect { Fluent::Rubyprof.new.parse_options(['start', '-P', 'graph']) }.not_to raise_error
    end

    it 'incorrect printer' do
      expect { Fluent::Rubyprof.new.parse_options(['start', '-P', 'bar']) }.to raise_error(OptionParser::InvalidArgument)
    end
  end

  context 'profiling' do
    before :all do
      @fluentd_pid = spawn('fluentd', '-c', CONFIG_PATH, out: '/dev/null')
      sleep 2

      system("#{File.join(BIN_DIR, 'fluent-rubyprof')} start")
      sleep 2

      system("#{File.join(BIN_DIR, 'fluent-rubyprof')} stop -o #{OUTPUT_FILE}")
      sleep 1
    end

    after :all do
      Process.kill(:TERM, @fluentd_pid)
      Process.waitall
    end

    it 'should output' do
      expect(File.size?(OUTPUT_FILE)).to be_truthy
    end
  end
end

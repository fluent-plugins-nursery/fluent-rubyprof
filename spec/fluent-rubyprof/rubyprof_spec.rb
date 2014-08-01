require 'json'
require 'spec_helper'

describe 'Fluent::Rubyprof' do
  CONFIG_PATH = File.join(File.dirname(__FILE__), 'fluent.conf')
  BIN_DIR = File.join(ROOT, 'bin')
  OUTPUT_FILE = File.join(File.dirname(__FILE__), 'test.txt')

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

  it 'outputs profiling result' do
    expect(File.size?(OUTPUT_FILE)).to be_truthy
  end
end

#!/usr/bin/ruby
require "rake"
require "rake/testtask"
require "rubygems"

def self.parse(args)
    
    options = OpenStruct.new
    #options.task  = "2000"
    #options.host = "127.0.0.1"
    #options.dir = ""
    parser = OptionParser.new do |opts|
        
        opts.banner = "Usage: ./simplerake.rb [options] srake_file [task]"

            opts.on("-T","list tasks") do |task|
                options.task << task
            end

            opts.on_tail("-h","--help", "print help") do 
                puts opts
                exit
            end
        parser.parse!(args)
        options
end
task :default => [:test]  
Rake::TestTask.new do |test|  
  test.libs << "test"  
  test.test_files = Dir[ "test/test_*.rb" ]  
  test.verbose = true  
end  


def process_command(cmd)
    args = Array(cmd)
    command = args.shift
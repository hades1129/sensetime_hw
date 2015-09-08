#!/usr/bin/ruby
require "rake"
require "rake/testtask"
require "rubygems"

class srake


    def initialize()
        @command = ""
        @task = []
        @shell = {}
        @filename = ""
        @currenttask = ""
        @defaulttask =""
        @description = {}
        @sum = 0
        @tasknum = 0
        @depend = {}
    end
    def parse(args)
    
        options = OpenStruct.new
    #options.task  = "2000"
    #options.host = "127.0.0.1"
    #options.dir = ""
        parser = OptionParser.new do |opts|
        
            opts.banner = "Usage: ./simplerake.rb [options] srake_file [task]"

                opts.on("-T","list tasks") do |task|
                    options.@currenttask = task
                end

                @filename = ARGV.split[2]

                opts.on_tail("-h","--help", "print help") do 
                    puts opts
                    exit
                end
        parser.parse!(args)
        options
    end


    def parse_file()
        File.open(@filename,"r") do |aFile|
            content = aFile.gets
            while content != "" do
                if(content =~ /default(.*)/)
                    defaulttask = content.split[6].delete(:)
                end
            
                if(content =~ /desc(.*)/)
                    temp = content.split[1].gsub('\'',"")
                    content = aFile.gets
                    @description(content.split[1].delete(':')) = temp
                    taskname = content.split[1].delete(':')
                    task[tasknum++] = content.split[1].delete(':')
                    if(content =~ /=>(.*)/)
                        if(content =~ /\[(.*)/) 
                            depend[content.split[1].delete(':')] =(?<=\[)(.*?)(?=\])
                            depend[content.split[1].delete(':')].gsub(':','')
                            depend[content.split[1].delete(':')].gsub(',','')
                        else
                            depend[content.split[1].delete(':')] = content.split[3].delete(':')
                        end
                    end
                    content = aFile.gets 
                    if(content =~ /sh(.*)/)
                        @shell[taskname] = content.split[1].gsun('\'',"")
                    end
                
                end

            
            
                if(content =~ /task(.*)/)
                    task[tasknum++] = content.split[1].delete(':')
                    taskname = content.split[1].delete(':')
                    if(content =~ /=>(.*)/)
                        if(content =~ /\[(.*)/) 
                            depend[content.split[1].delete(':')] =(?<=\[)(.*?)(?=\])
                        else
                            depend[content.split[1].delete(':')] = content.split[3].delete(':')
                        end
                    end
                
                    content = aFile.gets
                    if(content =~ /sh(.*)/)
                        @shell[taskname] = content.split[1].gsun('\'',"")
                    end
                    
                end
                content = aFile.gets
            end
        aFile.close
    end

    def dispatch()
        i = 0
        if @defaulttask != ''
            if(@depend[default] != '')
                depend_execute(default)
            else 
                main_execute(default) 
            end 
        end


        loop{
            if i >= tasknum 
                break
            end

            if(depend[task[i]] != '')
                depend_execute(task[i])
            else
                main_execute(task[i])
            i++
            

        }

    end 

    def main_execute(taskname)
        if(shell[taskname] != '')
            $stdout(shell[taskname])
        if(description[taskname] != '')
            puts "        ##{taskname}\n"
    end

    def depend_execute(taskname)
        j = 0
            loop{
                if(@depend[taskname].split[j] == '')
                    break
                else
                    if (@depend[@depend[taskname].split[j]] != '')
                        decide_execute(@depend[taskname].split[j])
                        main_execute(@depend[taskname].split[j])
                    end
                end
                j++
            }


    end
end




  #(?<=\[)(.*?)(?=\])

    
options = parse(ARGV) 
rrake = srake.new
rrake.parse_file() 
rrake.dispatch()


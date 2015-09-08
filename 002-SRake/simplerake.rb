#!/usr/bin/ruby


require "optparse"
require "ostruct"
require 'pp'
require 'logger'

class SRAKE


  def initialize()
    @task = []                            
    @shell = {}           #存储sh命令的哈希表
    @filename = ""
    @templist = ARGV[0] 
    @list = false
    @defaulttest = false      
    @testtask = ""
    @defaulttask =""
    @description = {}         #存储关键字的哈希表
    @alreadytask = []
    @sum = 0
    @test = 0
    @depend = {}          #存储依赖关系的哈希表，如果对于一个task有多个依赖，一起存入
    @logger = Logger.new($stdout)
    @options = self.class.parse(ARGV) 

  end
  def self.parse(args)
    options = OpenStruct.new
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: ./simplerake.rb [options] srake_file [task]"
      opts.on("-T","list tasks") do 
        @list = true
      end
      opts.on_tail("-h","--help", "print help") do 
        puts opts
        exit
      end
    end
    parser.parse!(args)
    options
  end


  def parse_file()          #解析rake文件，根据default,desc,task,sh等关键字一行一行读入并将需要的数据存到相应数组及哈希表中
    @filename = ARGV[0]
    if @templist == "-T" then 
      @list = true
    end
    if (ARGV.size == 1)
      @defaulttest = true
    else
      @testtask = ARGV[1]
    end

    aFile = File.new("#{@filename}","r")
    content = aFile.gets
      loop do
        if content == nil then 
          break
        end
        
        if(content =~ /default(.*)/)
          @defaulttask = content.split[3].gsub!(':',"")
        
        elsif(content =~ /desc(.*)/)          
          temp = content.split[1].gsub!('\'',"")
          content = aFile.gets
          if content == nil then 
            break
          end
          @description[content.split[1].delete!(':')] = temp
          tasktempname = content.split[1].delete!(':')
          @task << content.split[1].delete!(':')
          if content =~ /=>(.*)/ then
            if(content =~ /\[(.*)/) 
              tmp = content.match(/(?<=\[)(.*?)(?=\])/)[1]
                @depend[content.split[1].delete!(':')] = tmp
                @depend[content.split[1].delete!(':')].gsub!(':','')
                @depend[content.split[1].delete!(':')].gsub!(',','')
            else
                @depend[content.split[1].delete!(':')] = content.split[3].delete!(':')
            end
          end
          content = aFile.gets 
          if content == nil then 
            break
          end
          if content =~ /sh(.*)/ then
            @shell[tasktempname] = content.match(/(?<=\')(.*?)(?=\')/)[1]
          end
        
        elsif(content =~ /task(.*)/)
          @task << content.split[1].delete!(':')
          tasktempname = content.split[1].delete!(':')
          if content =~ /=>(.*)/ then
            if(content =~ /\[(.*)/) 
              tmp = content.match(/(?<=\[)(.*?)(?=\])/)[1]
              @depend[content.split[1].delete!(':')] = tmp
              @depend[content.split[1].delete!(':')].gsub!(':','')
              @depend[content.split[1].delete!(':')].gsub!(',','')
            else
              @depend[content.split[1].delete!(':')] = content.split[3].delete!(':')
            end
          end
          content = aFile.gets
          if content == nil then 
            break
          end
          if content =~ /sh(.*)/ then
            @shell[tasktempname] = content.match(/(?<=\')(.*?)(?=\')/)[1]
          end
       
        else
          @test += 1
        end
        content = aFile.gets
        if content == nil then 
          break
        end
      end
    aFile.close
  end

  def dispatch()          # 调度函数，判断执行-T还是default还是个别实例，按优先级顺序排列
    if @list
      i = 0
      loop do
        if (@task[i] != nil)
          output_list(@task[i])
        else
          break
        end
        i += 1 
      end
      abort
    end 

    if(@defaulttest)
      if(@defaulttask != '')
        if(@depend[@defaulttask] != nil)
            depend_execute(@defaulttask)
        else 
          main_execute(@defaulttask) 
        end 
      else
        @logger.fatal("No default task.")         #没有默认的task
        abort 
      end
    abort
    end
  
    if @testtask != '' then
      if(@depend[@testtask] != nil) 
        depend_execute(@testtask)
      else
        main_execute(@testtask)
      end
    end
  end 

  def main_execute(taskname)          #执行sh命令 
    if @shell[taskname] != nil then
      system  @shell[taskname]
    end
  end
 
  def output_list(taskname)         #输出LIST
    if (@description[taskname] != nil)
      puts "#{taskname}        ##{@description[taskname]}"
    else
      puts "#{taskname}        #"
    end
  end

  def depend_execute(taskname)          #判断依赖关系，并进行相关调用及辨错
    i = 0
    loop do
      if @depend[taskname].split[i] == nil then 
        break 
      end
      if(@depend[@depend[taskname].split[i]] != nil)
        if !(@task.include? @depend[taskname].split[i])             #判断是否是rake文件里出现过的task，不是则提醒
          @logger.fatal("The prerequisite doesn't exist for task.")
          abort
        else
          depend_execute(@depend[taskname].split[i])
        end
      else
        if !(@task.include? @depend[taskname].split[i]) 
          @logger.fatal("The prerequisite doesn't exist for task.")
          abort
        end
        if !(@alreadytask.include? (@depend[taskname].split[i])) then         #判断是否已经输出过该task
          main_execute(@depend[taskname].split[i])
          @alreadytask << @depend[taskname].split[i]
        end
            
      end
      i += 1  
    end
    main_execute(taskname)
  end

end
rrake = SRAKE.new
rrake.parse_file() 
rrake.dispatch()

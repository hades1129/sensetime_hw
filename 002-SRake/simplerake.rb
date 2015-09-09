#!/usr/bin/ruby
require 'logger'
require 'optparse'
require 'ostruct'
require 'singleton'

$desc_temp= ''
$list = false 
$defaulttest = false
$testtask = ''
$filename = ''
class TASKDATA
  include Singleton
  attr_accessor :taskname, :desc, :depend, :command
  def initialize()
    @taskname = []
    @desc = {}
    @depend = {}
    @temptask = ''
    @command = {}
    @alreadytask = []
    @defaulttask = ''
    @logger = Logger.new($stdout)
  end

  def process(hash_or_symbol,&block)          #数据处理函数
    if(hash_or_symbol.is_a?(Hash))          
      if(hash_or_symbol.first[0] != "default".to_sym)         
        @taskname << hash_or_symbol.first[0]          #如果是哈希的话将Key存为taskname Value存为depend
        @temptask = hash_or_symbol.first[0]
        @depend[@temptask] = hash_or_symbol.first[1]
      else
        @defaulttask = hash_or_symbol.first[1]
      end
    else
      @taskname << hash_or_symbol
      @temptask = hash_or_symbol

    end
    if $desc_temp != '' then          #将desc对应上相应task
      @desc[@temptask] = $desc_temp
      $desc_temp = ''         
    end
    if block != nil then          #将block信息存到command中
      @command[@temptask] = block
    end

  end 
  
  def output_list(taskname)         #输出LIST
    if taskname != "default" then 
      if (@desc[taskname] != nil)
        puts "#{taskname}        ##{@desc[taskname]}"
      else
        puts "#{taskname}        #"
      end
    end
  end
  
  def depend_execute(task)          #判断依赖关系，并进行相关调用及辨错
      
    if(@depend[task].is_a?(Array))
      j = 0
      loop do
        if (@depend[task][j] == nil) then
          break
        end
        if !(@taskname.include?@depend[task][j])       #判断是否是rake文件里出现过的task，不是则提醒
          @logger.fatal("The prerequisite doesn't exist for task.")
          abort
        else
          if (@depend[@depend[task]] != nil) 
            depend_execute(@depend[task][j])
          else  
            if !(@alreadytask.include? @depend[task][j]) then
              main_execute(@depend[task][j])
              @alreadytask << @depend[task]
            end
          end
        end
        j += 1  
      end
    else
      if !(@taskname.include?@depend[task]) then       #判断是否是rake文件里出现过的task，不是则提醒
        @logger.fatal("The prerequisite doesn't exist for task.")
        abort
      end
      if (@depend[@depend[task]] != nil)
          depend_execute(@depend[task])
      else
        if !(@alreadytask.include? (@depend[task])) then         #判断是否已经输出过该task
          main_execute(@depend[task])
          @alreadytask << @depend[task]
        end
      end

    end
    main_execute(task)
  end





  
  def main_execute(taskname)          #执行sh命令 
    if @command[taskname] != nil then
      @command[taskname].call
    end
  end
  def dispatch()          # 调度函数，判断执行-T还是default还是个别实例，按优先级顺序排列
    
    if $list == true then
      i = 0
      loop do
        if (@taskname[i] != nil)
          output_list(@taskname[i])
        else
          break
        end
        i += 1 
      end
      abort
    end 

    if($defaulttest)
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
  
    if $testtask != '' then
      if(@depend[$testtask.to_sym] != nil) 
        depend_execute($testtask.to_sym)
      else
        main_execute($testtask.to_sym)
      end
    end
  end 

end

def parse(args)
  options = OpenStruct.new
  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ./simplerake.rb [options] srake_file [task]"
    opts.on("-T","list tasks") do 
      list = true
    end
    opts.on_tail("-h","--help", "print help") do 
      puts opts
      exit
    end
  end
  parser.parse!(args)
  options
end

def task(hash_or_symbol,&block)         
  TASKDATA.instance.process(hash_or_symbol,&block)          #调用TASKDATA类方法process来处理数据
end
def desc(description)
  $desc_temp = description          #设置全局变量desc_temp结局函数调用的顺序问题，确保description能准确对应上task
end

def sh(string)
  system(string)

end

if (ARGV.size == 1)
  $filename = ARGV[0]
  $defaulttest = true
else 
  if(ARGV[0] == "-T")
    $filename = ARGV[1]
    $list = true
  else
    $filename = ARGV[0] 
    $testtask = ARGV[1]
  end
end

load $filename 
options = parse(ARGV) 
TASKDATA.instance.dispatch()




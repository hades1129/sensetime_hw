#!/usr/bin/ruby
require 'socket'
require 'thread'
require 'logger'
require 'optparse'
require 'ostruct'
require 'pp'

class Ftpserver

    def initialize()
        @port = 2000
        @host = "127.0.0.1"
        @currentdir = "/Users/Hades/Documents"
        @command = ""
        @use = 0
        @connect = 0
        @logger = Logger.new($stdout)
        @isBinary = true
        @client_port = {} 
        @ok = 0

    end
    def self.parse(args)
        options = OpenStruct.new
        options.port = "2000"
        options.host = "127.0.0.1"
        options.dir = ""
        parser = OptionParser.new do |opts|
            opts.banner = "Usage: 001-ftp-server/ftp.rb [options]"

            opts.on("-p", "--port=PORT", "listen port") do |port|
                options.port = port
            end
    
            opts.on("--host=HOST", "binding address") do |host|
                options.host = host
            end
    
            opts.on("--dir=DIR", "change current directory") do |dir|
                options.dir = dir
            end

            opts.on_tail("-h","--help", "print help") do 
                puts opts
                exit
            end
        end
        parser.parse!(args)
        options
    end

    def user (con,string)
        if(string == "Hades")
            #self.use = 1
            con.puts "331 user name ok,need password.\r\n"
        else
            con.puts "430 user name error\r\n"
        end
    end

    def pass (con,string)
        if(string == "ILOVEJICONG")
            con.puts "230 successful\r\n"
            #if(self.use == 1)
             #   con.puts "230 user logged in,proceed.\r\n"
        else
                #con.puts "530 who are you\r\n"
            #end
        #else
            con.puts "430 pass word error.\r\n"
        end
    end

    def type(con,string)

        if(string == 'I')
            @isBinary = true
            con.puts "220 Type set to I(Binary)"
        else
            @isBinary = false
            con.puts "330 Type set to A(ASCII)"
        end
    end  

    def list(con,string)
        if(con!='')
            con.puts "150 Opening data connection.\r\n"
            if(@ok != 1)
                pasv(con)
                @ok = 1 
                dataclient = @client_port[con]
            else
                dataclient = @client_port[con]

            end

            # if(string.split[1]!='')
            #  dataclient.puts Dir.entries(string.split[1]).join(' ')
            
            #else
            #    dataclient.puts Dir.entries(Dir.pwd).join(' ')
            #end
            dataclient.puts(`ls -l`)
            dataclient.close
            con.puts "226 Transfer complete.\r\n"
        else
            con.puts "503 on port specify\r\n"
        end
    end
    def cwd(con,string)
        if File.directory?string
            Dir.chdir(string)
            con.puts "250 Directory changed to #{string}successfully\r\n"
        else
            con.puts "550 Directory #{string} does not exist\r\n"
        end

    end
    def pwd(con)
        con.puts "257 #{Dir.pwd} is current directory.\r\n"
    end
    def retr(con,string)
        if File::exists?(string)
            con.puts "150 Opening data connection.\r\n"
            if(@ok != 1)
                pasv(con)
                @ok = 1
                dataclient = @client_port[con]

            else
                dataclient = @client_port[con]
            end
            size = File.size?(string)
            aFile = File.new(string, "r")
            if aFile
                content = aFile.sysread(size)
                dataclient.puts content 
            else
                puts "Unable to open file!"
            end
            dataclient.close()
            con.puts "226 Transfer complete.\r\n"
        else 
            con.puts "503 no such file\r\n"

        end

    end
    def stor(con,string)

        con.puts "150 Opening data connection.\r\n"
        
        if(@ok != 1)
            pasv(con)
            @ok = 1
            dataclient = @client_port[con]

        else
            dataclient = @client_port[con]
        end      

        if @isBinary
            File.write("#{string}",dataclient.read)
        else
            aFile = File.new(string,'w')
            aFile.syswrite(dataclient.read)
        end
        dataclient.close()
        con.puts "226 Transfer complete.\r\n"
    end
    
    
    def pasv(con)
        @ok = 1  
        dataserver = TCPServer.open(0)
        temp = dataserver.addr
        dataport = temp[1]
        random1 = dataport >> 8
        random2 = dataport & 255 
        con.puts ("227 Entering Passive Mode (127,0,0,1,#{random1},#{random2}).\r\n")
        dataclient = dataserver.accept
        @client_port[con] = dataclient
    end

    


    
    def loop()

        myserver = TCPServer.open(2000)

        while 1 do
            Thread.start(myserver.accept) do |client|
                client.puts "220 welcome to Hades FTP.\r\n"
                while 1 do
                    command = client.gets
                    @logger.info "#{command.inspect}"
                    string0 = command.split[0]
                    string1 = command.split[1]
                    puts command.split[1].inspect 
                    puts command.split[0].inspect 
                    if command == ""
                        break
                    else
                        case string0
                        when "PASV"
                            pasv(client)
                        when "USER"
                            puts command.split[0].inspect 
                            user(client,string1)
                        when "PASS"
                            pass(client,string1)
                        when "PWD"
                            pwd(client)
                        when "CWD"
                            cwd(client,string1)
                        when "LIST"
                            list(client,command)
                        when "RETR"
                            retr(client,string1)
                        when "STOR"
                            stor(client,string1)
                        when "SYST"
                            client.puts "215 UNIX Type: L8"
                        when "FEAT"
                            client.puts "220 Features:\nUSER\nPASS\nPWD\nCWD\nLIST\nRETR\nSTOR\nSYST\nFEAT\nPASV\nQUIT\n221 End"
                        when "TYPE"
                             type(client,string1)  
                        when "QUIT"
                            print "client left!"
                            break
                        else
                            client.puts "500 unknow command.\r\n"
                        end
                    end

                end
                print "closing connection"
                client.close
            end
            
        end 

    end
end

options = Ftpserver.parse(ARGV)
object = Ftpserver.new
object.loop()




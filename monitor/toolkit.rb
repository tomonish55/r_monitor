#!/usr/bin/ruby
# coding: utf-8

# bundler step
require 'bundler/setup'
Bundler.require(:default)
require 'memcache'
#require 'bunny'

# this file only
require 'singleton'


## example
## ToolKit.instance.alert_mail("test", "foo")
## arg1 = subject, arg2 = body(read text file)

class ToolKit

  attr_accessor :etitle, :ebody

  def initialize(etitle,ebody)
    @etitle = etitle
    @ebody = ebody
  end

  def alert_mail

    title = etitle
    filename = ebody
    # create mail object
      mail = Mail.new do
        from  "xxxxx@gmail.com"
        to "xxxxxx@gmail.com"
        subject title
        body  File.read(filename)
    end
    # Envelope From
    mail.smtp_envelope_from = "test@hoghoge.com"
    # sendmail
    mail.deliver
  end

end

class MemCacheR

    include Singleton
    attr_accessor :x, :y, :z

    def initialize(*args)
        @x, @y, @z = args
    end

    def mem_get(*args)
       x = args[0]
       y = args[1]
       cache = MemCache.new('127.0.0.1:11211')
       cache.get(x+y)
    end

    def mem_set(*args)
      x = args[0]
      y = args[1]
      z = args[2]
      z ||= 0
      cache = MemCache.new('127.0.0.1:11211')
      cache[x+y]= z
    end

end


## example
## FileWrite.instance.f_write("#{log_file}", "testserver", "mib", "hogehoge")
## arg1 = log_file, arg2 = host, arg3  = info, arg4 = message 

class FileWrite
  include Singleton
     attr_accessor :log, :server, :gmib, :mesg

    def initialize(*args)
       @log, @server, @gmib, @mesg = args
    end

    def f_write(*args)
      @log = args[0]
      @server = args[1]
      @gmib = args[2]
      @mesg = args[3]
      time = Time.new
      file = File.open(log, "a")
      file.write("#{time}\t#{server}\t#{gmib}\t#{mesg}\n")
    end
end


## slack send message
## example
## Slack.instance.alert_scall("test")
## arg1 = message

class Slack

  include Singleton
    attr_accessor :mesg

  def initialize
      @mesg = mesg
  end

  def alert_scall(mesg)

      host = "slack.com"
      path = "/api/chat.postMessage"
      message = mesg
      # read api token with shell env 
      query_parameter = {  "token" => "#{ENV["slack_token"]}",
                            "channel" => "#alert",
                            "text" => "server_issue",
                            "username" => "hogehoge" }

      query_parameter["text"] = "#{message}"
        query = query_parameter.map do |key,value|
          "#{URI.encode(key)}=#{URI.encode(value)}"
        end.join("&")

      https = Net::HTTP.new(host, 443)
      https.use_ssl = true
      res = https.post(path, query)
  end
end

class Date
  def business_days(i)
    date = self
    i.times.each do |j|
      date -= 1
      date -= 1 while (date.wday <= 0 || date.wday >= 6) or (date.national_holid
ay?)
    end
    date
  end
end

class Gyml
   include Singleton
   attr_accessor :path, :key, :code

   def  initialize(*args)
        @path, @key, @code = path, key, code
   end

   def  get_yml(*args)
        list = YAML.load_file(args[0])
        skey = args[1]
        ylist = list["Server"][skey]
        return ylist
   end

   def  get2_yml(*args)
        list = YAML.load_file(args[0])
        skey = args[1]
        cpcode = args[2]
        ylist = list["Server"][skey][cpcode]
        return ylist
   end
end

class  Rabbitq

  include Singleton
    attr_accessor :key, :qmesg

   def  initialize(*args)
        @key, @qmesg = key, qmesg
   end

   def push_rabbit(*args)
       # create conn
       conn = Bunny.new(:host => "127.0.0.1", :user => "guest", :pass => "guest")
       conn.start
       # create channel
       ch = conn.create_channel
       # sete queue
       q  = ch.queue(args[0])
       q.publish(args[1])
       ch.close
       conn.stop
   end

   def get_rabbit(*args)
       # create conn
       kvalue = 0
       conn = Bunny.new(:host => "127.0.0.1", :user => "guest", :pass => "guest")
       conn.start
       # create channel
       ch = conn.create_channel
       # get queue
       q = ch.queue(args[0])
         q.subscribe do |delivery_info, properties, msg|       
       end
       ch.close
       conn.stop
       return kvalue
   end

end         

## example
## Threshold.instance.count_Up(value, host, target)
## arg1 = value, arg2 = hostname, args3 = target
## Threshold.instance.count_Up(1, "hogehoge@gmail.com", "load")

class Threshold

  include Singleton
  attr_accessor :value, :host, :target

  def initialize(*args)
      @value, @hots, @target = args
  end

  def count_Up(*args)
      value = args[0]
      hosts = args[1]
      target = args[2]
      case value
        when 0  then
          MemCacheR.instance.mem_set("#{hosts}","#{target}",1)
        when 1 then
          MemCacheR.instance.mem_set("#{hosts}","#{target}",2)
        when 2 then
          MemCacheR.instance.mem_set("#{hosts}","#{target}",3)
        else
          MemCacheR.instance.mem_set("#{hosts}","#{target}",0)
      end
  end

  def record_time(*args)
      value = args[0]
      hosts = args[1]
      target = args[2]
      t1 = Time.now
      case value
        when 0 then
          MemCacheR.instance.mem_set("#{hosts}","#{target}",t1.to_i)
        when 2 then
          MemCacheR.instance.mem_set("#{hosts}","#{target}",t1.to_i)
        else
          exit
      end
  end

end

#############################

# test exec
#log_file = "logs/test.log"
if __FILE__ == $PROGRAM_NAME
 Slack.instance.alert_scall("test")
end

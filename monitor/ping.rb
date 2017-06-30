#!/usr/bin/ruby
# encoding: utf-8

# bundler step
require 'bundler/setup'
Bundler.require(:default)
require 'net/ping'
require_relative 'toolkit'

# target ste

common_list = YAML.load_file('env_target.yml')
list_server = common_list["ALL"]

#=begin
# set log file

log_file = "logs/dead_or_alive.log"


# common procedure

checking = lambda  do  | targetlist ,logs|

  targetlist.each do  |target|
    begin
      address = Net::Ping::External.new(target[1])
      if address.ping? == true && MemCacheR.instance.mem_get(target[0],"dump").to_i != 0
        Slack.instance.alert_scall( target[0].to_s + "\sserver status recovery!\s"  )
        MemCacheR.instance.mem_set(target[0],"dumy",0)
      elsif address.ping? == true 
        FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "server status OK\n")
        MemCacheR.instance.mem_set(target[0],"dumy",0)
      else
        Slack.instance.alert_scall( target[0].to_s + "\sserver status issue!\s"  )
        MemCacheR.instance.mem_set(target[0],"dumy",1)
       end
  rescue => ex
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_ping\sdisconnect!" )   
      next
    end 
  end
end

# exec step
checking.call(list_server , log_file)






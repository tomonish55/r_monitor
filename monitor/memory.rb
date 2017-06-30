#!/usr/bin/ruby
# encoding: utf-8

require 'yaml'
require_relative 'toolkit'

# target ste

common_list = YAML.load_file('env_target.yml')
list_server = common_list["ALL"]

# monitor MIB set

common_oid = YAML.load_file('mib.yml')
oid_server_mem = common_oid["MEMORY"]

# low watermark   kB
lwmark = 500000

#=begin
# set log file

log_file = "logs/general.log"

# common procedure

checking = lambda  do  | targetlist, targetoid ,logs|

  targetlist.each do  |target|
    begin
      SNMP::Manager.open(:host => target[1], :Community => 'public', :timeout => 1) do |manager|
        targetoid.each do |mib|
          response = manager.get([mib[1]])
          response.each_varbind do |vb|
            if  vb.value.to_i <= lwmark.to_i
              Slack.instance.alert_scall( target[0].to_s + "\stotal memory free space little!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            elsif  vb.value.to_i  > lwmark.to_i  &&   lwmark.to_i > MemCacheR.instance.mem_get(target[0],mib[0]).to_i
              Slack.instance.alert_scall( target[0].to_s + "\stotal memory free space recovery!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            else
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "total memory free space enoguh OK\n")
        end
          end
        end
      end
  rescue => ex
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_memory\sdisconnect!" )   
      next
    end
  end
end

# exec step
checking.call(list_server ,oid_server_mem, log_file)

#!/usr/bin/ruby
# encoding: utf-8

require 'yaml'
require 'date'
require_relative 'toolkit'

# target ste

common_list = YAML.load_file('env_target.yml')
list_server = common_list["ALL"]

# monitor MIB set

common_oid = YAML.load_file('mib.yml')
oid_server_load = common_oid["LOAD"]

# low watermark
lwmark = 4
interval_time = 180

# Exclusion time and server


ex_server1 = { "test02" => "1"}
ex_start1 = '23:00'
ex_end2 = '00:00'

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
            if  (ex_start1..ex_end2).include? DateTime.now.strftime('%R') and ex_server1[target[0]] == "1"
              # exclude cron time"
              next
            elsif vb.value.to_f >= lwmark.to_f and MemCacheR.instance.mem_get(target[0],"load").to_i == 3 \
              and (( MemCacheR.instance.mem_get(target[0],"loadtime2").to_i - MemCacheR.instance.mem_get(target[0],"loadtime0").to_i ) < interval_time.to_i )
              # send alert
              Slack.instance.alert_scall( target[0].to_s + "\sOver load 4\sHigh usage 1-minute intervals!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_f)
              # init Threshold and time
              value =  MemCacheR.instance.mem_get(target[0],"load")
              Threshold.instance.count_Up(value, target[0],"load") 
            elsif vb.value.to_f >= lwmark.to_f and MemCacheR.instance.mem_get(target[0],"load").to_i <= 3
              # set counter and time of occurrence
              value =  MemCacheR.instance.mem_get(target[0],"load")
              Threshold.instance.count_Up(value, target[0],"load")
              Threshold.instance.record_time(value, target[0],"loadtime" + "#{value}")                
            elsif vb.value.to_f < lwmark.to_f and lwmark.to_f < MemCacheR.instance.mem_get(target[0],mib[0]).to_f
              # recovery step
              Slack.instance.alert_scall( target[0].to_s + "\sload recovery!\s" + mib[0] ) 
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_f)
            else
              # write log
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "load OK\n")
              # init counter up
              MemCacheR.instance.mem_set("#{target[0]}","load",0)
            end
          end
        end
      end
  rescue => ex
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_load\sdisconnect!" )   
      next
    end
  end
end

# exec step
checking.call(list_server ,oid_server_load, log_file)

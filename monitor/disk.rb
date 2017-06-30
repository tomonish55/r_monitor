#!/usr/bin/ruby
# encoding: utf-8

require 'yaml'
require_relative 'toolkit'

# target ste
common_list = YAML.load_file('env_target.yml')
# target
list_first_db = common_list["HOST"]["DB"]

# monitor MIB set
common_oid = YAML.load_file('mib.yml')
# DB
oid_db_disk = common_oid["DISK"]["DB"]

# low watermark
lwmark = 80

# set log file
log_file = "logs/disk_space.log"

# common procedure

checking = lambda  do  | targetlist, targetoid ,logs|

  targetlist.each do  |target|
    begin
      SNMP::Manager.open(:host => target[1], :Community => 'public', :timeout => 1) do |manager|
        targetoid.each do |mib|
          response = manager.get([mib[1]])
          response.each_varbind do |vb|
            if  vb.value.to_i >= lwmark
              Slack.instance.alert_scall( target[0].to_s + "\sThis Disk space will be full soon!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            elsif  vb.value.to_i  < lwmark  &&   lwmark <   MemCacheR.instance.mem_get(target[0],mib[0]).to_i
              Slack.instance.alert_scall( target[0].to_s + "\sThis server recovered disk space!\s" + mib[0] ) 
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            else
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "Disk OK\n")
        end
          end
        end
      end
  rescue => ex
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_Disk\sdisconnect!" )   
      next
    end
  end
end

# exec step
checking.call(list_first_db ,oid_db_disk, log_file)

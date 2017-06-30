#!/usr/bin/ruby
# encoding: utf-8


# bundler step
require 'bundler/setup'
Bundler.require(:default)
require 'yaml'
require_relative 'toolkit'

# target ste

common_list = YAML.load_file('env_target.yml')
list_first_db = common_list["FIRST"]["DB"]

# monitor MIB set

common_oid = YAML.load_file('mib.yml')
oid_db_pos = common_oid["POSTGRES"]["down"]
oid_db_con = common_oid["POSTGRES"]["status"]
oid_db_con2 = common_oid["POSTGRES"]["status2"]

# monitor port set
common_oid = YAML.load_file('port.yml')
oid_db_port = common_oid["TCP_Port"]["DB"]

# low watermark
lwmark = 1
lwmark_con = 90


#=begin
# set log file

log_file = "logs/postgres.log"

# common procedure

checking = lambda  do  | targetlist, targetoid ,logs|

  targetlist.each do  |target|
    begin
      SNMP::Manager.open(:host => target[1], :Community => 'public', :timeout => 1) do |manager|
        targetoid.each do |mib|
          response = manager.get([mib[1]])
          response.each_varbind do |vb|
            if vb.value[0].to_i == 0 and ( (Time.new.to_i - MemCacheR.instance.mem_get(target[0],mib[0])).to_i < 60 )
              # postgres reboot send alert step 
              Slack.instance.alert_scall( target[0].to_s + "\sPostgres reboot!\s" + mib[0] )
            elsif vb.value[0].to_i == 0 and ( (Time.new.to_i - MemCacheR.instance.mem_get(target[0],mib[0])).to_i > 60 )
              # postgres reboot within 10 hour
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "postgres_status OK, but recently this DB reboot!\n") 
            elsif  vb.value[0].to_i == 0
              #postgres reboot register time step
              register_time = Time.new  
              MemCacheR.instance.mem_set(target[0],mib[0],register_time.to_i)
            elsif vb.value[0].to_i >= lwmark
              # postgres status ok
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "postgres_status OK\n")
            else 
              # default log
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "postgres_status check!\n")                         
            end
          end
        end
      end
  rescue => ex
    # xxxxx nil can't be coerced into Fixnum disconnect! 
    # if the reboot server can't register value, once set value.
    # register_time = Time.new
    #MemCacheR.instance.mem_set(target[0],"uptime",register_time.to_i)
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_postgres_down\sdisconnect!" )   
      next
    end
  end
end


# exec step
#checking.call(list_db ,oid_db_pos, log_file)
checking.call(list_first_db ,oid_db_pos, log_file)

#  port scan

portscan = lambda do  | targetip, targetport |
  targetip.each do | target |
    targetport.each do | port |
     ping_tcp = Net::Ping::TCP.new(target[1],port[1] )
       if ping_tcp.ping? != false && MemCacheR.instance.mem_get("#{target[0]}","#{port[1]}").to_i != 0
         FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{port[1]}", "postgres access recovery!\n")
         MemCacheR.instance.mem_set("#{target[0]}","#{port[1]}",0)
       elsif ping_tcp.ping? != false
         FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{port[1]}", "postgres access OK!\n")
       else
         Slack.instance.alert_scall( target[0].to_s + "\sCan't access Postgres!\s" )
         MemCacheR.instance.mem_set("#{target[0]}","#{port[1]}",1)
       end 
    end
  end
end

# exec step
#portscan.call( list_db, oid_db_port )
portscan.call( list_first_db, oid_db_port )

## check connection

checking_con = lambda  do  | targetlist, targetoid ,logs|

  targetlist.each do  |target|
    begin
      SNMP::Manager.open(:host => target[1], :Community => 'public', :timeout => 1, :Version => :SNMPv2c) do |manager|
        targetoid.each do |mib|
          response = manager.get([mib[1]])
          response.each_varbind do |vb|
            if  vb.value[0].to_i >= lwmark_con
              Slack.instance.alert_scall( target[0].to_s + "\sThis server connection will be max soon!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            elsif  vb.value[0].to_i  < lwmark_con  &&   lwmark_con <   MemCacheR.instance.mem_get(target[0],mib[0]).to_i
              Slack.instance.alert_scall( target[0].to_s + "\sThis server recovered connection!\s" + mib[0] )
              MemCacheR.instance.mem_set(target[0],mib[0],vb.value.to_i)
            else
              FileWrite.instance.f_write("#{log_file}", "#{target[0]}", "#{mib[0]}", "Postgres connection OK\n")
            end
          end
        end
      end
  rescue => ex
    Slack.instance.alert_scall( target[0].to_s + "\s#{ex}" + "\scheck_con\sdisconnect!" )
      next
    end
  end
end

# exec step
#portscan.call( list_db, oid_db_port )
checking_con.call(list_first_db ,oid_db_con, log_file)

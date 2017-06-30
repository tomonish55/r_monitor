#!/usr/bin/ruby
# encoding: utf-8

require 'yaml'
require_relative 'toolkit'
require 'net/https'
require 'date'

# target ste
url_list = YAML.load_file('url.yml')
https_list = url_list["CERT"]["HTTPS"]

# set log file
log_file = "logs/cert_check.log"

# limit
limitdays = 30

# method

def check_cert(url, port) 
    https = Net::HTTP.new(url, port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    cert = https.start do
    https.peer_cert
    end
    limit_time = cert.not_after.to_time
    now_time = Time.now
    return  ((limit_time - now_time ) / 60 / 60 / 24).round
end


#check('admin-lap.potto.jp', 443)

checking = lambda do | targetlist, logs|
 
  targetlist.each do  |target|
    begin
      if  check_cert("#{target[1]}", 443).to_i >= limitdays
          #puts check_cert("#{target[1]}", 443).to_i 
          FileWrite.instance.f_write("#{log_file}", "#{target[1]}", "certification status OK\n")
          MemCacheR.instance.mem_set(target[1],"potto",0)
      elsif check_cert("#{target[1]}", 443).to_i <= limitdays and MemCacheR.instance.mem_get(target[1],"potto").to_i == 1
          FileWrite.instance.f_write("#{log_file}", "#{target[1]}", "certification status NG\n")
      elsif check_cert("#{target[1]}", 443).to_i <= limitdays 
          remaining_days = check_cert("#{target[1]}", 443).to_s
          Slack.instance.alert_scall( target[1].to_s + "\sThe certification deadline is going to come very soon!\s")
          Slack.instance.alert_scall( target[1].to_s + "\s#{remaining_days}" + "\sdays!" )
          MemCacheR.instance.mem_set(target[1],"potto",1)          
      else 
         remaining_days = check_cert("#{target[1]}", 443).to_s
         FileWrite.instance.f_write("#{log_file}", "#{target[1]}", "certification status NG\n")      
      end
    rescue => ex
         Slack.instance.alert_scall( target[1].to_s + "\s#{ex}" + "\s#{remaining_days}" + "\sdays!" )   
      next
    end
  end
end

# exec step
checking.call(https_list, log_file)

#!/usr/bin/ruby
# encoding: utf-8


# bundler step
require 'bundler/setup'
Bundler.require(:default)
require 'net/ping'

require 'net/https'
require_relative 'toolkit'


=begin
## URL list

common_list = YAML.load_file('url.yml')
list_url = common_list["URL"]["HTTP"]
list_port = { "HTTP" => "80" }

## logfile set

log_file = "logs/url_check.log"

# common step

$stdout = open('/dev/null', 'w')
urlscan = lambda do  | targetlist, targetport |
  targetlist.each do | target |
    targetport.each do | port |
      url = Net::Ping::HTTP.new(target[1],port[1])
        if  url.ping? != false && MemCacheR.instance.mem_get(target[0],port[0]).to_i == 1
          MemCacheR.instance.mem_set(target[0],port[0],0)
          puts "recovery"
          Slack.instance.alert_scall( target[0].to_s + "sSite\sRecovery!\s" )
        elsif  url.ping? != false
          MemCacheR.instance.mem_set(target[0],port[0],0)
          puts "#{target[1]} \t[#{port[1]}]" if url.ping?
          FileWrite.instance.f_write("#{log_file}", "#{target[1]}", "#{port[1]}", "URL OK\n")
        else
          MemCacheR.instance.mem_set(target[0],port[0],0)
          Slack.instance.alert_scall( target[0].to_s + "sSite\sDonw!!\s" )
        end
    end
  end
end


urlscan.call( list_url, list_port )
=end



https = Net::HTTP.new('8.8.8.8/utility/healthcheck.php', 443)
https.use_ssl = true
https.verify_mode = OpenSSL::SSL::VERIFY_PEER
https.request_get('/')

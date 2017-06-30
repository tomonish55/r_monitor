#!/usr/bin/ruby
# encording: utf-8

require "bundler/setup"
Bundler.require(:default)
require 'pp'
require 'yaml'
require_relative 'toolkit'

### set target host ###
common_list = YAML.load_file('env_target.yml')
list_server = common_list["ALL"]

### set check time ####
cktime = 5

send_packet =  Proc.new  do | hosts |
  packet = Net::Fping.latency(hosts, 64, 12, 100)
  packetloss =  packet[0]
end

send_packet_latency =  Proc.new  do | hosts |
  packet = Net::Fping.latency(hosts, 64, 12, 100)
  packetloss =  packet[3]
end

# set log file
log_file = "logs/packetloss.log"

### exec step ###

EM.run do

  ping = EM::PeriodicTimer.new(1) do
    list_server.each_with_index do | host |
      if send_packet.call(host[1]).to_i != 0
        packeloss = send_packet.call(host[1]).to_i
        # send alert       
        Slack.instance.alert_scall( host[0].to_s + "\spacketloss issue #{packeloss}%\s"  )
      elsif send_packet.call(host[1]).to_i == nil
        Slack.instance.alert_scall( host[0].to_s + "\sCan'not access!\s"  ) 
      else
        # write log
        packeloss = send_packet.call(host[1]).to_i 
        FileWrite.instance.f_write("#{log_file}", "#{host[0]}", "#{host[1]}", "packetloss no problem! #{packeloss}%\n")
      end
    end
  end

  EM::Timer.new(cktime) do
    FileWrite.instance.f_write("#{log_file}", "packeloss check finsihed", "no", "problem\n")
    ping.cancel
    EM.stop
  end

end

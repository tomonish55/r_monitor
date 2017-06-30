#!/usr/bin/ruby
# encoding: utf-8


# bundler step

require 'io/console'
require_relative 'toolkit'

###  check target files inclued

list = {
       "disk" => "disk.rb",
       "load" => "load.rb",
       "ping" => "ping.rb",
       "swap" => "swap.rb",
       "memory" => "memory.rb",
#       "url" => "url_check.rb",
       "postgres" => "postgres.rb",       
       "certification" => "cert_check.rb"       
       }


llist = {
        "nw" => "check_nw.rb"  
}

## logfile
log_file = "logs/start.log"

## exec host

host = system("hostname")

## start script

begin

FileWrite.instance.f_write("#{log_file}", "ruby_check_script", "#{host}", "start\n")

  check_thread = Thread.new do
    loop do
      list.each do  |x|
        system("ruby #{x[1]}")
      end
    sleep 30
    end
  end

  check_thread2 = Thread.new do
    loop do
      llist.each do  |y|
        system("ruby #{y[1]}")
      end
    sleep 300
    end
  end

  input_thread = Thread.new do
    while STDIN.getch != "q"; end
    puts
    check_thread.kill
  end

  check_thread.join
  check_thread2.join
  input_thread.join

  rescue => ex
  FileWrite.instance.f_write("#{log_file}", "ruby_check_script", "#{host}", "issue\n")
 
  ensure 
  # write stop or kill process
  FileWrite.instance.f_write("#{log_file}", "ruby_check_script", "#{host}", "stop\n") 

end



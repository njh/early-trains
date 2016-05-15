#!/usr/bin/env ruby
#
# Script to find trains that leave Denham early
# (it is really annoying)
#
# I run this script once an hour using cron
#

require 'bundler/setup'

Bundler.require(:default)

USER_AGENT = 'early-trains.rb (please give njh@aelius.com an API key)'

def to_minutes(time)
  if time.match(/(\d\d)(\d\d)(.?)/)
    mins = ($1.to_f * 60) + $2.to_f
    mins += 0.25 if $3 == '¼'
    mins += 0.5 if $3 == '½'
    mins += 0.75 if $3 == '¾'
    return mins
  end
end

date = Date.today.strftime("%Y/%m/%d")
hour = Time.now.strftime("%H").to_i
time = sprintf("%2.2d00-%2.2d01", hour-1, hour)
url = "http://www.realtimetrains.co.uk/search/advanced/DNM/#{date}/#{time}?stp=WVS&show=pax-calls&order=wtt"

response = RestClient.get(url, :user_agent => USER_AGENT)
doc = Nokogiri::HTML(response)

doc.css("tr.call_public").each do |service|
  origin,destination = service.css(".location").map {|l| l.inner_text}
  planned_arrival,planned_departure = service.css(".time").map {|l| l.inner_text}
  actual_arrival,actual_departure = service.css(".realtime").map {|l| l.inner_text}

  diff = to_minutes(actual_departure) - to_minutes(planned_departure)
  if diff <= -1.0
    puts "Train left Denham at last a minute early:"
    puts "      Route: #{origin} to #{destination}"
    puts "    Planned: #{planned_departure}"
    puts "     Actual: #{actual_departure} (#{diff.abs}min early)"
    puts
  end
end

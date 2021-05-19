#!/usr/bin/env ruby
#
# Script to find trains that leave Denham early
# (it is really annoying)
#

require 'bundler/setup'

Bundler.require(:default)

USER_AGENT = 'early-trains.rb (please give njh@aelius.com an API key)'

class Date
  def self.yesterday
    today - 1
  end
end

def to_minutes(time)
  if time.match(/(\d\d)(\d\d)(.?)/)
    mins = ($1.to_f * 60) + $2.to_f
    mins += 0.25 if $3 == '¼'
    mins += 0.5 if $3 == '½'
    mins += 0.75 if $3 == '¾'
    return mins
  end
end

date = Date.yesterday.strftime("%Y/%m/%d")
url = "http://www.realtimetrains.co.uk/search/advanced/DNM/#{date}/0400-0200?stp=WVS&show=pax-calls&order=wtt"
response = RestClient.get(url, :user_agent => USER_AGENT)
doc = Nokogiri::HTML(response)

total = 0
early = 0
doc.css(".servicelist/.service").each do |service|
  origin,destination = service.css(".location").map {|l| l.inner_text}
  planned_arrival,planned_departure = service.css(".time.plan").map {|l| l.inner_text}
  actual_arrival,actual_departure = service.css(".time.real").map {|l| l.inner_text}

  actual_mins = to_minutes(actual_departure)
  planned_mins = to_minutes(planned_departure)
  next if actual_mins.nil? or planned_mins.nil?

  diff = actual_mins - planned_mins
  if diff <= -1.0
    early += 1
    puts "Train left Denham early:"
    puts "      Route: #{origin} to #{destination}"
    puts "    Planned: #{planned_departure}"
    puts "     Actual: #{actual_departure} (#{diff.abs}min early)"
    puts
  end
  
  total += 1
end

puts

percent = sprintf("%1.1f%%", (early.to_f/total.to_f) * 100)
date = Date.yesterday.strftime("%A %e %B")
puts "On #{date}, #{early}/#{total} of @chilternrailway trains left Denham station 1 minute or more early (#{percent})"
puts
puts url

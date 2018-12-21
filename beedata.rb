#!/usr/bin/env ruby
require 'ap'
require 'sequel'
require 'date'
require 'active_support'
require 'active_support/core_ext'
require './beedata_secret'

DB = Sequel.connect('sqlite://beegraph.sqlite')


=begin
},
    [145] {
         "timestamp" => 1349539200,
             "value" => 100.0,
           "comment" => "Unfroze today",
                "id" => "50707be486f224476b00001d",
        "updated_at" => 1349549028,
         "requestid" => nil
    },
    [146] {
         "timestamp" => 1349539200,
             "value" => 100.0,
           "comment" => "initial datapoint of 100 on the 6th",
                "id" => "50707b6886f224476b000016",
        "updated_at" => 1349548904,
         "requestid" => nil
=end

# beedata(arr): arr has newest beeminder data in no particular order
# (records are usually newest first, data structured as the two above)
def beedata(arr)
  #ap arr
  ms = DB[:minutes]

  newest_date = nil
  last_value = nil

  arr.each do |d|
    m = ms.where(:id => d['id']).first
    #puts "timestamp.to_date: #{Time.at(d['timestamp']).to_date}"

    record_date = Time.at(d['updated_at']).to_date

    unless m.nil?
      # Already seen this value, not news to this process.
      #puts "found: #{m[:value]} in database with matching id"
    else
      ms.insert(:timestamp => d['timestamp'], :value => d['value'],
                :comment => d['comment'], :id => d['id'],
                :updated_at => d['updated_at'],
                :requestid => d['requestid'])

      #puts "New entry for: #{record_date}"
      if newest_date.nil? or record_date>newest_date
        newest_date = record_date
        last_value = d['value']
      end
    end

    # When data point is already in local cache, nothing to do but find
    # it, read the date updated_at, and store it if newer than any other.
    unless m.nil?
      mt = m[:updated_at]     # data from local cache
      dt = d['updated_at']    # data from beeminder

      record_date = Time.at(m[:updated_at]).to_date

      # The database has a newer date than previously seen
      if newest_date.nil? or record_date>newest_date
        newest_date = record_date
        last_value = m[:value]
      end

      # We do not expect recorded values to ever be changed
      puts "beeminder data has been modified!"    if dt > mt
      Kernel.exit(1)                              if dt > mt
    end
  end

  now_date = Time.now.to_date
  if newest_date.nil? or now_date > newest_date
    print "time to update beeminder data, "

    if now_date > Date.new(2018,12,16)
      new_value = last_value+1
    else
      new_value = last_value-1
    end
    puts "sending: #{new_value}"
    cmd = "beemind -t #{AUTH_TOKEN} 20-minutes '#{new_value}' 'from beeminute auto'"
    puts cmd.gsub(AUTH_TOKEN, "[AUTH TOKEN]")
    `#{cmd}`
  end
end


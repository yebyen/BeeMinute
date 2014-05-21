#!/usr/bin/env ruby
require 'json'
require 'ap'
require './beedata'

u = 'yebyenw'
g = '20-minutes'

url = "https://www.beeminder.com/api/v1/users/#{u}/goals/#{g}/datapoints.json"

data = IO.read('./20-minutes.json')
result = JSON.parse(data)

beedata([result[0],result[1],result[2]])


#!/usr/bin/env ruby

require_relative "../lib/satx"

v = ARGV.shift.to_i
n = ARGV.shift.to_i

p = Satx::Problem.new v
p.add_random_unique_clauses n, 2
# puts p.to_s
counts = p.variable_occurences
histogram = Hash.new{|h,k|h[k] = 0}
counts.values.each{|x| histogram[x] += 1}
expected = 2 * n / v
sum = 0
histogram.keys.sort.each do |key|
  val = histogram[key]
  sum += val * key
  puts "%5d %5d %5d %s" % [key, val, sum, expected == key ? 'mean' : '']
end
ordered_vars = counts.keys.sort{|a,b| counts[a] <=> counts[b]}
puts "most common #{ordered_vars.last} (#{counts[ordered_vars.last]})"

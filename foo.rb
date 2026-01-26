#!/bin/env ruby

(3..20).each do |np|
  n = 1 << np
  a = 5
  lits = []
  if false
    n.times do |lit|
      lits.concat [lit+1] * a * 3
    end
  else
    (3*a*n).times{ lits << rand(n) + 1}
  end

  clauses = []
  take = 0
  while !lits.empty? do
    lits.shuffle!
    cs = clauses.size
    next_lits = []
    lits.each_slice(3) do |clause|
      if clause.size == clause.union.size
        clauses << clause
      else
        next_lits.concat clause
      end
    end
    if clauses.size == cs && !next_lits.empty?
      take += 1
      take.times{ next_lits.concat clauses.pop }
    end
    lits = next_lits
  end
  #puts clauses.inspect
  #puts next_lits.inspect
  count = Hash.new{|h,k| h[k] = 0}
  clauses.flatten.each { |lit| count[lit] += 1}
  pair_count = Hash.new{|h,k| h[k] = 0}
  clauses.each do |clause|
    pair_count[[clause[0], clause[1]]] += 1
    pair_count[[clause[0], clause[2]]] += 1
    pair_count[[clause[1], clause[2]]] += 1
  end
  #puts count.inspect
  sorted = count.values.sort
  # puts sorted[-10..-1].inspect
  tgt = n
  cnt = 0
  mc = sorted[-1] + sorted[-2]
  while 0 < tgt
    cnt += 1
    tgt -= sorted.pop
  end
  puts "#{np} #{n} removed #{cnt}   #{2**(np - 5) * 1.375}"
  pcm = pair_count.values.max
  pair, pc = pair_count.find{|k, v| v == pcm}
  puts pair.inspect
  puts pair_count[pair]
  puts "#{count[pair[0]] + count[pair[1]] - pcm} vs #{mc}"
end

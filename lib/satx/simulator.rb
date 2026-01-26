module Satx
  class Simulator
    def create_uniform_sampled vars, valance, alpha
      lits = []
      if false
        vars.times do |lit|
          lits.concat [lit+1] * a * 3
        end
      else
        (valance * alpha * vars).times{ lits << rand(vars) + 1}
      end
      puts lits.inspect
      create_clauses lits
      @clauses.uniq!
      tgt = alpha * vars
      while @clauses.size < tgt
        (valance * (tgt - @clauses.size)).times{ lits << rand(vars) + 1}
        create_clauses lits
        @clauses.uniq!
      end
    end

    def create_clauses lits
      @clauses ||= []
      take = 0
      while !lits.empty? do
        lits.shuffle!
        cs = @clauses.size
        next_lits = []
        lits.each_slice(3) do |clause|
          if clause.size == clause.union.size
            @clauses << clause
          else
            next_lits.concat clause
          end
        end
        if @clauses.size == cs && !next_lits.empty?
          take += 1
          take.times { next_lits.concat @clauses.pop }
        end
        lits = next_lits
      end
    end

    def new_counter
      Hash.new{|h,k| h[k] = 0}
    end
    def init_counters
      @clause_counts = new_counter
      @pair_counts = new_counter
      @variable_counts = new_counter
      @clauses.each do |clause|
        add_counts clause
      end
    end

    def add_counts clause
      @clause_counts[clause] += 1
      @pair_counts[[clause[0], clause[1]]] += 1
      @pair_counts[[clause[0], clause[2]]] += 1 if clause[2]
      @pair_counts[[clause[1], clause[2]]] += 1 if clause[2]
      @variable_counts[clause[0]] += 1
      @variable_counts[clause[1]] += 1
      @variable_counts[clause[2]] += 1 if clause[2]
    end

    def remove_counts clause
      @clause_counts[clause] -= 1
      @pair_counts[[clause[0], clause[1]]] -= 1
      @pair_counts[[clause[0], clause[2]]] -= 1 if clause[2]
      @pair_counts[[clause[1], clause[2]]] -= 1 if clause[2]
      @variable_counts[clause[0]] -= 1
      @variable_counts[clause[1]] -= 1
      @variable_counts[clause[2]] -= 1 if clause[2]
    end

    def simulate_max_occurence
      init_counters
      iter = 0
      puts @clauses.sort.inspect
      implies = []
      trues = []
      cc = @clause_counts.values.map{|x| [x - 1, 0].max}.sum
      pc = @pair_counts.values.map{|x| [x - 1, 0].max}.sum
      puts "%5d %5d %5d %5d %5d" % [iter, cc, pc, implies.size, trues.size]
      last_size = -1
      while 1 < @clauses.size && @clauses.size != last_size
        sorted = @variable_counts.to_a.sort{|a,b| a.last <=> b.last}
        a, a_cnt = sorted.pop
        b, b_cnt = sorted.pop
        #puts "top 2: #{a} #{a_cnt}   #{b} #{b_cnt}"
        a, b = b, a if b < a
        #puts @clauses.inspect
        rewrite = {}
        @clauses.delete_if do |clause|
          idx = clause.index b
          next false if idx.nil?
          new_clause = clause.dup
          new_clause[idx] = a
          new_clause.sort!
          new_clause.uniq!
          next false if clause == new_clause
          rewrite[clause] = new_clause
          true
        end
        rewrite.each do |old, new|
          next if old == new
          remove_counts old
          if new.size == 3
            add_counts new
          elsif new.size == 2
            implies << new
          else
            trues << new
          end
        end
        iter += 1
        cc = @clause_counts.values.map{|x| [x - 1, 0].max}.sum
        pc = @pair_counts.values.map{|x| [x - 1, 0].max}.sum
        puts "%5d %5d %5d %5d %5d" % [iter, cc, pc, implies.size, trues.size]
        init_counters
        #break if @clause_counts.values.any?{|cnt| 1 < cnt }
      end
      puts @clauses.inspect
      puts @clause_counts.inspect
      puts @variable_counts.inspect
    end
  end
end

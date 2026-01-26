module Satx
  class Problem
    attr_reader :variables
    attr_reader :clauses
    attr_reader :solution

    def initialize vars, **options
      @variables = vars
      @known = options[:known]
      @solution = options[:solution]
      clear
    end

    def known?
      @known && true
    end

    def known_sat?
      @known == :sat
    end

    def known_unsat?
      @known == :unsat
    end

    def clear
      (@clauses ||= Set.new).clear
    end

    def size
      @clauses.size
    end

    def empty?
      @clauses.empty?
    end

    def _sort ary
      ary.sort{|a,b| a.abs <=> b.abs}
    end

    def add *args
      @clauses.add _sort(args.shift) while args.first.is_a? Array
      if args.first.is_a? Integer
        @clauses.add _sort(args)
      end
    end

    def add_random_unique_clauses n, k=2, prng=nil
      prng ||= Random
      finish = @clauses.size + n
      while @clauses.size < finish
        clause = Set.new
        clause.add 1 + prng.rand(@variables) while clause.size < k
        @clauses.add clause.map{|x| x * (2 * prng.rand(2) - 1)}
      end
    end

    def variable_occurences
      counts = Hash.new{|h,k| h[k] = 0}
      @clauses.each do |clause|
        clause.each{|literal| counts[literal.abs] += 1}
      end
      counts
    end

    def to_s
      s = @clauses.map(&:inspect).join(", ")
      "[#{s}]"
    end

    def brute_force_vars_rec assign, depth = 0
      #puts assign
      #puts assign.size
      if assign.size == 2 * @variables
        #puts assign
        rv = @clauses.all? do |c|
          z = !c.all?{|x| assign[x] == false }
          #puts "#{c.inspect} #{z}"
          z
        end
        #puts rv
        return assign.dup if rv
        return false
      end
      raise "depth = #{depth}" if depth > @variables
      v = assign.size / 2 + 1
      assign[v] = true
      assign[-v] = false
      rv = brute_force_vars_rec assign, depth + 1
      if rv
        assign.delete v
        assign.delete -v
        return rv
      end
      assign[v] = false
      assign[-v] = true
      rv = brute_force_vars_rec assign, depth + 1
      assign.delete v
      assign.delete -v
      rv
    end

    def brute_force_vars
      brute_force_vars_rec({})
    end

    def brute_force
      stack = []
      assign = {}
      ary = @clauses.to_a
      #puts ary.first.inspect
      ary.first.each do |literal|
        stack.push [0, literal]
      end
      while !stack.empty?
        idx, literal = stack.pop
        unless literal
          # idx is a variable that was assigned
          #puts "restore variable #{idx}"
          assign.delete idx
          assign.delete -idx
          next
        end
        # base case
        if ary.size <= idx
          #puts "FOUND #{assign}"
          raise "cain"
          return assign
        end
        clause = ary[idx]
        #puts "#{' ' * idx}#{idx} with #{literal} #{assign}"

        case assign[literal]
        when false
          next
        when true
          # do nothing
          # puts "#{' ' * idx}found true"
        when nil
          # puts "#{' ' * idx}#{literal} = true"
          assign[literal] = true
          assign[-literal] = false
          stack.push [literal, nil]
        end

        # find first clause that has at least two unknown literals
        # return false if blocked clause is found
        stack_size = stack.size
        found = []
        indent = ' ' * idx
        while true
          idx += 1
          nc = ary[idx]
          #puts "#{indent}first decision: #{nc || 'nil'} #{assign}"
          # end of the line, solution found
          return assign unless nc
          skip = false
          found.clear
          nc.each do |literal|
            case assign[literal]
            when false
              next
            when true
              found.clear
              found.push [:found, literal]
              break
            end
            found.push [idx, literal]
          end
          #puts "#{indent}first decision: found: #{found.inspect}"
          break if found.empty?
          if found.size == 1
            next if found.first.first == :found
            lit = found.first.last
            assign[lit] = true
            assign[-lit] = false
            stack.push [lit, nil]
          else
            stack.concat found
            break
          end
        end
      end
      false
    end

    def self.[] *args, **options
      vars = args.flatten.map(&:abs).max
      p = Problem.new vars, **options
      p.add *args
      p
    end

    attr_reader :failed

    def verify equivalences
      z = Hash.new
      equivalences.keys(&:abs).uniq.each do |k|
        z[k] = equivalences[k]
        z[-k] = equivalences[-k]
      end
      puts "testing: #{z}"
      @failed = []
      clauses.each do |clause|
        unless clause.inject(false) do |value, literal|
                 case equivalences[literal]
                 when Integer
                   raise "#{literal}  #{equivalences}"
                 when true
                   break true
                 end
               end
          @failed << clause
        end
      end
      puts @failed.inspect if @failed.empty?
      @failed.empty?
    end
  end
end

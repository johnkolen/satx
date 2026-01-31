module Satx
  class DCSolver
    def initialize problem
      @problem = problem
      make
    end

    def sizes
      @a.map(&:size)
    end

    def unsatisfiable?
      @unsatisfiable || false
    end

    BUILDER = [nil, nil,
               Clause2LiteralSet,
               Clause3LiteralSet]
    def make
      @a = [SearchState.new,
            SearchState.new,
            SearchState.new,
            SearchState.new]

      @cutoff = @problem.variables / 2
      @problem.clauses.each do |clause|
        cls = BUILDER[clause.size].new *clause
        grp = clause.inject(0) do |count, literal|
          literal.abs <= @cutoff ? count + 1 : count
        end
        @a[grp].add cls
      end
      @a.each_with_index do |ax, idx|
        puts "==== #{idx} ===="
        puts ax
        puts "---"
        unless ax.simplify
          @unsatisfiable = true
          return false
        end
        puts ax
        puts "==="
      end
      true
    end

    def enumerate_a3 idx, equivalences, indent=""
      begin
        current = @a3_stack[idx] || @a3_clauses.next
        unless @a3_stack[idx]
          @a3_stack[idx] = current
        end
      rescue StopIteration
        # puts "#{indent}BASE CASE *******************"
        # puts equivalences
        # raise "cain"
        @a3_solutions << equivalences
        return verify_a210_extended equivalences
      end
      #puts "#{indent}#{idx}: current #{current}"
      reduced = current.reduce equivalences
      case reduced
      when false
        return false
      when true
        return enumerate_a3 idx + 1, equivalences, "#{indent}  "
      when Equivalences
        ec = equivalences.dup
        return enumerate_a3 idx + 1, equivalences, "#{indent}  " if ec.merge! reduced
      when ClauseLiteralSet
        current.each_variable_assignment do |assignment|
          # puts "#{indent}#{idx}: assignment #{assignment}"
          ec = equivalences.dup
          ok = true
          assignment.each do |a, b|
            break unless ok &&= ec.assign(a, b)
          end
          next if !ok
          #puts "#{indent}#{idx}: ec #{ec}"
          rv = enumerate_a3 idx + 1, ec, "#{indent}  "
          return rv if rv
        end
        return false
      else
        raise "wtf? #{reduced.inspect}"
      end
    end

    def reduce_ax idx, ss
      puts "==="
      puts ss
      puts '---'
      rv = ss.merge! @a[idx]
      puts @a[idx]
      puts "after merge: #{rv}"
      puts ss
      puts "==="
      return false if rv == false
      rv = ss.simplify
      puts "after simplify: #{rv}"
      puts ss
      return false if rv == false
      return true if rv == true
      ss
    end

    def verify_a210_extended equivalences, var=1
      # puts "#{var} #{equivalences.to_assign}"
      while var <= @problem.variables && equivalences.assigned?(var)
        puts "#{var} #{equivalences.assigned?(var)} #{@problem.variables.inspect}"
        var += 1
      end
      #puts "#{var} #{equivalences.assigned?(var)}"
      if @problem.variables < var
        # puts "#{equivalences.to_assign}"
        return verify_a210 equivalences
      end
      raise "cain #{equivalences[var]}" unless equivalences[var].nil?
      equivalences.assign var, true
      rv = verify_a210_extended equivalences, var + 1
      equivalences.delete var
      equivalences.delete -var
      unless rv
        equivalences.assign var, false
        rv = verify_a210_extended equivalences, var + 1
        equivalences.delete var
        equivalences.delete -var
      end
      return rv
    end

    def verify_a210 equivalences
      ss = SearchState.new equivalences: equivalences
      puts "#{equivalences.to_assign}"
      2.downto(0).each do |x|
        #puts "reduce_a#{x}"
        ss.simplify
        rv = reduce_ax x, ss
        #puts "finished reduce_a#{x}"
        #puts ss
        #puts rv
        #return false if rv == false
        if rv == false
          #puts before
          puts ss
          puts rv
          puts "failed #{x}, on to next"
          #puts "press enter to continue"
          #STDIN.gets
          return false
        end

      end
      v = @problem.verify ss.equivalences
      if v
        puts "VERIFIED"
      else
        puts "FAILURE - NOT VERIFIED"
        puts @problem.failed.inspect
        puts ss
        return :failed
      end
      #puts "press enter to continue"
      #STDIN.gets
      return true
    end

    def solve
      return false if unsatisfiable?
      @a3_clauses = @a[3].each_clause
      @a3_stack = []
      @a3_solutions = []
      puts "*"*30, "START ENUMERATE ", "*"*30
      rv = enumerate_a3 0, Equivalences.new
      @unsatisfiable = true unless rv
      puts "enumerate returns: #{rv}"
      puts "*"*30, "END ENUMERATE ", "*"*30
      puts "a3 solutions found = #{@a3_solutions.size}"
      puts "cutoff = #{@cutoff}"
      puts "possible = #{2**@cutoff}"
      puts "overall = #{2**(2*@cutoff)}"
      rv
    end
  end
end

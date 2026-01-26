module Satx
  class Zipper
    attr_reader :sequence
    attr_reader :final

    def initialize problem
      @problem = problem
      @sequence = []
      make
    end

    def size
      @sequence.size
    end

    def empty?
      @sequence.empty?
    end

    # Trigger next in choice loop, if the choice led to contradiction
    def _make_process_next? result, choice, failed
      case result
      when Equivalences, Hash
        puts "merging #{result}"
        choice.equivalences.merge! result
      when ClauseLiteralSet
        choice.add result.dup
      when true
        # already satisfied, do nothing
      when false
        # contradiction
        puts "contradiction"
        failed << choice
        true
      end
      false
    end

    def make
      ss = SearchState.new @problem
      puts ss
      @final = false
      rv = ss.simplify
      puts "rv = #{rv}"
      puts ss
      if ss.unsatisfiable?
        @final = false
        return
      end
      while !ss.empty?
        puts "make: #{ss.hash}:\n#{ss}"
        var_counts = ss.variable_counts
        ordered_vc = var_counts.to_a.sort{|a,b| a.last <=> b.last}
        u = ordered_vc[-1].first
        v = ordered_vc[-2].first
        u, v = v, u if v < u
        choices = [SearchState.new(equivalences: ss.equivalences),
                   SearchState.new(equivalences: ss.equivalences)]
        puts "branch: #{v} = #{u}  & #{v} = #{-u}"
        choices[0].equivalences.assign v, u
        choices[1].equivalences.assign v, -u
        remainder = SearchState.new nil
        failed = []
        ss.each_clause do |clause|
          num = 0
          choices.each do |choice|
            result = clause.reduce choice.equivalences
            puts "zipper: clause: #{clause} reduce #{num += 1} ==> result: #{result}   #{choice.equivalences}"
            next if _make_process_next? result, choice, failed
          end
          while !failed.empty?
            bad = failed.pop
            puts "removing failed #{bad}"
            choices.delete_if{|c| c.equal? bad}
          end
        end
        puts "Simplifying choices"
        choices.delete_if do |choice|
          puts choice
          rv = choice.simplify
          puts "Simplify rv = #{rv.inspect}"
          rv == false
        end
        puts "===="
        puts choices[0]
        puts "----"
        puts choices[1]
        puts "===="
        if 1 < choices.size
          common = choices[0].intersection choices[1]
          puts "cccc"
          puts common.to_s
          choices[0].subtract! common
          choices[1].subtract! common
          puts "zzzz"
          puts choices[0]
          puts "-----"
          puts choices[1]
          puts "zzzz"
          ss = common
          @sequence << choices
        elsif choices.empty?
          if @sequence.empty?
            @final = false
            return false
          end
          puts @sequence.inspect
          puts ss
          raise "cain"
        else
          ss = choices.first
        end
      end
      @final = ss
    end

    def to_s
      out = ["====="]
      out << @sequence.map do |picks|
        picks.map(&:to_s).join("\n---\n")
      end.join("\n=====\n")
      out << "====="
      out << @final
      out << "^^^^"
      out.join("\n")
    end

    def search_rec search_state, idx, indent=''
      raise "search_rec: cain" unless search_state.is_a? SearchState
      return search_state if @sequence.size <= idx
      num = 0
      puts "#{indent}===== Search Rec ======"
      puts search_state.to_s(indent)
      @sequence[idx].each do |choice|
        num += 1
        puts "#{indent}----- Choice #{num} ------"
        puts choice.to_s(indent)
        current = search_state.merge choice
        puts current.to_s("#{indent}merged: ")
        return current if current == false
        result = search_rec current, idx + 1, "#{indent}  "
        return result if result
      end
      false
    end

    def solve
      return false if @final == false
      raise "solve: cain" unless @final.is_a? SearchState
      ss = search_rec @final.dup, 0
      puts "============ RESULT ========="
      puts ss
      ss.simplify
      puts ss
      ss.equivalences
    end
  end
end

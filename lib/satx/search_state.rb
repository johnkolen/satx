module Satx
  class SearchState
    attr_reader :equivalences
    attr_reader :clauses
    attr_reader :unsatisfiable

    include Noisy

    def initialize problem=nil, **options
      @problem = problem
      @clauses = [nil, nil, ClauseSet.new, ClauseSet.new]
      @equivalences = Equivalences.new

      _add_initial_clauses @problem.clauses if @problem
      _add_initial_clauses options[:clauses] if options[:clauses]
      _add_initial_equivalences options[:equivalences] if options[:equivalences]
    end

    def unsatisfiable?
      @equivalences.unsatisfiable
    end

    def _add_initial_clauses src
      src.each do |clause|
        case clause.size
        when 3
          @clauses[3].add Clause3LiteralSet.new *clause
        when 2
          @clauses[2].add Clause2LiteralSet.new *clause
        when 1
          @equivalences.assign clause.first, true
        end
      end
    end

    def _add_initial_equivalences src
      equivalences.merge! src
    end

    def size
      @clauses[3].size +
        @clauses[2].size
    end

    def empty?
      @clauses[3].empty? &&
        @clauses[2].empty?
    end

    attr_reader :var_map
    def == other
      other.is_a?(SearchState) &&
        @clauses == other.clauses &&
        @equivalences = other.equivalences
    end

    def eql? other
      @clauses == other.clauses &&
        @equivalences = other.equivalences
    end

    def hash
      @clauses.hash ^ @equivalences.hash
    end

    def add clause
      @clauses[clause.valence].add clause
      self
    end

    def add? clause
      rv = @clauses[clause.valence].add? clause
      rv ? self : rv
    end

    def addx clause
      reduced = clause.reduce @equivalences
      case reduced
      when false
        false
      when true
        self
      when ClauseLiteralSet
        add reduced
      when Equivalences
        unless @equivalences.merge! reduced
          self
        else
          false
        end
      else
        raise "unknown reduced #{reduced.inspect}"
      end
    end

    def delete clause
      @clauses[clause.valence].delete clause
    end

    def delete? clause
      rv = @clauses[clause.valence].delete? clause
      rv ? self : rv
    end

    def subtract! src
      if src.respond_to? :each_clause
        src.each_clause do |clause|
          rv = delete? clause
        end
      else
        src.each do |clause|
          rv = delete? clause
        end
      end
      if src.respond_to? :equivalences
        @equivalences.subtract! src.equivalences
      elsif src.is_a? Hash
        @equivalences.subtract! src
      end
      self
    end

    def each_clause &block
      if block_given?
        @clauses[2..-1].each do |cx|
          cx.each do |clause|
            yield clause
          end
        end
        self
      else
        Enumerator.new do |out|
        @clauses[2..-1].each do |cx|
          cx.each do |clause|
            out << clause
          end
        end
        end
      end
    end

    def inject_clauses x, &block
      @clauses[2..-1].inject(x) do |x, cx|
        cx.inject(x) do |x, cls|
          yield x, cls
        end
      end
    end

    def merge_clauses! other
      other.each_clause do |clause|
        add clause
      end
      self
    end

    def clauses_to_a
      inject_clauses([]){|ary, cls| ary << cls.to_a; ary}.flatten(1)
    end

    def intersection other
      ss = SearchState.new @problem
      max_size = [@clauses.size, other.clauses.size].max
      max_size.times do |idx|
        next if @clauses[idx].nil? || other.clauses[idx].nil?
        # puts "SearchState#intersection: clauses[#{idx}] = #{clauses[idx].inspect}"
        # puts "SearchState#intersection: clauses[#{idx}] = #{clauses[idx]}"
        # puts "SearchState#intersection: other.clauses[#{idx}] = #{other.clauses[idx].inspect}"
        # puts "SearchState#intersection: other.clauses[#{idx}] = #{other.clauses[idx]}"
        cx = @clauses[idx].intersection other.clauses[idx]
        # puts "SearchState#intersection: cx = #{cx.inspect}"
        # puts "SearchState#intersection: cx = #{cx}"
        ss.clauses[idx].merge! cx
      end
      common = @equivalences.to_a.intersection(other.equivalences.to_a).to_h
      ss.equivalences.merge! common
      ss
    end

    def _simplify_process_next? result, clause, remove, addlater
      case result
      when Equivalences, Hash
        remove << clause
        unless @equivalences.merge!(result)
          @unsatisfiable ||= []
          @unsatisfiable << clause
        end
        # puts "_simplify_process_next?: #{@equivalences}"
        true
      when true
        remove << clause
        true
      when false
        @unsatisfiable ||= []
        @unsatisfiable << clause
        true
      when ClauseLiteralSet
        if clause.equal? result
          false
        else
          remove << clause
          addlater << result
          true
        end
      when Array
        remove << clause
        result.each do |item|
          case item
          when Equivalences, Hash
            unless @equivalences.merge!(item)
              @unsatisfiable ||= []
              @unsatisfiable << clause
            end
          when ClauseLiteralSet
            addlater << item
          end
        end
        true
      else
        false
      end
    end

    def pp x
      case x
      when Array
        "[#{x.map(&:to_s).join(", ")}]"
      else
        x.to_s
      end
    end

    def simplify indent=""
      noisy { to_s(indent) }
      remove = []
      addlater = []
      # cnt = 0
      while !@unsatisfiable do
        # cnt += 1
        # break if cnt == 4
        remove.clear
        addlater.clear
        equiv_size = @equivalences.size
        each_clause do |clause|
          if 1 < clause.size
            result = clause.simplify
            noisy { "#{indent}#{clause} simplify 1 ==> #{pp result}" }
            next if _simplify_process_next? result, clause, remove, addlater
          end
          result = clause.reduce @equivalences
          noisy { "#{indent}#{clause} reduce ==> #{result}    #{@equivalences}" }
          next if _simplify_process_next? result, clause, remove, addlater
          if result != clause
            result = clause.simplify
            noisy { "#{indent}#{clause} simplify 2 ==> #{result}" }
            next if _simplify_process_next? result, clause, remove, addlater
          end
          if clause.is_a? Clause3LiteralSet
            [@clauses[2][clause.var12],
             @clauses[2][clause.var13],
             @clauses[2][clause.var23]].each do |c2|
              next if c2.nil?
              s = clause.subsumed_by c2
              next if s.equal? clause
              case s
              when true
                remove << clause
                break
              when false
                return false
              else
                remove << clause
                addlater << s
                break
              end
            end
          end
        end
        noisy { "#{indent}remove: #{pp remove}" }
        if remove.empty? && addlater.empty?
          break if @equivalences.size == equiv_size
        else
          subtract! remove
        end
        noisy { "#{indent}addlater: #{pp addlater}" }
        addlater.each{|cls| add cls}
        noisy { "#{indent}#{self}" }
      end
      if @unsatisfiable
        @equivalences.unsatisfiable = true
        false
      else
        true
      end
    end

    def variable_counts
      inject_clauses(Hash.new{|h,k| h[k] = 0}) do |vc, clause|
        clause.each_var do |var|
          vc[var] += 1
        end
        vc
      end
    end

    def to_s indent=''
      out = [
        "#{indent}clauses3:   #{@clauses[3]}",
        "#{indent}clauses2:   #{@clauses[2]}",
        "equivalences: #{@equivalences}",
        @unsastifiable ? "unsastifiable: #{@unsastifiable}" : nil
      ].compact.join("\n#{indent}")
    end

    def to_a
      @clauses[2].to_a.concat @clauses[3].to_a
    end

    def to_cls_a
      @clauses[2].to_cls_a.concat @clauses[3].to_cls_a
    end

    def merge! other
      merge_clauses! other
      puts equivalences.to_assign
      puts other.equivalences.to_assign
      result = equivalences.merge! other.equivalences
      if result
        self
      else
        false
      end
    end

    def merge other
      ss = dup
      ss.merge! other
    end

    attr_reader :failed

    def verify equivalences
      @failed = []
      unless equivalences.is_a? Equivalences
        # make sure transitive closure is in place
        equivalences = Equivalences.new equivalences
      end
      each_clause do |cls|
        cls.each do |literals|
          unless literals.inject(false) do |value, literal|
                   case equivalences[literal]
                   when Integer
                     raise "#{literal}  #{equivalences}"
                   when true
                     break true
                   end
                 end
            @failed << literals
          end
        end
      end
      @failed.empty?
    end

    def landscape_rec assign, var, lx
      #puts assign
      #puts assign.size
      var += 1 while assign.assigned?(var) && var <= @variables
      if @variables < var
        lx[assign.dup] = verify assign
        return
      end
      v = assign.size / 2 + 1
      assign.assign v, true
      landscape_rec assign, var + 1, lx
      assign.delete v
      assign.delete -v
      assign.assign v, false
      rv = landscape_rec assign, var + 1, lx
      assign.delete v
      assign.delete -v
    end

    def landscape
      lx = {}
      max_equiv_var = @equivalences.empty? ? 0 : equivalences.keys.max
      @variables = [max_equiv_var,
                    to_cls_a.map(&:max_variable).max].max
      landscape_rec @equivalences.dup, 1, lx
      lx
    end

    def landscape_diff lx_other
      lx = landscape
      rv = :same
      lx.each do |vars, value|
        if lx_other[vars] != value
          puts "#{vars.to_assign} self: #{value}  other: #{lx_other[var]}"
          rv = :diff
        end
      end
      rv
    end
  end
end

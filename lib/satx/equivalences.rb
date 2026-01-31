module Satx
  class Equivalences < Hash
    include Noisy

    attr_accessor :unsatisfiable

    alias_method :get_value, :"[]"

    def [] idx
      return nil if super(idx).nil?
      while super(idx).is_a? Integer
        idx = super(idx)
      end
      v = super(idx)
      v.nil? ? idx : v
    end

    def assigned? idx
      !get_value(idx).nil?
    end

    def self.assign **assignments
      e = new
      assignments.each do |a, b|
        rv = e.assign a, b
        return false if rv == false
      end
      e
    end

    class Contradiction < Error
      def initialize msg
        super "contradiction during assignment: #{msg}"
      end
    end

    def unsatisfiable?
      @unsatisfiable || false
    end

    def contradiction?
      @unsatisfiable
    end

    def []= idx, v
      k = self[idx]
      case k
      when Integer
        super(k, v)
      when nil
        super(idx, v)
      when true
        if v == false
          raise Contradiction.new("#{idx.inspect} = #{v.inspect} => #{inspect}")
        end
        true
      when false
        if v == true
          raise Contradiction.new("#{idx.inspect} = #{v.inspect} => #{inspect}")
        end
        false
      end
    end

    def assign a, b, indent=""
      raise Error.new("#assign first arg must be an integer") unless a.is_a? Integer
      case b
      when Integer
        noisy "#{indent}#{inspect}"
        a, b = b, a if a.abs < b.abs
        if self[a].nil?
          if a.abs < b.abs
            # maintain a => b with a.abs > b.abs
            self[b] = a
            self[-b] = -a
          elsif a.abs == b.abs
            # either identity or contraction
            return a == b
          else
            self[a] = b
            self[-a] = -b
          end
          noisy "#{indent}#{inspect}"
        else
          c = self[a]
          if c == true || c == false
            d = self[b]
            if d == true || d == false
              if c == d
                assign b, c, indent
              else
                noisy "#{indent}contradiction: #{a}=#{b} and #{inspect} "\
                      "return FALSE"
                return false
              end
            else
              return assign b, c, indent
            end
          elsif c.abs > b.abs
            return assign c, b, indent
          elsif b.abs > c.abs
            return assign b, c
          elsif b == -c
            noisy "#{indent}contradiction: #{a}=#{b} and #{inspect} "\
                  "return FALSE"
            return false
          else
            # do nothing
          end
        end
      when true, false
        if self[a] == !b ||
           self[-a] == b
          noisy "#{indent}contradiction: #{a}=#{b} and #{inspect} "\
               "return FALSE"
          return false
        end
        self[a] = b
        self[-a] = !b
      end
      true
    end

    def subtract! other
      delete_if do |k, v|
        other[k] == v
      end
    end

    def merge! other
      other.keys.map(&:abs).each do |k|
        if other[k] == other[-k]
          raise Error.new("merge!: contradiction in other #{other}")
        end
        #puts "#{self.class}#merge!: assign #{k}, #{other[k]}"
        return false unless assign k, other[k]
        #puts self
      end
      self
    end

    def to_assign
      keys.map(&:abs).union.sort.inject({}){|h, k| h[k] = self[k]; h}
    end
  end
end

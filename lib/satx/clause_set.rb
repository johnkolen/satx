module Satx
  class ClauseSet
    def initialize
      @var_map = Hash.new
    end

    def self.[] *args
      clause_set = new
      args.each do |cx|
        if cx.size == 2
          c = Clause2LiteralSet.new *cx
          clause_set.add c
        elsif cx.size == 3
          c = Clause3LiteralSet.new *cx
          clause_set.add c
        end
      end
      clause_set
    end

    attr_reader :var_map
    def == other
      @var_map == other.var_map
    end

    def eql? other
      @var_map == other.var_map
    end

    def hash
      @var_map.hash
    end

    def sets_size
      @var_map.size
    end

    def size
      @var_map.values.map(&:size).sum
    end

    def empty?
      @var_map.empty?
    end

    def [] key
      @var_map[key]
    end

    def clear
      @var_map.clear
    end

    def each &block
      @var_map.values.each do |cx|
        yield cx
      end
    end

    def inject x, &block
      @var_map.values.inject(x) do |x, cx|
        yield x, cx
      end
    end

    def clauses
      @var_map.values
    end

    def to_a
      inject([]) do |ary, cls|
        cls.each do |clause|
          ary << clause
        end
        ary
      end
    end

    def to_cls_a
      inject([]) do |ary, cls|
        ary << cls
      end
    end

    def intersection other
      cs = ClauseSet.new
      # puts "#{self.class}#intersection: #{clauses.inspect}"
      # puts "#{self.class}#intersection: #{to_a.inspect}"
      # puts "#{self.class}#intersection: #{other.clauses.inspect}"
      # puts "#{self.class}#intersection: #{other.to_a.inspect}"
      clauses.intersection(other.clauses).each do |clause|
        cs.add clause
      end
      cs
    end

    def add clause
      v = clause.vars
      if @var_map.key? v
        @var_map[v].union! clause
      else
        @var_map[v] = clause
      end
    end

    def delete clause
      @var_map.delete clause.vars
      self
    end

    def delete? clause
      # puts "ClauseSet#delete?: #{clause.inspect}"
      # puts "ClauseSet#delete?: #{@var_map.inspect}"
      rv = @var_map.delete clause.vars
      # puts "ClauseSet#delete?: rv = #{rv.inspect}"
      rv ? self : rv
    end

    def merge! src
      src.each do |clause|
        add clause
      end
      self
    end

    def reduce! equivs
      remove = []
      each do |clause_set|
        rv = clause_set.reduce equivs
        next if rv.equal? clause_set
        remove << clause_set.vars
        case rv
        when Hash
          equivs.merge! rv
        when false
          return false
        end
      end
      remove.each do |idx|
        @var_map.delete idx
      end
      reduce! equivs unless remove.empty?
      equivs
    end

    def simplify!
      equivs = Equivalences.new
      remove = []
      each do |clause_set|
        rv = clause_set.simplify
        next if rv.equal? clause_set
        remove << clause_set.vars
        case rv
        when Hash
          equivs.merge! rv
        when false
          return false
        end
      end
      remove.each do |idx|
        @var_map.delete idx
      end
      reduce! equivs unless remove.empty?
      equivs
    end

    def to_s
      s = @var_map.values.map(&:to_s).join(", ")
      "[#{s}]"
    end
  end
end

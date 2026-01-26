module Satx
  class Clause2LiteralSet < ClauseLiteralSet
    SET_SHIFT = VARIABLE_BITS * 2
    SET_MASK = 2**4 - 1

    def initialize a, b
      raise Error.new("same variable: #{a} and #{b}") if a.abs == b.abs
      a, b = b, a if b.abs < a.abs
      s = (a < 0 ? 2 : 0) + (b < 0 ? 1 : 0)
      @r = (1 << (SET_SHIFT + s)) |
           ((a.abs & VARIABLE_MASK) << VARIABLE_BITS) |
           (b.abs & VARIABLE_MASK)
    end

    def self.[] *args
      cx = args.map do |ary|
        if ary.size != 2
          raise Error.new("must have 2 literals: #{args.last}")
        end
        new *ary
      end
      cx.inject(cx.pop){|u, cls| u.union! cls }
    end

    attr_reader :r
    def == other
      return false unless other.is_a? Clause2LiteralSet
      @r == other.r
    end

    def eql? other
      @r == other.r
    end

    def hash
      @r
    end

    # number of variable slots
    def valence
      2
    end

    def size
      sv = set_vector
      (sv & 1) + ((sv & 0b10) >> 1) + ((sv & 0b100) >> 2) + ((sv & 0b1000) >> 3)
    end

    def set_vector
      (@r >> SET_SHIFT) & SET_MASK
    end

    SET_CLEAR = (VARIABLE_MASK << VARIABLE_BITS) | VARIABLE_MASK
    def set_vector= value
      @r = (@r & SET_CLEAR) | (value & SET_MASK) << SET_SHIFT
      self
    end

    def vars
      @r & SET_CLEAR
    end

    def var1
      (@r >> VARIABLE_BITS) & VARIABLE_MASK
    end

    STRSIZE = 4 + 2 * VARIABLE_BITS
    def bitstring v
      ("%#{STRSIZE}s" % v.to_s(2)).gsub(' ', '0')
    end

    VAR1_CLEAR = (SET_MASK << SET_SHIFT) | VARIABLE_MASK
    def var1= value
      @r = (@r & VAR1_CLEAR) | (value & VARIABLE_MASK) << VARIABLE_BITS
      self
    end

    def var2
      @r & VARIABLE_MASK
    end

    VAR2_CLEAR = (SET_MASK << SET_SHIFT) | (VARIABLE_MASK << VARIABLE_BITS)
    def var2= value
      @r = (@r & VAR2_CLEAR) | (value & VARIABLE_MASK)
      self
    end

    def each_var &block
      yield var1
      yield var2
    end

    def each &block
      s = (@r >> SET_SHIFT) & SET_MASK
      i = 0
      while s > 0 do
        if s & 1 == 1
          lit1 = (i & 2).zero? ? var1 : -var1
          lit2 = (i & 1).zero? ? var2 : -var2
          yield [lit1, lit2]
        end
        s >>= 1
        i += 1
      end
    end

    def inject x, &block
      each do |clause|
        yield x, clause
      end
      x
    end

    def to_a
      inject([]) do |ary, clause|
        ary << clause
      end
    end

    def covers
      sv = set_vector
      ((sv & 0b0001) << 3 ^ SET_MASK) &
      ((sv & 0b0010) << 1 ^ SET_MASK) &
      ((sv & 0b0100) >> 1 ^ SET_MASK) &
      ((sv & 0b1000) >> 3 ^ SET_MASK)
    end

    def to_s
      s = (@r >> SET_SHIFT) & SET_MASK
      out = []
      4.times do |i|
        if s & 1 == 1
          lit1 = (i & 2).zero? ? var1 : -var1
          lit2 = (i & 1).zero? ? var2 : -var2
          out << "[#{lit1}, #{lit2}]"
        end
        s >>= 1
      end
      out.join(", ")
    end

    def union! *others
      others.each do |other|
        raise Error.new("bad union") unless var1 == other.var1 && var2 == other.var2
        @r |= (other.set_vector & SET_MASK) << SET_SHIFT
      end
      self
    end

    VAR1_POS = 0b0011
    VAR1_NEG = 0b1100
    VAR2_POS = 0b0101
    VAR2_NEG = 0b1010
    def each_variable_assignment &block
      res = []
      sv = set_vector
      # puts cv.to_s(2)
      res << {var1 => true} if 0 < sv & VAR1_POS
      res << {var1 => false} if 0 < sv & VAR1_NEG
      res << {var2 => true} if 0 < sv & VAR2_POS
      res << {var2 => false} if 0 < sv & VAR2_NEG
      if block_given?
        res.each{|a| yield a}
      else
        res
      end
    end

    SX = [
      true,     # 0000
      nil,      # 0001  [A,B]
      nil,      # 0010  [A,-B]
      0b0000,   # 0011  [A,B]&[A,-B] -> A=true
      nil,      # 0100  [-A,B]
      0b0010,   # 0101  [-A,B]&[A,B] -> B=true
      0b0001,   # 0110  [-A,B]&[A,-B] -> A=B
      0b1001,   # 0111  [-A,B]&[A,-B]&[A,B] -> A=true,B=true
      nil,      # 1000  [-A,-B]
      0b0101,   # 1001  [-A,-B]&[A,B] -> A!=B
      0b0110,   # 1010  [-A,-B]&[A,-B] -> B!=true
      0b1011,   # 1011  [-A,-B]&[A,-B]&[A,B] -> A=true,B!=true
      0b0100,   # 1100  [-A,-B]&[-A,B] -> A!=true
      0b1101,   # 1101  [-A,-B]&[-A,B]&[A,B] -> A!=true,B=true
      0b1111,   # 1110  [-A,-B]&[-A,B]&[A,-B] -> A!=true,B!=true
      false     # 1111
    ]

    def simplify
      #puts "sv = #{set_vector.to_s(2)}"
      sx = SX[set_vector]
      #puts "sx = #{sx.is_a?(Integer) ? sx.to_s(2) : sx.inspect}"
      # puts self.to_s
      return self if sx.nil?
      return sx if sx == true || sx == false
      if sx < 0b0111
        # only one variable is set
        # puts "sx simple"
        if sx & 0b10 == 0
          # puts "sx A"
          if sx & 1 == 1
            # puts "sx EQ"
            rv = (sx & 0b100).zero? ? var1 : -var1
            equiv var2, rv
          else
            # puts "sx TF  #{var1}"
            tv = (sx & 0b100).zero?
            equiv var1, tv
          end
        else
          # puts "sx B"
          tv = (sx & 0b100).zero?
          equiv var2, tv
        end
      else
        # two variables are set
        rv1 = (sx & 0b100).zero?
        rv2 = (sx & 0b10).zero?
        ec = equiv var1, rv1
        ec.assign var2, rv2
        ec
      end
    end

    def _exchange_ab
      @r ^= (0b0110 << SET_SHIFT)
    end

    EXCH = [0, 8, 4, nil, 2, nil, 6, nil, 1, 9]
    PAIR_EXCH = [0, 2, 1, 3]

    def _assign **vars
      vars.inject(Equivalences.new) do |ec, (u,v)|
        return false unless ec.assign u, v
        ec
      end
    end

    def _reduce_bools ec_var1, ec_var2
      sv = set_vector
      # puts "sv = #{sv.to_s(2)}"
      # remove pp and pn because var1 is true
      sv &= 0b1100 if ec_var1 == true
      # remove np and nn because var1 is false
      sv &= 0b0011 if ec_var1 == false
      # remove pp and np because var2 is true
      sv &= 0b1010 if ec_var2 == true
      # remove pn and nn because var2 is false
      sv &= 0b0101 if ec_var2 == false
      # puts "sv after = #{sv.to_s(2)}"
      return true if sv == 0
      if ec_var2.is_a? Integer
        if ec_var1 == true
          return _assign(ec_var2=>true) if sv & 0b0100 > 0
          return _assign(-ec_var2=>true) if sv & 0b1000 > 0
        else
          return _assign(ec_var2=>true) if sv & 0b0001 > 0
          return _assign(-ec_var2=>true) if sv & 0b0010 > 0
        end
      elsif ec_var1.is_a? Integer
        if ec_var2 == true
          return _assign(ec_var1=>true) if sv & 0b0010 > 0
          return _assign(-ec_var1=>true) if sv & 0b1000 > 0
        else
          return _assign(ec_var1=>true) if sv & 0b0001 > 0
          return _assign(-ec_var1=>true) if sv & 0b0100 > 0
        end
      elsif ec_var1 == true
        return sv & 0b0111 > 0 if ec_var2 == true
        return sv & 0b1011 > 0 # if ec_var2 == false
      elsif ec_var1 == false
        return sv & 0b1101 > 0 if ec_var2 == true
        return sv & 0b1110 > 0 # if ec_var2 == false
      else
        raise "cain sv = #{sv.to_s(2)}"
      end
      raise Error.new("wtf?  #{ec_var1} #{ec_var2} : #{self}  #{equivalences}")
    end

     #     cx = Clause2LiteralSet.new -6, -7
     #     expect(cx.reduce(Equivalences[{7=>-4, -7=>4}]).to_a).to eq [[4, -6]]
    def _reduce_ints ec_var1, ec_var2
      if ec_var1.abs == ec_var2.abs
        if ec_var1 == ec_var2
          # puts "reduce: ec equal"
          # a==b  ~a|~b, ~a|b,  a|~b,  a|b
          # b=>a  ~a|~a, ~a|a,  a|~a,  a|a
          #         ~a     t     t      a
          z = set_vector & 0b1001
          return false if z == 0b1001
          return _assign(-var1 => true) if z & 0b1000 > 0
          return _assign(var1 => true) if z & 0b0001 > 0
          return true
        else
          # a!=b   ~a|~b, ~a|b,   a|~b,  a|b
          # b=>~a  ~a|a,  ~a|~a,  a|a,   a|~a
          #          t     ~a      a      t
          z = set_vector & 0b0110
          # puts "sv=#{set_vector.to_s(2)}"
          # puts "z=#{z.to_s(2)}"
          return false if z == 0b0110
          return _assign(-var1 => true) if z & 0b0100 > 0
          return _assign(var1 => true) if z & 0b0010 > 0
          return true
        end
      else
        rv = dup
        lit1 = ec_var1 || var1
        lit2 = ec_var2 || var2
        # puts "var1: #{ec_var1}  var2: #{ec_var2}"
        # puts "lit1: #{lit1}  lit2: #{lit2}"
        rv.var1 = lit1.abs
        rv.var2 = lit2.abs
        #        nn np pn pp
        #neg 1   pn pp nn np  rotate right 2
        #neg 2   np nn pp pn  exch 32, exch 10
        #neg 12  pp pn np nn  reverse
        #exch    nn pn np pp
        if lit1 < 0
          if lit2 < 0
            # reverse
            sv = set_vector
            outer = sv & 0b1001  # 0->0, 1->8, 8->1, 9->9
            inner = sv & 0b0110  # 0->0, 2->4, 4->2, 6->6
            rv.set_vector = EXCH[outer] | EXCH[inner]
          else
            # rotate right 2
            sv = set_vector
            rv.set_vector = ((0b0011 & sv) << 2) | (sv >> 2)
          end
        else
          if lit2 < 0
            # exch 32, exch 10
            sv = set_vector
            rv.set_vector = (PAIR_EXCH[sv >> 2] << 2) | PAIR_EXCH[sv & 0b0011]
          end
        end
        if rv.var2 < rv.var1
          sv = rv.set_vector
          rv.var1, rv.var2 = rv.var2, rv.var1
          rv.set_vector = (PAIR_EXCH[(sv & 0b0110) >> 1] << 1) | sv & 0b1001
        end
        rv
      end
    end

    def reduce equivalences
      return false if set_vector == 0b1111
      s = simplify
      case s
      when Hash
        return Equivalences[s].merge!(equivalences)
      when true
        return !equivalences.contradiction?
      when false
        return false
      end
      # puts "#reduce: #{equivalences.inspect}"
      unless equivalences.is_a? Equivalences
        raise Error.new("equivalences is not an Equivalences")
      end
      ec_var1 = equivalences[var1]
      ec_var2 = equivalences[var2]
      return self if ec_var1.nil? && ec_var2.nil?
      ec_var1 = var1 if ec_var1.nil?
      ec_var2 = var2 if ec_var2.nil?
      # puts "ec_var1: #{ec_var1}  ec_var2: #{ec_var2}"
      if ec_var1.is_a?(Integer) && ec_var2.is_a?(Integer)
        _reduce_ints ec_var1, ec_var2
      else
        _reduce_bools ec_var1, ec_var2
      end
    end
  end
end

#  NXE
#  000 A=true
#  010 B=true
#  001 A=B
#  101 A!=B
#  110 B!=true
#  100 A!=true
# 1001 A=true,B=true
# 1011 A=true,B!=true
# 1101 A!=true,B=true
# 1111 A!=true,B!=true

module Satx
  class Clause3LiteralSet < ClauseLiteralSet
    SET_SHIFT = VARIABLE_BITS * 3
    SET_MASK = 2**8 - 1

    include Noisy

    def initialize a, b, c
      raise Error.new("same variable: #{a} and #{b}") if a.abs == b.abs
      raise Error.new("same variable: #{a} and #{c}") if a.abs == c.abs
      raise Error.new("same variable: #{b} and #{c}") if b.abs == c.abs
      #puts "before #{a} #{b} #{c}"
      c, b = b, c if c.abs < b.abs
      a, b = b, a if b.abs < a.abs
      c, b = b, c if c.abs < b.abs
      #puts "after  #{a} #{b} #{c}"
      s = (a < 0 ? 4 : 0) + (b < 0 ? 2 : 0) + (c < 0 ? 1 : 0)
      #puts "s = #{s}"
      @r = (1 << (SET_SHIFT + s)) |
           ((a.abs & VARIABLE_MASK) << 2 * VARIABLE_BITS) |
           ((b.abs & VARIABLE_MASK) << VARIABLE_BITS) |
           (c.abs & VARIABLE_MASK)
    end

    def self.[] *args
      cx = args.map do |ary|
        if ary.size != 3
          raise Error.new("must have 3 literals: #{args.last}")
        end
        new *ary
      end
      cx.inject(cx.pop){|u, cls| u.union! cls }
    end

    attr_reader :r
    def == other
      return false unless other.is_a? Clause3LiteralSet
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
      3
    end

    def size
      sv = set_vector
      (sv & 1) +
        ((sv >> 1) & 1) +
        ((sv >> 2) & 1) +
        ((sv >> 3) & 1) +
        ((sv >> 4) & 1) +
        ((sv >> 5) & 1) +
        ((sv >> 6) & 1) +
        ((sv >> 7) & 1)
    end

    def set_vector
      (@r >> SET_SHIFT) & SET_MASK
    end

    def set_vectors
      result = []
      current = 0b0000001
      sv = set_vector
      while current <= sv
        result << current if 0 < (sv & current)
        current <<= 1
      end
      result
    end

    SET_CLEAR = (VARIABLE_MASK << 2 * VARIABLE_BITS) |
                (VARIABLE_MASK << VARIABLE_BITS) |
                VARIABLE_MASK
    def set_vector= value
      @r = (@r & SET_CLEAR) | (value & SET_MASK) << SET_SHIFT
      self
    end

    def vars
      @r & SET_CLEAR
    end

    def var1
      (@r >> 2 * VARIABLE_BITS) & VARIABLE_MASK
    end

    STRSIZE = 8 + 3 * VARIABLE_BITS
    def bitstring v
      ("%#{STRSIZE}s" % v.to_s(2)).gsub(' ', '0')
    end

    VAR1_CLEAR = (SET_MASK << SET_SHIFT) |
                 VARIABLE_MASK << VARIABLE_BITS |
                 VARIABLE_MASK
    def var1= value
      @r = (@r & VAR1_CLEAR) | (value & VARIABLE_MASK) << 2 * VARIABLE_BITS
      self
    end

    def var2
      (@r >> VARIABLE_BITS) & VARIABLE_MASK
    end

    VAR2_CLEAR = (SET_MASK << SET_SHIFT) |
                 (VARIABLE_MASK << 2 * VARIABLE_BITS) |
                 VARIABLE_MASK
    def var2= value
      @r = (@r & VAR2_CLEAR) | (value & VARIABLE_MASK) << VARIABLE_BITS
      self
    end

    def var3
      @r & VARIABLE_MASK
    end

    VAR3_CLEAR = (SET_MASK << SET_SHIFT) |
                 (VARIABLE_MASK << 2 * VARIABLE_BITS) |
                 (VARIABLE_MASK << VARIABLE_BITS)
    def var3= value
      @r = (@r & VAR3_CLEAR) | (value & VARIABLE_MASK)
      self
    end

    # copy vars 1 and 2 to lower bits (as if CLS2)
    def var12
      (var1 << VARIABLE_BITS) | var2
    end
    # copy vars 1 and 2 to lower bits (as if CLS2)
    def var13
      (var1 << VARIABLE_BITS) | var3
    end
    # copy vars 1 and 2 to lower bits (as if CLS2)
    def var23
      (var2 << VARIABLE_BITS) | var3
    end

    def each_var &block
      yield var1
      yield var2
      yield var3
    end

    def each &block
      s = (@r >> SET_SHIFT) & SET_MASK
      i = 0
      while s > 0 do
        if s & 1 == 1
          lit1 = (i & 4).zero? ? var1 : -var1
          lit2 = (i & 2).zero? ? var2 : -var2
          lit3 = (i & 1).zero? ? var3 : -var3
          yield [lit1, lit2, lit3]
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

    def map &block
      res = []
      inject([]) do |result, clause|
        result << yield(clause)
      end
    end

    def to_a
      inject([]) do |ary, clause|
        ary << clause
      end
    end
    #     nnnnpppp  nnnnpppp
    #     nnppnnpp  nnppnnpp
    #     npnpnpnp  npnpnpnp
    # ppp 00000001  01111111
    # ppn 00000010  10111111
    # pnp 00000100  11011111
    # pnn 00001000  11101111
    # npp 00010000  11110111
    # npn 00100000  11111011
    # nnp 01000000  11111101
    # nnn 10000000  11111110
    def covers
      sv = set_vector
      ((sv & 0b00000001) << 7 ^ SET_MASK) &
      ((sv & 0b00000010) << 5 ^ SET_MASK) &
      ((sv & 0b00000100) << 3 ^ SET_MASK) &
      ((sv & 0b00001000) << 1 ^ SET_MASK) &
      ((sv & 0b00010000) >> 1 ^ SET_MASK) &
      ((sv & 0b00100000) >> 3 ^ SET_MASK) &
      ((sv & 0b01000000) >> 5 ^ SET_MASK) &
      ((sv & 0b10000000) >> 7 ^ SET_MASK)
    end

    def to_s
      s = (@r >> SET_SHIFT) & SET_MASK
      out = []
      8.times do |i|
        if s & 1 == 1
          lit1 = (i & 4).zero? ? var1 : -var1
          lit2 = (i & 2).zero? ? var2 : -var2
          lit3 = (i & 1).zero? ? var3 : -var3
          out << "[#{lit1}, #{lit2}, #{lit3}]"
        end
        s >>= 1
      end
      out.join(", ")
    end

    def union! *others
      others.each do |other|
        raise Error.new("bad union") unless var1 == other.var1 &&
                                            var2 == other.var2 &&
                                            var3 == other.var3
        @r |= (other.set_vector & SET_MASK) << SET_SHIFT
      end
      self
    end

    def each_variable_assignment &block
      res = []
      cv = set_vector
      # puts cv.to_s(2)
      res << {var1 => true} if 0 < cv & VAR1_POS
      res << {var1 => false} if 0 < cv & VAR1_NEG
      res << {var2 => true} if 0 < cv & VAR2_POS
      res << {var2 => false} if 0 < cv & VAR2_NEG
      res << {var3 => true} if 0 < cv & VAR3_POS
      res << {var3 => false} if 0 < cv & VAR3_NEG
      if block_given?
        res.each{|a| yield a}
      else
        res
      end
    end

    SIMPLIFY = {
      0 => true,
      1 => nil,  # [1, 2, 3]
      2 => nil,  # [1, 2, -3]
      3 => [[1, 2]],
      4 => nil,  # [1, -2, 3]
      5 => [[1, 3]],
      6 => nil,  # [1, 2, -3], [1, -2, 3]
      7 => [[1, 2], [1, 3]],
      8 => nil,  # [1, -2, -3]
      9 => nil,  # [1, 2, 3], [1, -2, -3]
      10 => [[1, -3]],
      11 => [[1, 2], [1, -3]],
      12 => [[1, -2]],
      13 => [[1, -2], [1, 3]],
      14 => [[1, -2], [1, -3]],
      15 => [[1]],
      16 => nil,  # [-1, 2, 3]
      17 => [[2, 3]],
      18 => nil,  # [1, 2, -3], [-1, 2, 3]
      19 => [[1, 2], [2, 3]],
      20 => nil,  # [1, -2, 3], [-1, 2, 3]
      21 => [[1, 3], [2, 3]],
      22 => nil,  # [1, 2, -3], [1, -2, 3], [-1, 2, 3]
      23 => [[1, 2], [1, 3], [2, 3]],
      24 => nil,  # [1, -2, -3], [-1, 2, 3]
      25 => [[2, 3], [1, -2, -3]],
      26 => [[1, -3], [-1, 2, 3]],
      27 => [[1, -3], [2, 3]],
      28 => [[1, -2], [-1, 2, 3]],
      29 => [[1, -2], [2, 3]],
      30 => [[1, -2], [1, -3], [-1, 2, 3]],
      31 => [[1], [2, 3]],
      32 => nil,  # [-1, 2, -3]
      33 => nil,  # [1, 2, 3], [-1, 2, -3]
      34 => [[2, -3]],
      35 => [[1, 2], [2, -3]],
      36 => nil,  # [1, -2, 3], [-1, 2, -3]
      37 => [[1, 3], [-1, 2, -3]],
      38 => [[2, -3], [1, -2, 3]],
      39 => [[1, 3], [2, -3]],
      40 => nil,  # [1, -2, -3], [-1, 2, -3]
      41 => nil,  # [1, 2, 3], [1, -2, -3], [-1, 2, -3]
      42 => [[1, -3], [2, -3]],
      43 => [[1, 2], [1, -3], [2, -3]],
      44 => [[1, -2], [-1, 2, -3]],
      45 => [[1, -2], [1, 3], [-1, 2, -3]],
      46 => [[1, -2], [2, -3]],
      47 => [[1], [2, -3]],
      48 => [[-1, 2]],
      49 => [[-1, 2], [2, 3]],
      50 => [[-1, 2], [2, -3]],
      51 => [[2]],
      52 => [[-1, 2], [1, -2, 3]],
      53 => [[-1, 2], [1, 3]],
      54 => [[-1, 2], [2, -3], [1, -2, 3]],
      55 => [[2], [1, 3]],
      56 => [[-1, 2], [1, -2, -3]],
      57 => [[-1, 2], [2, 3], [1, -2, -3]],
      58 => [[-1, 2], [1, -3]],
      59 => [[2], [1, -3]],
      60 => [{2 => 1}],
      61 => [[1, 3], {2 => 1}],
      62 => [[1, -3], {2 => 1}],
      63 => [[1], [2]],
      64 => nil,  # [-1, -2, 3]
      65 => nil,  # [1, 2, 3], [-1, -2, 3]
      66 => nil,  # [1, 2, -3], [-1, -2, 3]
      67 => [[1, 2], [-1, -2, 3]],
      68 => [[-2, 3]],
      69 => [[1, 3], [-2, 3]],
      70 => [[-2, 3], [1, 2, -3]],
      71 => [[1, 2], [-2, 3]],
      72 => nil,  # [1, -2, -3], [-1, -2, 3]
      73 => nil,  # [1, 2, 3], [1, -2, -3], [-1, -2, 3]
      74 => [[1, -3], [-1, -2, 3]],
      75 => [[1, 2], [1, -3], [-1, -2, 3]],
      76 => [[1, -2], [-2, 3]],
      77 => [[1, -2], [1, 3], [-2, 3]],
      78 => [[1, -3], [-2, 3]],
      79 => [[1], [-2, 3]],
      80 => [[-1, 3]],
      81 => [[-1, 3], [2, 3]],
      82 => [[-1, 3], [1, 2, -3]],
      83 => [[1, 2], [-1, 3]],
      84 => [[-1, 3], [-2, 3]],
      85 => [[3]],
      86 => [[-1, 3], [-2, 3], [1, 2, -3]],
      87 => [[3], [1, 2]],
      88 => [[-1, 3], [1, -2, -3]],
      89 => [[-1, 3], [2, 3], [1, -2, -3]],
      90 => [{3 => 1}],
      91 => [[1, 2], {3 => 1}],
      92 => [[1, -2], [-1, 3]],
      93 => [[3], [1, -2]],
      94 => [[1, -2], {3 => 1}],
      95 => [[1], [3]],
      96 => nil,  # [-1, 2, -3], [-1, -2, 3]
      97 => nil,  # [1, 2, 3], [-1, 2, -3], [-1, -2, 3]
      98 => [[2, -3], [-1, -2, 3]],
      99 => [[1, 2], [2, -3], [-1, -2, 3]],
      100 => [[-2, 3], [-1, 2, -3]],
      101 => [[1, 3], [-2, 3], [-1, 2, -3]],
      102 => [{3 => 2}],
      103 => [[1, 2], {3 => 2}],
      104 => nil,  # [1, -2, -3], [-1, 2, -3], [-1, -2, 3]
      105 => nil,  # [1, 2, 3], [1, -2, -3], [-1, 2, -3], [-1, -2, 3]
      106 => [[1, -3], [2, -3], [-1, -2, 3]],
      107 => [[1, 2], [1, -3], [2, -3], [-1, -2, 3]],
      108 => [[1, -2], [-2, 3], [-1, 2, -3]],
      109 => [[1, -2], [1, 3], [-2, 3], [-1, 2, -3]],
      110 => [[1, -2], {3 => 2}],
      111 => [[1], {3 => 2}],
      112 => [[-1, 2], [-1, 3]],
      113 => [[-1, 2], [-1, 3], [2, 3]],
      114 => [[-1, 3], [2, -3]],
      115 => [[2], [-1, 3]],
      116 => [[-1, 2], [-2, 3]],
      117 => [[3], [-1, 2]],
      118 => [[-1, 2], {3 => 2}],
      119 => [[2], [3]],
      120 => [[-1, 2], [-1, 3], [1, -2, -3]],
      121 => [[-1, 2], [-1, 3], [2, 3], [1, -2, -3]],
      122 => [[-1, 2], {3 => 1}],
      123 => [[2], {3 => 1}],
      124 => [[-1, 3], {2 => 1}],
      125 => [[3], {2 => 1}],
      126 => [{2 => 1}, {3 => 1}],
      127 => [[1], [2], [3]],
      128 => nil,  # [-1, -2, -3]
      129 => nil,  # [1, 2, 3], [-1, -2, -3]
      130 => nil,  # [1, 2, -3], [-1, -2, -3]
      131 => [[1, 2], [-1, -2, -3]],
      132 => nil,  # [1, -2, 3], [-1, -2, -3]
      133 => [[1, 3], [-1, -2, -3]],
      134 => nil,  # [1, 2, -3], [1, -2, 3], [-1, -2, -3]
      135 => [[1, 2], [1, 3], [-1, -2, -3]],
      136 => [[-2, -3]],
      137 => [[-2, -3], [1, 2, 3]],
      138 => [[1, -3], [-2, -3]],
      139 => [[1, 2], [-2, -3]],
      140 => [[1, -2], [-2, -3]],
      141 => [[1, 3], [-2, -3]],
      142 => [[1, -2], [1, -3], [-2, -3]],
      143 => [[1], [-2, -3]],
      144 => nil,  # [-1, 2, 3], [-1, -2, -3]
      145 => [[2, 3], [-1, -2, -3]],
      146 => nil,  # [1, 2, -3], [-1, 2, 3], [-1, -2, -3]
      147 => [[1, 2], [2, 3], [-1, -2, -3]],
      148 => nil,  # [1, -2, 3], [-1, 2, 3], [-1, -2, -3]
      149 => [[1, 3], [2, 3], [-1, -2, -3]],
      150 => nil,  # [1, 2, -3], [1, -2, 3], [-1, 2, 3], [-1, -2, -3]
      151 => [[1, 2], [1, 3], [2, 3], [-1, -2, -3]],
      152 => [[-2, -3], [-1, 2, 3]],
      153 => [{-3 => 2}],
      154 => [[1, -3], [-2, -3], [-1, 2, 3]],
      155 => [[1, 2], {-3 => 2}],
      156 => [[1, -2], [-2, -3], [-1, 2, 3]],
      157 => [[1, -2], {-3 => 2}],
      158 => [[1, -2], [1, -3], [-2, -3], [-1, 2, 3]],
      159 => [[1], {-3 => 2}],
      160 => [[-1, -3]],
      161 => [[-1, -3], [1, 2, 3]],
      162 => [[-1, -3], [2, -3]],
      163 => [[1, 2], [-1, -3]],
      164 => [[-1, -3], [1, -2, 3]],
      165 => [{-3 => 1}],
      166 => [[-1, -3], [2, -3], [1, -2, 3]],
      167 => [[1, 2], {-3 => 1}],
      168 => [[-1, -3], [-2, -3]],
      169 => [[-1, -3], [-2, -3], [1, 2, 3]],
      170 => [[-3]],
      171 => [[-3], [1, 2]],
      172 => [[1, -2], [-1, -3]],
      173 => [[1, -2], {-3 => 1}],
      174 => [[-3], [1, -2]],
      175 => [[1], [-3]],
      176 => [[-1, 2], [-1, -3]],
      177 => [[-1, -3], [2, 3]],
      178 => [[-1, 2], [-1, -3], [2, -3]],
      179 => [[2], [-1, -3]],
      180 => [[-1, 2], [-1, -3], [1, -2, 3]],
      181 => [[-1, 2], {-3 => 1}],
      182 => [[-1, 2], [-1, -3], [2, -3], [1, -2, 3]],
      183 => [[2], {-3 => 1}],
      184 => [[-1, 2], [-2, -3]],
      185 => [[-1, 2], {-3 => 2}],
      186 => [[-3], [-1, 2]],
      187 => [[2], [-3]],
      188 => [[-1, -3], {2 => 1}],
      189 => [{2 => 1}, {-3 => 1}],
      190 => [[-3], {2 => 1}],
      191 => [[1], [2], [-3]],
      192 => [[-1, -2]],
      193 => [[-1, -2], [1, 2, 3]],
      194 => [[-1, -2], [1, 2, -3]],
      195 => [{-2 => 1}],
      196 => [[-1, -2], [-2, 3]],
      197 => [[-1, -2], [1, 3]],
      198 => [[-1, -2], [-2, 3], [1, 2, -3]],
      199 => [[1, 3], {-2 => 1}],
      200 => [[-1, -2], [-2, -3]],
      201 => [[-1, -2], [-2, -3], [1, 2, 3]],
      202 => [[-1, -2], [1, -3]],
      203 => [[1, -3], {-2 => 1}],
      204 => [[-2]],
      205 => [[-2], [1, 3]],
      206 => [[-2], [1, -3]],
      207 => [[1], [-2]],
      208 => [[-1, -2], [-1, 3]],
      209 => [[-1, -2], [2, 3]],
      210 => [[-1, -2], [-1, 3], [1, 2, -3]],
      211 => [[-1, 3], {-2 => 1}],
      212 => [[-1, -2], [-1, 3], [-2, 3]],
      213 => [[3], [-1, -2]],
      214 => [[-1, -2], [-1, 3], [-2, 3], [1, 2, -3]],
      215 => [[3], {-2 => 1}],
      216 => [[-1, 3], [-2, -3]],
      217 => [[-1, -2], {-3 => 2}],
      218 => [[-1, -2], {3 => 1}],
      219 => [{-2 => 1}, {3 => 1}],
      220 => [[-2], [-1, 3]],
      221 => [[-2], [3]],
      222 => [[-2], {3 => 1}],
      223 => [[1], [-2], [3]],
      224 => [[-1, -2], [-1, -3]],
      225 => [[-1, -2], [-1, -3], [1, 2, 3]],
      226 => [[-1, -2], [2, -3]],
      227 => [[-1, -3], {-2 => 1}],
      228 => [[-1, -3], [-2, 3]],
      229 => [[-1, -2], {-3 => 1}],
      230 => [[-1, -2], {3 => 2}],
      231 => [{-2 => 1}, {-3 => 1}],
      232 => [[-1, -2], [-1, -3], [-2, -3]],
      233 => [[-1, -2], [-1, -3], [-2, -3], [1, 2, 3]],
      234 => [[-3], [-1, -2]],
      235 => [[-3], {-2 => 1}],
      236 => [[-2], [-1, -3]],
      237 => [[-2], {-3 => 1}],
      238 => [[-2], [-3]],
      239 => [[1], [-2], [-3]],
      240 => [[-1]],
      241 => [[-1], [2, 3]],
      242 => [[-1], [2, -3]],
      243 => [[-1], [2]],
      244 => [[-1], [-2, 3]],
      245 => [[-1], [3]],
      246 => [[-1], {3 => 2}],
      247 => [[-1], [2], [3]],
      248 => [[-1], [-2, -3]],
      249 => [[-1], {-3 => 2}],
      250 => [[-1], [-3]],
      251 => [[-1], [2], [-3]],
      252 => [[-1], [-2]],
      253 => [[-1], [-2], [3]],
      254 => [[-1], [-2], [-3]],
      255 => false,
    }
    def binary a, b
      Clause2LiteralSet.new a, b
    end

    def simplify
      sx = SIMPLIFY[set_vector]
      return self if sx.nil?
      return sx if sx == true || sx == false
      lit_array = [nil, var1, var2, var3, -var3, -var2, -var1]
      results = sx.map do |result|
        case result
        when Array
          if result.size == 2
            binary lit_array[result[0]], lit_array[result[1]]
          elsif result.size == 1
            equiv lit_array[result.first], true
          elsif result.size == 3
            self.class.new lit_array[result[0]],
                           lit_array[result[1]],
                           lit_array[result[2]]
          else
            raise "wtf? array #{result.inspect} on #{set_vector}"
          end
        when Hash
          ec =
          result.inject(Equivalences.new) do |ec, (a, b)|
            ec.assign lit_array[a], lit_array[b]
            ec
          end
        when false
          false
        else
          raise "wtf? #{result.inspect}"
        end
      end
      self.class.unify results
    end

    def _exchange_ab
      @r ^= (0b0110 << SET_SHIFT)
    end

    EXCH = [0, 8, 4, nil, 2, nil, 6, nil, 1, 9]
    PAIR_EXCH = [0, 2, 1, 3]

    def _assign **vars
      neg = {}
      vars.each do |u,v|
        if v.is_a? Integer
          neg[-u] = -v
        else
          neg[-u] = !v
        end
      end
      vars.merge neg
    end


    def _reverse_bits x
      ((x & 0b00000001) << 7) |
      ((x & 0b00000010) << 5) |
      ((x & 0b00000100) << 3) |
      ((x & 0b00001000) << 1) |
      ((x & 0b00010000) >> 1) |
      ((x & 0b00100000) >> 3) |
      ((x & 0b01000000) >> 5) |
        ((x & 0b10000000) >> 7)
    end

    def _exchange_bits x, a, b
      a_mask = 0b00000001 << a
      b_mask = 0b00000001 << b
      a_bit = (x & a_mask) >> a
      b_bit = (x & b_mask) >> b
      nb = (a_bit << b) | (b_bit << a)
      (x & ~a_mask & ~b_mask) | nb
    end

    #     nnnnpppp  nnnnpppp
    #     nnppnnpp  nnppnnpp
    #     npnpnpnp  npnpnpnp
    # ppp 00000001  01111111
    # ppn 00000010  10111111
    # pnp 00000100  11011111
    # pnn 00001000  11101111
    # npp 00010000  11110111
    # npn 00100000  11111011
    # nnp 01000000  11111101
    # nnn 10000000  11111110
    def equiv a, b
      ec = Equivalences.new
      raise "wtf?" unless ec.assign a, b
      ec
    end

    def _reduce_ints ec_var1, ec_var2, ec_var3, indent=''
      res = []
      sv = set_vector
      if ec_var1.abs == ec_var2.abs && ec_var1.abs == ec_var3.abs
        # all vars equal is true for everything except ppp and nnn, which
        # assign to true or false
        noisy { "#{indent}all equal" }
        noisy { "#{indent}#{sv.to_s(2)}" }
        res << equiv(ec_var1, true) if sv & 0b00000001 > 0
        res << equiv(ec_var1, false) if sv & 0b10000000 > 0
        noisy { "#{indent}#{res.inspect}" }
        return sv & 0b01111110 > 0 if res.empty?
        return self.class.unify res
      end
      if ec_var1.abs == ec_var2.abs
        # nnx and ppx reduce to ux
        # others are true
        res << Clause2LiteralSet.new( ec_var1,  ec_var3) if sv & 0b00000001 > 0
        res << Clause2LiteralSet.new( ec_var1, -ec_var3) if sv & 0b00000010 > 0
        res << Clause2LiteralSet.new(-ec_var1,  ec_var3) if sv & 0b01000000 > 0
        res << Clause2LiteralSet.new(-ec_var1, -ec_var3) if sv & 0b10000000 > 0
        return sv & 0b00111100 > 0 if res.empty?
        return self.class.unify res
      end
      if ec_var1.abs == ec_var3.abs
        # nxn and pxp reduce to ux
        # others are true
        res << Clause2LiteralSet.new( ec_var2,  ec_var3) if sv & 0b00000001 > 0
        res << Clause2LiteralSet.new( ec_var2, -ec_var3) if sv & 0b00000100 > 0
        res << Clause2LiteralSet.new(-ec_var2,  ec_var3) if sv & 0b00100000 > 0
        res << Clause2LiteralSet.new(-ec_var2, -ec_var3) if sv & 0b10000000 > 0
        return sv & 0b01011010 > 0 if res.empty?
        return self.class.unify res
      end
      if ec_var2.abs == ec_var3.abs
        # xnn and xpp reduce to ux
        # others are true
        res << Clause2LiteralSet.new( ec_var1,  ec_var2) if sv & 0b00000001 > 0
        res << Clause2LiteralSet.new( ec_var1, -ec_var2) if sv & 0b00001000 > 0
        res << Clause2LiteralSet.new(-ec_var1,  ec_var2) if sv & 0b00010000 > 0
        res << Clause2LiteralSet.new(-ec_var1, -ec_var2) if sv & 0b10000000 > 0
        return sv & 0b01100110 > 0 if res.empty?
        return self.class.unify res
      end
      noisy { "#{indent}shuffling" }
      # We are left with shuffling the vars around
      rv = dup
      lit1 = ec_var1 || var1
      lit2 = ec_var2 || var2
      lit3 = ec_var3 || var3
      # puts "var1: #{ec_var1}  var2: #{ec_var2}"
      # puts "lit1: #{lit1}  lit2: #{lit2}"
      rv.var1 = lit1.abs
      rv.var2 = lit2.abs
      rv.var3 = lit3.abs
      noisy { "#{indent}shuffling: #{rv}" }
      #        nnn nnp npn npp pnn pnp ppn ppp
      #neg 1   pnn pnp ppn ppp nnn nnp npn npp  rotate 4 left
      #neg 2   npn npp nnn nnp ppn ppp pnn pnp  exch 76,54; 32,10
      #neg 3   nnp nnn npp npn pnp pnn ppp ppn  exch 7,6; 5,4; 3,2; 1,0
      #neg 12  ppn ppp pnn pnp npn npp nnn nnp  exch 76,10;;54,32
      #neg 13  pnp pnn ppp ppn nnp nnn npp npn  exch 7,2;6,3;5,0;4,1
      #neg 23  npp npn nnp nnn ppp ppn pnp pnn  exch 7,4; 3, 0
      #neg 123 ppp ppn pnp pnn npp npn nnp nnn  reverse

      sv = set_vector
      if lit1 < 0
        if lit2 < 0
          if lit3 < 0
            # reverse
            noisy { "#{indent}reverse" }
            outer = sv & 0b1001  # 0->0, 1->8, 8->1, 9->9
            inner = sv & 0b0110  # 0->0, 2->4, 4->2, 6->6
            rv.set_vector = _reverse_bits sv
          else
            # exch 7,4; 3, 0
            noisy { "#{indent}exch 7,4; 3, 0" }
            rv.set_vector = _exchange_bits(_exchange_bits(sv, 7, 4), 3, 0)
          end
        else
          if lit3 < 0
            # exch 7,2;6,3;5,0;4,1
            noisy { "#{indent}exch 7,2;6,3;5,0;4,1" }
            rv.set_vector =
              _exchange_bits(_exchange_bits(_exchange_bits(_exchange_bits(sv,
                                                                      7, 2),
                                                        6, 3),
                                          5, 0),
                            4, 1)
          else
            # rotate 4 left
            noisy { "#{indent}rotate 4 left" }
            rv.set_vector = ((sv & VAR1_POS) << 4) | ((sv & VAR1_NEG) >> 4)
          end
        end
      else
        if lit2 < 0
          if lit3 < 0
            # exch 7,4; 3, 0
            noisy { "#{indent}exch 7,4; 3, 0" }
            rv.set_vector =
              _exchange_bits(_exchange_bits(sv, 7, 4), 3, 0)
          else
            # exch 76,54; 32,10
            noisy { "#{indent}exch 76,54; 32,10" }
            rv.set_vector =
              _exchange_bits(_exchange_bits(_exchange_bits(_exchange_bits(sv, 7, 5),
                                                        6, 4),
                                          3, 1),
                            2, 0)
          end
        else
          if lit3 < 0
            #exch 7,6; 5,4; 3,2; 1,0
            noisy { "#{indent}exch 7,6; 5,4; 3,2; 1,0" }
            rv.set_vector =
              _exchange_bits(_exchange_bits(_exchange_bits(_exchange_bits(sv, 7, 6),
                                                        5, 4),
                                          3, 2),
                            1, 0)
          else
            noisy { "#{indent}no rotation" }
          end
        end
        noisy { "#{indent}shuffling x: #{rv}" }
      end

      noisy { "#{indent}shuffling: #{rv.set_vector}" }
      #        nnn nnp npn npp pnn pnp ppn ppp
      #exch 12 nnn nnp pnn pnp npn npp ppn ppp exch 5,3; 4, 2
      #exch 23 nnn npn nnp npp pnn ppn pnp ppp exch 6,5; 2,1
      #exch 13 nnn pnn npn ppn nnp pnp npp ppp exch 6,3; 4,1;
      if rv.var2 < rv.var1
        noisy { "#{indent}exchanging var 1 with var 2" }
        sv = rv.set_vector
        rv.var1, rv.var2 = rv.var2, rv.var1
        rv.set_vector = _exchange_bits(_exchange_bits(sv, 5, 3), 4, 2)
      end
      if rv.var3 < rv.var1
        noisy { "#{indent}exchanging var 1 with var 3" }
        sv = rv.set_vector
        rv.var1, rv.var3 = rv.var3, rv.var1
        rv.set_vector = _exchange_bits(_exchange_bits(sv, 6, 3), 4, 1)
      end
      if rv.var3 < rv.var2
        noisy { "#{indent}exchanging var 2 with var 3" }
        sv = rv.set_vector
        rv.var2, rv.var3 = rv.var3, rv.var2
        noisy { "#{indent}#{"%8s" % sv.to_s(2)}" }
        rv.set_vector = _exchange_bits(_exchange_bits(sv, 6, 5), 2, 1)
        noisy { "#{indent}#{"%8s" % rv.set_vector.to_s(2)}" }
      end
      noisy { "#{indent}rv = #{rv}" }
      rv
    end

    VAR1_POS = 0b00001111
    VAR1_NEG = 0b11110000
    VAR2_POS = 0b00110011
    VAR2_NEG = 0b11001100
    VAR3_POS = 0b01010101
    VAR3_NEG = 0b10101010

    VAR_EQ_12  = 0b11000011
    VAR_NEQ_12 = 0b00111100
    VAR_EQ_13  = 0b10100101
    VAR_NEQ_13 = 0b01011010
    VAR_EQ_23  = 0b10011001
    VAR_NEQ_23 = 0b01100110

    def _reduce_bools ec_var1, ec_var2, ec_var3
      sv = set_vector
      noisy { "#{indent}sv 0: %8s" % sv.to_s(2) }
      # puts "sv = #{sv.to_s(2)}"
      #       nnnnpppp var 1
      #       nnppnnpp var 2
      #       npnpnpnp var 3
        # sv &= 0b11110000 if ec_var1 == true
      if ec_var1 == true
        # remove ppp, ppn, pnp, and pnn because var1 is true
        sv &= VAR1_NEG
      elsif ec_var1 == false
        # remove npp, npn, nnp, and nnn because var1 is false
        sv &= VAR1_POS
      elsif ec_var2.is_a?(Integer)
        if ec_var1 == ec_var2
          # remove pnp, pnn, npp, and npn
          # because var1 == var2 [a, -a, x] is true
          sv &= VAR_NEQ_12
        elsif ec_var1 == -ec_var2
          # remove ppp, ppn, nnp, and nnn
          # because var1 == var2 [a, -a, x] is true
          sv &= VAR_EQ_12
        end
      elsif ec_var3.is_a?(Integer)
        if ec_var1 == ec_var3
          # remove pnp, pnn, npp, and npn
          # because var1 == var2 [a, -a, x] is true
          sv &= VAR_NEQ_13
        elsif ec_var1 == -ec_var3
          sv &= VAR_EQ_13
        end
      end
      noisy { "#{indent}sv 1: %8s" % sv.to_s(2) }

      if ec_var2 == true
        # remove ppp, ppn, pnp, and pnn because var1 is true
        sv &= VAR2_NEG
      elsif ec_var2 == false
        # remove npp, npn, nnp, and nnn because var1 is false
        sv &= VAR2_POS
      elsif ec_var3.is_a?(Integer)
        if ec_var2 == ec_var3
          # remove pnp, pnn, npp, and npn
          # because var1 == var2 [a, -a, x] is true
          sv &= VAR_NEQ_23
        elsif ec_var2 == -ec_var3
          # remove ppp, ppn, nnp, and nnn
          # because var1 == var2 [a, -a, x] is true
          sv &= VAR_EQ_23
        end
      end
      noisy { "#{indent}sv 2: %8s" % sv.to_s(2) }

      if ec_var3 == true
        # remove ppp, ppn, pnp, and pnn because var1 is true
        sv &= VAR3_NEG
      elsif ec_var3 == false
        # remove npp, npn, nnp, and nnn because var1 is false
        sv &= VAR3_POS
      end
      noisy { "#{indent}sv 3: %8s" % sv.to_s(2) }

      return true if sv == 0
      return false if sv > 0 &&
                      !ec_var1.is_a?(Integer) &&
                      !ec_var2.is_a?(Integer) &&
                      !ec_var3.is_a?(Integer)
      if ec_var3.is_a? Integer
        # test for xyn and xyp: aabbccdd
        #sv = set_vector
        noisy { "#{indent}sv var3: %8s" % sv.to_s(2) }
        x = dup
        x.set_vector = sv
        noisy { "#{indent}  remaining clauses: #{x}" }
        if ec_var2.is_a? Integer
          raise "ec_var1 should be boolean #{ec_var1}" if ec_var1.is_a? Integer
          clauses = x.inject(ClauseSet.new) do |cs, literals|
            # literals.delete_at 0
            next cs if 0 < literals[0] && ec_var1 == true
            next cs if literals[0] < 0 && ec_var1 == false
            cs.add binary literals[1], literals[2]
          end
          noisy { "#{indent}#{clauses}" }
          ec = clauses.simplify!
          noisy { "#{indent}#{clauses}" }
          noisy { "#{indent}#{ec}" }
          if clauses.empty? || ec == false
            return ec
          else
            if ec.empty?
              return self.class.unify(clauses.to_cls_a)
            else
              return self.class.unify(clauses.to_cls_a.push ec)
            end
          end
        end
        # both var1 and var2 are boolean
        noisy { "#{indent}both var1 and var2 are boolean" }
        # return false if 0 < (sv & ((sv & 0b10101010) >> 1))
        rv = Equivalences[_assign(ec_var3 => 0 < (sv & VAR3_POS))]
        if ec_var1.is_a? Integer
          rv.assign(var1, 0 < (sv & VAR1_NEG))
        else
          rv.assign(var1, ec_var1)
        end
        #rv.assign(-var1, 0 < (sv & VAR1_POS)) if ec_var1.is_a? Integer
        if ec_var2.is_a? Integer
          rv.assign(var2, 0 < (sv & VAR2_NEG))
        else
          rv.assign(var2, ec_var2)
        end
        # rv.assign(-var2, 0 < (sv & VAR2_POS)) if ec_var2.is_a? Integer
        noisy { "#{indent}#{rv}" }
        return rv
      elsif ec_var2.is_a? Integer
        noisy { "#{indent}sv var2: %8s" % sv.to_s(2) }
        x = dup
        x.set_vector = sv
        noisy { "#{indent}  remaining clauses: #{x}" }
        if ec_var1.is_a? Integer
          raise "ec_var3 should be boolean #{ec_var3}" if ec_var3.is_a? Integer
          clauses = x.inject(ClauseSet.new) do |cs, literals|
            next cs if 0 < literals[2] && ec_var3 == true
            next cs if literals[2] < 0 && ec_var3 == false
            cs.add binary literals[0], literals[1]
          end
          noisy { "#{indent}#{clauses}" }
          ec = clauses.simplify!
          noisy { "#{indent}#{clauses}" }
          noisy { "#{indent}#{ec}" }
          if clauses.empty? || ec == false
            return ec
          else
            if ec.empty?
              return self.class.unify(clauses.to_cls_a)
            else
              return self.class.unify(clauses.to_cls_a.push ec)
            end
          end
        end
        # both var1 and var3 are boolean
        noisy { "#{indent}both var1 and var3 are boolean" }
        #sv = set_vector
        noisy { "#{indent}sv var2: %8s" % sv.to_s(2) }
        # return false if 0 < (sv & ((sv & 0b10101010) >> 1))
        noisy { "#{indent}#{(sv & VAR2_POS).to_s(2)}" }
        rv = Equivalences[_assign(ec_var2 => 0 < (sv & VAR2_POS))]
        rv.assign( var1, 0 < (sv & VAR1_NEG)) if ec_var1 == true
        rv.assign(-var1, 0 < (sv & VAR1_POS)) if ec_var1 == false
        rv.assign( var3, 0 < (sv & VAR3_NEG)) if ec_var3 == true
        rv.assign(-var3, 0 < (sv & VAR3_POS)) if ec_var3 == false
        noisy { "#{indent}#{rv}" }
        return rv
      elsif ec_var1.is_a? Integer
        rv = Equivalences[_assign(ec_var1 => 0 < (sv & VAR1_POS))]
        rv.assign( var1, 0 < (sv & VAR2_NEG)) if ec_var2 == true
        rv.assign(-var1, 0 < (sv & VAR2_POS)) if ec_var2 == false
        rv.assign( var3, 0 < (sv & VAR3_NEG)) if ec_var3 == true
        rv.assign(-var3, 0 < (sv & VAR3_POS)) if ec_var3 == false
        return rv
      elsif ec_var1 == true
        raise "wtf: reduce bools TODO sv = #{sv.to_s(2)} was #{set_vector}"
        return sv & 0b0111 > 0 if ec_var2 == true
        return sv & 0b1011 > 0 # if ec_var2 == false
      elsif ec_var1 == false
        raise "wtf: reduce bools TODO sv = #{sv.to_s(2)} was #{set_vector}"
        return sv & 0b1101 > 0 if ec_var2 == true
        return sv & 0b1110 > 0 # if ec_var2 == false
      else
        raise "cain sv = #{sv.to_s(2)}"
      end
      raise Error.new("wtf?  #{ec_var1} #{ec_var2} : #{self}  #{equivalences}")
    end

    def self.unify ary
      ec = nil
      clsh = Hash.new
      ary.each do |elem|
        # puts "examine #{elem}"
        if elem.is_a? Hash
          if ec
            ec.merge! elem
            # puts "merged #{elem} -> #{ec}"
          else
            ec = Equivalences[elem]
            # puts "added #{elem} -> #{ec}"
          end
        elsif elem.is_a? ClauseLiteralSet
          # puts "found #{elem}"
          cls = clsh[elem.vars]
          if cls
            cls.union! elem
            # puts "merged #{cls}"
          else
            clsh[elem.vars] = elem.dup
            # puts "added #{clsh[elem]}"
          end
        else
          raise "unexpected #{elem.inspect}"
        end
      end
      if ec.nil?
        if clsh.size == 1
          return clsh.values.first
        else
          return clsh.values
        end
      else
        rv = clsh.values
        if rv.empty?
          ec
        else
          rv.push ec
          rv
        end
      end
    end

    def _reduce_merge a, b, *ec_vars
      if ec_vars.last.is_a? String
        indent = ec_vars.pop
      else
        indent = ''
      end
      noisy { "#{indent}_reduce_merge: #{a} #{b} #{ec_vars}" }
      a -= 1
      b -= 1
      x = 0
      x += 1 while x== a || x == b
      xtv = ec_vars[x].is_a?(Integer) ? nil : ec_vars[x]
      noisy { "#{indent}_reduce_merge: xtv = #{xtv} x=#{x}" }
      remains = inject(Set.new) do |list, c|
        #puts "---"
        #puts c.inspect
        if 0 < c[x]
          next if xtv == true
        else
          next if xtv == false
        end
        c[a] = (c[a] <=> 0) * ec_vars[a]
        c[b] = (c[b] <=> 0) * ec_vars[b]
        if xtv.nil?
          c[x] = (c[x] <=> 0) * ec_vars[x]
        else
          next if 0 < c[x] && xtv == true
          next if c[x] < 0 && xtv == false
          c[x] = 0 < c[x] ? xtv : !xtv
        end
        next if xtv.nil? && (c[a] == -c[x] || c[b] == -c[x])
        noisy { "#{indent}#{c.inspect}" }
        noisy { "#{indent}#{c[a]} #{c[b]}" }
        if c[a] == c[b]
          del = [b]
          if c[x] == false
            del << x
          elsif 0 < c[x]
            del << x if xtv == false
          else
            del << x if xtv == true
          end
          if xtv.nil?
            del << x if c[a] == c[x] || c[b] == c[x]
          end
          del.sort.reverse.each{|idx| c.delete_at idx}
          noisy { "#{indent}#{c.inspect} added" }
          list.add c
        else  # [a, -a] is true, skip
          list
        end
      end
      noisy { "#{indent}_reduce_merge: #{remains.inspect}" }
      if remains.empty?
        true
      else
        e = nil
        clauses = remains.inject(Hash.new) do |h, literals|
          case literals.size
          when 3
            raise "3 size"
          when 2
            cls = Clause2LiteralSet.new *literals
            v = h[cls.vars]
            if v
              v.union! cls
            else
              h[cls.vars] = cls
            end
          when 1
            if e
              e.assign literals.first, true
            else
              e = Equivalences.assign literals.first=>true
            end
          else
            raise Error.new("unprocessable size")
          end
          h
        end.values
        noisy { "#{indent}#{clauses.map(&:to_s).join(", ")}" }
        results = clauses.map do |cls|
          x = cls.simplify
          case x
          when false
            return false
          when Hash, Equivalences
            if !ec_vars[0].is_a?(Integer) &&
               !x[var1].is_a?(Integer)
              return false if x[var1] != ec_vars[0]
            end
            if !ec_vars[1].is_a?(Integer) &&
               !x[var2].is_a?(Integer)
              return false if x[var2] != ec_vars[1]
            end
            if !ec_vars[2].is_a?(Integer) &&
               !x[var3].is_a?(Integer)
              return false if x[var3] != ec_vars[2]
            end
            x
          when Clause2LiteralSet
            x
          else
            raise "_reduce_merge: TODO #{x.inspect}"
          end
        end
        results.push e if e
        noisy { "#{indent}_reduce_merge: #{results.map(&:to_s).join(", ")}" }
        self.class.unify results
      end
    end

    def reduce equivalences
      return false if set_vector == 0b1111
      s = simplify
      case s
      when Array
        # ignore
      when Hash
        return Equivalences[s].merge!(equivalences)
      when true
        return !equivalences.contradiction?
      when false
        return false
      end
      ec_var1 = equivalences[var1]
      ec_var2 = equivalences[var2]
      ec_var3 = equivalences[var3]
      return self if ec_var1.nil? && ec_var2.nil? && ec_var3.nil?
      ec_var1 = var1 if ec_var1.nil?
      ec_var2 = var2 if ec_var2.nil?
      ec_var3 = var3 if ec_var3.nil?
      noisy { "#{indent}reduce: ec_var1: #{ec_var1}  ec_var2: #{ec_var2}  ec_var3: #{ec_var3}" }
      rw = to_s
      noisy { "#{indent}reduce: #{rw}" }
      noisy { "#{indent}reduce: #{set_vectors.map{|x| ("%8s" % x.to_s(2)).gsub(' ', '0')}.join(", ")}" }
      rw = rw.gsub(var1.to_s, ec_var1.to_s).
             gsub(var2.to_s, ec_var2.to_s).
             gsub(var3.to_s, ec_var3.to_s).
             gsub("-false", "true").
             gsub("-true", "false").
             gsub("--", "")
      noisy { "#{indent}reduce: #{rw}" }
      if ec_var2.is_a?(Integer) && ec_var3.is_a?(Integer) &&
         ec_var2.abs == ec_var3.abs
        _reduce_merge 2, 3, ec_var1, ec_var2, ec_var3
      elsif ec_var1.is_a?(Integer) && ec_var3.is_a?(Integer) &&
            ec_var1.abs == ec_var3.abs
        _reduce_merge 1, 3, ec_var1, ec_var2, ec_var3
      elsif ec_var1.is_a?(Integer) && ec_var2.is_a?(Integer) &&
            ec_var1.abs == ec_var2.abs
        _reduce_merge 1, 2, ec_var1, ec_var2, ec_var3
      elsif ec_var1.is_a?(Integer) && ec_var2.is_a?(Integer) && ec_var3.is_a?(Integer)
        _reduce_ints ec_var1, ec_var2, ec_var3
      else
        _reduce_bools ec_var1, ec_var2, ec_var3
      end
    end

    def subsumed_by other
      unless other.is_a? Clause2LiteralSet
        raise Error.new("other must be a Clause2LiteralSet")
      end
      mask = 0
      osv = other.set_vector << 1
      if var12 == other.vars
        noisy { "12 match" }
        #        nnn nnp npn npp pnn pnp ppn ppp
        #        ab  ab  ab  ab  ab  ab  ab  ab
        #        11  11  10  10  01  01  00  00
        4.times do |idx|
          osv >>= 1
          next if osv & 1 == 0
          mask1 = 0b00000001 << (2 * idx)
          mask |= mask1
          mask |= mask1 << 1
        end
        raise "not a num #{mask}" unless mask.is_a? Integer
      elsif var13 == other.vars
        noisy { "13 match" }
        #        nnn nnp npn npp pnn pnp ppn ppp
        #        a b a b a b a b a b a b a b a b
        #        11  10  11  10  01  00  01  00
        masks = [0b00000001, 0b00000010, 0b00010000, 0b00100000]
        4.times do |idx|
          osv >>= 1
          next if osv & 1 == 0
          mask1 = masks[idx]
          mask |= mask1
          mask |= (mask1 << 2)
        end
        raise "not a num #{mask}" unless mask.is_a? Integer
      elsif var23 == other.vars
        noisy { "23 match" }
        #        nnn nnp npn npp pnn pnp ppn ppp
        #         ab  ab  ab  ab  ab  ab  ab  ab
        #         11  10  01  00  11  10  01  00
        4.times do |idx|
          osv >>= 1
          next if osv & 1 == 0
          mask |= 1 << idx
          mask |= 1 << (idx + 4)
        end
        raise "not a num #{mask}" unless mask.is_a? Integer
      else
        raise "wtf?"
      end
      sv = set_vector
      noisy { "other  = %8s" % other.set_vector.to_s(2) }
      noisy { "mask   = %8s" % mask.to_s(2) }
      noisy { "sv     = %8s" % sv.to_s(2) }
      remain = sv & ~mask
      noisy { "remain = %8s" % remain.to_s(2) }
      return true if remain == 0
      all = sv | mask
      return false if all == 0b11111111
      return self if sv == remain # no change
      s_min = SIMPLIFY[remain]
      s_max = SIMPLIFY[all]
      puts "#{s_min.inspect}  #{s_max.inspect}"
      z = dup
      if s_max.nil?
        z.set_vector = remain
      elsif s_min.nil?
        z.set_vector = all
      else
        c3_min = s_min.count{|x| x.is_a? Clause3LiteralSet}
        c3_max = s_max.count{|x| x.is_a? Clause3LiteralSet}
        if c3_min <= c3_max
          z.set_vector = remain
        else
          z.set_vector = all
        end
      end
      z
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

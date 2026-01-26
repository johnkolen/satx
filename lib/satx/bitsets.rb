module Satx
  class BitSet
    def initialize *args
      # puts args.inspect
      @bits = args.size
      # puts @bits
    end
    # 1,  2  : 0x0001
    # 1, -2  : 0x0010
    #-1,  2  : 0x0100
    #-1, -2  : 0x1000

    # 1,  2,  3  : 0x00000001
    # 1,  2, -3  : 0x00000010
    # 1, -2,  3  : 0x00000100
    # 1, -2, -3  : 0x00001000
    #-1,  2,  3  : 0x00010000
    #-1,  2, -3  : 0x00100000
    #-1, -2,  3  : 0x01000000
    #-1, -2, -3  : 0x10000000
    def _to_idxs args
      @fixed = args.inject([]){|ary, v| ary[v.abs] = ((0 <=> v) + 1) / 2 unless v.nil?; ary}
      # puts "@fixed = #{@fixed}"
      @fixed.shift # remove leading nil
      @fixed.push nil while @fixed.size < @bits
      # puts @fixed.inspect
      _to_idxs_rec
    end

    def _to_idxs_rec
      if @fixed.size == 1
        v = @fixed.first
        return [0, 1] if v.nil?
        return [v]
      end
      v = @fixed.pop
      u = _to_idxs_rec
      @fixed.push v
      u2 = u.map{|x| 2 * x}
      return u2.concat(u2.map{|x| x + 1}) if v.nil?
      return u2 if v == 0
      return u2.map{|x| x + 1}
    end

    def _neg ary
      ary.map do |x|
        if x.nil?
          nil
        else
          -x
        end
      end
    end
  end

  class OrBitSet < BitSet
    attr_reader :bit_set

    def initialize *args
      @ary = args.dup
      # puts "---- OR #{args.inspect}"
      super
      idxs = _to_idxs _neg(args)
      mask = (2**2**@bits - 1)
      #puts idxs.inspect
      @bit_set = idxs.inject(0){|b, idx| b | (1 << idx) } ^ mask
      #puts "%#{2**@bits}s" % @bit_set.to_s(2)
    end

    def to_s
      @ary.compact.inspect
    end

    def weight
      @weight ||= @ary.compact.size
    end
  end

  class EqBitSet < BitSet
    attr_reader :bit_set

    def initialize a, b, bits
      @a = a
      @b = b
      @bits = bits
      # puts "---- EQ #{a} #{b}"
      same = (a <=> 0) == (b <=> 0)
      mask_a = 1 << a.abs
      mask_b = 1 << b.abs
      sa = (@bits - a.abs)
      sb = (@bits - b.abs)
      bits = (0...2**@bits).to_a.select do |x|
        if same
          (x >> sa) & 1 == (x >> sb) & 1
        else
          (x >> sa) & 1 != (x >> sb) & 1
        end
      end
      @bit_set = bits.inject(0){|b, idx| b | (1 << idx)}
    end

    def to_s
      "{#{@b} => #{@a}}"
    end

    def weight
      1
    end
  end
  class Generator
    def two_vars
      @h = Hash.new
      @h[0] = false
      search 2**2**2 - 1, []
      @h.keys.sort.each do |k|
        puts "%8s : #{path_str @h[k]}" % k.to_s(2)
      end
    end

    def three_vars
      @h = Hash.new
      @h[0] = false
      (1...2**2**3).each{|x| @h[x] = nil}
      search3 2**2**3 - 1, []
      @h.keys.sort.each do |k|
        puts "%8s : #{path_str @h[k]}" % k.to_s(2)
      end
      nonreduced = @h.values.select{|x| x.is_a?(Array) && x.map(&:weight).max == 3}.size
      puts "Non reduced: #{nonreduced} / #{@h.size}"
    end

    def set_vector_map
      @h = Hash.new
      @h[0] = false
      (1...2**2**3).each{|x| @h[x] = nil}
      search3 2**2**3 - 1, []
      cls = Clause3LiteralSet.new 1, 2, 3
      puts cls.to_s
      (0...256).each do |sv|
        cls.set_vector = sv
        puts "%8s %8s %90s => %s" %
             [sv.to_s(2), cls.covers.to_s(2), cls.to_s, path_str(@h[cls.covers])]
      end
      puts "SIMPLIFY = {"
      (0...256).each do |sv|
        cls.set_vector = sv
        rhs = path_str(@h[cls.covers]).gsub(" &", ",")
        if cls.to_s == rhs
          puts "%6d => nil,  # #{rhs}" % sv
        else
          puts "%6d => [#{rhs}]," % [sv]
        end
        # break if sv == 150
      end
      puts "}"
    end

    def path_str path
      return 'nil' if path.nil?
      return 'false' if path == false
      return 'true' if path == true || path.empty?
      path.map(&:to_s).join(" & ")
    end

    def search bits, path
      return if bits == 0
      return if 2 < path.size
      puts "bits = %8s   #{path_str path}" % bits.to_s(2)
      if @h.key? bits
        @h[bits] = path.dup if path.size < @h[bits].size
      else
        @h[bits] = path.dup
      end
      [1, -1, 2, -2].each do |a|
        x = OrBitSet.new a, nil
        path.push x
        search bits & x.bit_set, path
        path.pop
      end
      [1, -1].each do |a|
        [2, -2].each do |b|
          x = OrBitSet.new a, b
          path.push x
          search bits & x.bit_set, path
          path.pop
        end
      end
      [2, -2].each do |b|
        x = EqBitSet.new 1, b, 2
        path.push x
        search bits & x.bit_set, path
        path.pop
      end
    end

    def weight path
      path.map(&:weight).sum
    end

    def search3 bits, path
      return if bits == 0
      return if 4 < path.size
      # puts "bits = %8s   #{path_str path}" % bits.to_s(2)
      if @h[bits].nil?
        @h[bits] = path.dup
      else
        if weight(path) < weight(@h[bits])
          @h[bits] = path.dup
        else
          return
        end
      end
      [1, -1, 2, -2, 3, -3].each do |a|
        x = OrBitSet.new a, nil, nil
        path.push x
        search3 bits & x.bit_set, path
        path.pop
      end
      [1, -1].each do |a|
        [2, -2].each do |b|
          x = OrBitSet.new a, b, nil
          path.push x
          search3 bits & x.bit_set, path
          path.pop
        end
      end
      [1, -1].each do |a|
        [3, -3].each do |b|
          x = OrBitSet.new a, b, nil
          path.push x
          search3 bits & x.bit_set, path
          path.pop
        end
      end
      [2, -2].each do |a|
        [3, -3].each do |b|
          x = OrBitSet.new a, b, nil
          path.push x
          search3 bits & x.bit_set, path
          path.pop
        end
      end
      [2, -2, 3, -3].each do |b|
        x = EqBitSet.new 1, b, 3
        path.push x
        search3 bits & x.bit_set, path
        path.pop
      end
      [3, -3].each do |b|
        x = EqBitSet.new 2, b, 3
        path.push x
        search3 bits & x.bit_set, path
        path.pop
      end
      [1, -1].each do |a|
        [2, -2].each do |b|
          [3, -3].each do |c|
            x = OrBitSet.new a, b, c
            path.push x
            search3 bits & x.bit_set, path
            path.pop
          end
        end
      end
    end
  end
end

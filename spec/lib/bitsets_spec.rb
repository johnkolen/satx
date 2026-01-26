module Satx
  RSpec.describe BitSet do
    it 'to_idxs 1 of 2' do
      bs2 = BitSet.new 1, 2
      expect(bs2._to_idxs [1, nil]).to eq [0, 1]
      expect(bs2._to_idxs [-1, nil]).to eq [2, 3]
      expect(bs2._to_idxs [2, nil]).to eq [0, 2]
      expect(bs2._to_idxs [-2, nil]).to eq [1, 3]
    end
    it 'to_idxs 2' do
      bs2 = BitSet.new 1, 2
      expect(bs2._to_idxs [1, 2]).to eq [0]
      expect(bs2._to_idxs [1, -2]).to eq [1]
      expect(bs2._to_idxs [-1, 2]).to eq [2]
      expect(bs2._to_idxs [-1, -2]).to eq [3]
    end
    it 'to_idxs 3' do
      bs2 = BitSet.new 1, 2, 3
      expect(bs2._to_idxs [1, 2, 3]).to eq [0]
      expect(bs2._to_idxs [1, 2, -3]).to eq [1]
      expect(bs2._to_idxs [1, -2, 3]).to eq [2]
      expect(bs2._to_idxs [1, -2, -3]).to eq [3]
      expect(bs2._to_idxs [-1, 2, 3]).to eq [4]
      expect(bs2._to_idxs [-1, 2, -3]).to eq [5]
      expect(bs2._to_idxs [-1, -2, 3]).to eq [6]
      expect(bs2._to_idxs [-1, -2, -3]).to eq [7]
    end
  end

  RSpec.describe OrBitSet do
    context 'initializes' do
      it 'one args for two bits' do
        or1 = OrBitSet.new 1, nil
        expect(or1.bit_set).to eq 0b0011
        orn1 = OrBitSet.new -1, nil
        expect(orn1.bit_set).to eq 0b1100
        or2 = OrBitSet.new 2, nil
        expect(or2.bit_set).to eq 0b0101
        orn2 = OrBitSet.new -2, nil
        expect(orn2.bit_set).to eq 0b1010
      end
      it 'two args' do
        or12 = OrBitSet.new 1, 2
        expect(or12.bit_set).to eq 0b111
        expect(or12.bit_set).to eq Clause2LiteralSet.new(1, 2).covers
        or1n2 = OrBitSet.new 1, -2
        expect(or1n2.bit_set).to eq 0b1011
        expect(or1n2.bit_set).to eq Clause2LiteralSet.new(1, -2).covers
        orn12 = OrBitSet.new -1, 2
        expect(orn12.bit_set).to eq 0b1101
        expect(orn12.bit_set).to eq Clause2LiteralSet.new(-1, 2).covers
        orn1n2 = OrBitSet.new -1, -2
        expect(orn1n2.bit_set).to eq 0b1110
        expect(orn1n2.bit_set).to eq Clause2LiteralSet.new(-1, -2).covers
      end
      it 'three args' do
        or123 = OrBitSet.new 1, 2, 3
        expect(or123.bit_set).to eq 0b01111111
        or12n3 = OrBitSet.new 1, 2, -3
        expect(or12n3.bit_set).to eq 0b10111111
        or1n23 = OrBitSet.new 1, -2, 3
        expect(or1n23.bit_set).to eq 0b11011111
        or1n2n3 = OrBitSet.new 1, -2, -3
        expect(or1n2n3.bit_set).to eq 0b11101111
        orn123 = OrBitSet.new -1, 2, 3
        expect(orn123.bit_set).to eq 0b11110111
        orn12n3 = OrBitSet.new -1, 2, -3
        expect(orn12n3.bit_set).to eq 0b11111011
        orn1n23 = OrBitSet.new -1, -2, 3
        expect(orn1n23.bit_set).to eq 0b11111101
        orn1n2n3 = OrBitSet.new -1, -2, -3
        expect(orn1n2n3.bit_set).to eq 0b11111110
      end
      it 'two args three vars' do
        or12 = OrBitSet.new 1, 2, nil
        expect(or12.bit_set).to eq 0b00111111
      end
    end
  end

  RSpec.describe EqBitSet do
    context 'initializes' do
      it 'two bits' do
        eq12 = EqBitSet.new 1, 2, 2
        expect(eq12.bit_set).to eq 0b1001
        eq1n2 = EqBitSet.new 1, -2, 2
        expect(eq1n2.bit_set).to eq 0b0110
        eqn1n2 = EqBitSet.new -1, -2, 2
        expect(eqn1n2.bit_set).to eq 0b1001
      end
      it 'three bits' do
        eq12 = EqBitSet.new 1, 2, 3
        expect(eq12.bit_set).to eq 0b11000011
        eq1n2 = EqBitSet.new 1, -2, 3
        expect(eq1n2.bit_set).to eq 0b00111100
        eqn1n2 = EqBitSet.new -1, -2, 3
        expect(eqn1n2.bit_set).to eq 0b11000011
      end
    end
  end
  RSpec.describe Generator do
    it 'two vars' do
      g = Generator.new
      g.two_vars
    end
    it 'three vars' do
      g = Generator.new
      #g.three_vars
      g.set_vector_map
    end
  end
end

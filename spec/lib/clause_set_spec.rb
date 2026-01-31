module Satx
  RSpec.describe ClauseSet do
    let(:cs) { ClauseSet.new }
    context 'initializes' do
      it 'empty' do
        c = cs.dup
        expect(c).to be_a ClauseSet
        expect(c.size).to be_zero
      end
      it 'multiple' do
        c = ClauseSet[[1,2],[2,3]]
        expect(c.size).to eq 2
        expect(c.sets_size).to eq 2
      end
      it 'multiple with dups' do
        c = ClauseSet[[1, 2], [2, 3], [1, 2]]
        expect(c.size).to eq 2
        expect(c.sets_size).to eq 2
      end
      it 'multiple with dup sign diff' do
        c = ClauseSet[[1, 2], [2, 3], [-1, 2]]
        expect(c.size).to eq 3
        expect(c.sets_size).to eq 2
      end
      it 'Clause3' do
        c = ClauseSet[[-1, 2, 3], [-1, -2, 4], [2, 3, 4], [-1, -2, -3], [-1, 3, -4],
                      [2, -3, -4],[-1, 2, -3], [-1, 3, 4], [1, 3, -4], [1, -2, -3],
                      [1, 2, 4], [1, 2, 3]]
        expect(c.size).to eq 12
      end
    end
    let(:cpp) { Clause2LiteralSet.new 1, 2 }
    let(:cpn) { Clause2LiteralSet.new 1, -2 }
    let(:cnp) { Clause2LiteralSet.new -1, 2 }
    let(:cnn) { Clause2LiteralSet.new -1, -2 }
    let(:cc){ Clause2LiteralSet.new 10, 20 }
    context 'adds' do
      before(:each) do
        cs.clear
      end
      it 'one' do
        cs.add cpp
        expect(cpp.size).to eq 1
        expect(cs.size).to eq 1
        expect(cs.sets_size).to eq 1
      end
      it 'two diff var sets' do
        cs.add cpp
        cs.add cc
        expect(cs.size).to eq 2
        expect(cs.sets_size).to eq 2
      end
      it 'two same var set' do
        cs.add cpp
        cs.add cnn
        expect(cs.size).to eq 2
        expect(cs.sets_size).to eq 1
      end
    end

    context 'simplify' do
      it '[[1, 2], [2, 3], [-1, 2]]' do
        c = ClauseSet[[1, 2], [2, 3], [-1, 2]]
        equivs = c.simplify!
        puts equivs.to_s
        expect(equivs[2]).to eq true
        expect(c).to be_empty
      end
      it '[[1, 2], [-2, 3], [-1, 2]]' do
        c = ClauseSet[[1, 2], [-2, 3], [-1, 2]]
        equivs = c.simplify!
        puts equivs.to_s
        expect(equivs[2]).to eq true
        expect(equivs[3]).to eq true
        expect(c).to be_empty
      end
      it '2 vars full less nn' do
        c = ClauseSet[[1, 2], [1, -2], [-1, 2]]
        puts c.to_s
        equivs = c.simplify!
        puts equivs.to_s
        expect(equivs[1]).to eq true
        expect(equivs[2]).to eq true
        expect(c).to be_empty
      end
      it '2 vars full' do
        c = ClauseSet[[1, 2], [1, -2], [-1, 2], [-1, -2]]
        expect(c.simplify!).to eq false
      end
      it '3 vars full' do
        c = ClauseSet[[1, 2, 3], [1, 2, -3], [1, -2, 3], [1, -2, -3],
                      [-1, 2, 3], [-1, 2, -3], [-1, -2, 3], [-1, -2, -3]]
        expect(c.simplify!).to eq false
      end
      it '3 vars nearly full' do
        c = ClauseSet[[1, 2, 3], [1, 2, -3], [1, -2, 3], [1, -2, -3],
                      [-1, 2, 3], [-1, 2, -3], [-1, -2, 3]]
        expect(c.simplify!).to eq assign(1=>true, 2=>true, 3=>true)
      end
      it 'case 1' do
        cs = ClauseSet[[-1, 4, -5], [-4, 6], [-1, -4], [4, -7]]
        rv = cs.reduce!(assign(1=>false, 2=>false, 3=>false, 4=>false,
                              5=>true, 6=>true, 7=>false, 8=>true))
        puts rv.inspect
        puts cs
      end
      it 'case 2' do
        cs = ClauseSet[[1, -3, 8], [1, -3, -8], [-1, -3, 8], [-1, -4, -7], [-1, -4, 8],
                       [-1, -3, 7], [-1, -3, -7], [-3, -4, -5], [-1, 4, -5], [-2, 4, -7],
                       [-1, -3, -5], [2, -4, -8], [3, -4, 6], [-2, 3, -8]]
        rv = cs.simplify!
        puts rv
        puts cs
        expect(rv).to eq false
      end
    end

    context 'to clause arrays' do
      it 'empty' do
        c = ClauseSet[]
        expect(c.to_a).to eq []
      end
      it '2 vars full' do
        c = ClauseSet[[1, 2], [1, -2], [-1, 2], [-1, -2]]
        expect(c.to_a).to eq [[1, 2], [1, -2], [-1, 2], [-1, -2]]
      end
    end

    context 'intersection' do
      it 'case 1' do
        cs1 = ClauseSet[[-5, -8], [2, -7]]
        cs2 = ClauseSet[[-5, -8], [2, -7], [1, 6], [-1, -4],
                        [-1, 2], [4, -5], [1, -8]]
        puts cs1
        puts cs2
        puts cs1.class.to_s
        cx = cs1.intersection cs2
        expect(cx).to eq ClauseSet[[-5, -8], [2, -7]]
      end
      it 'case 2' do
        cs1 =
          ClauseSet[[3, 4], [3, -4], [3, -6], [-1, -8], [-4, -5], [2, 4], [2, -4],
                   [-1, -4]]
        cs2 =
          ClauseSet[[3, 4], [3, -4], [3, -6], [-1, -8], [-4, -5], [2, 4], [-1, 4]]
        cs12 = cs1.intersection cs2
        expect(cs12).to eq ClauseSet[[3, 4], [3, -4], [3, -6], [-1, -8], [-4, -5]]
      end
    end
  end
end

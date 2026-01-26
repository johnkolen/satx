module Satx
  RSpec.describe Clause2LiteralSet do
    let(:cpp) { Clause2LiteralSet.new 1, 2 }
    let(:cpn) { Clause2LiteralSet.new 1, -2 }
    let(:cnp) { Clause2LiteralSet.new -1, 2 }
    let(:cnn) { Clause2LiteralSet.new -1, -2 }
    let(:cc){ Clause2LiteralSet.new 10, 20 }
    context 'initializes' do
      it 'plus plus' do
        expect(cpp).to be_a Clause2LiteralSet
        expect(cpp.to_s).to eq "[1, 2]"
        expect(cpp.size).to eq 1
      end
      it 'plus plus reverse' do
        c = Clause2LiteralSet.new 2, 1
        expect(c).to be_a Clause2LiteralSet
        expect(c.to_s).to eq "[1, 2]"
        expect(c.size).to eq 1
      end
      it 'plus neg' do
        expect(cpn).to be_a Clause2LiteralSet
        expect(cpn.to_s).to eq "[1, -2]"
        expect(cpn.size).to eq 1
      end
      it 'neg plus reverse' do
        c = Clause2LiteralSet.new -2, 1
        expect(c).to be_a Clause2LiteralSet
        expect(c.to_s).to eq "[1, -2]"
        expect(c.size).to eq 1
      end
      it 'neg plus' do
        c = Clause2LiteralSet.new -1, 2
        expect(cnp).to be_a Clause2LiteralSet
        expect(cnp.to_s).to eq "[-1, 2]"
        expect(cnp.size).to eq 1
      end
      it 'neg neg' do
        c = Clause2LiteralSet.new -1, -2
        expect(cnn).to be_a Clause2LiteralSet
        expect(cnn.to_s).to eq "[-1, -2]"
        expect(cnn.size).to eq 1
      end
      it 'bad args' do
        expect{Clause2LiteralSet.new 1, 1}.to raise_error Error
      # TODO: new 1, 1 and new 1, -1
      end
    end

    context 'union' do
      it 'pp & pn' do
        c = cpp.dup
        c.union! cpn
        expect(c.to_s).to eq "[1, 2], [1, -2]"
      end
    end

    context 'simplify' do
      it 'pp' do
        expect(cpp.simplify).to be cpp
      end
      it 'pn' do
        expect(cpn.simplify).to be cpn
      end
      it 'np' do
        expect(cnp.simplify).to be cnp
      end
      it 'nn' do
        expect(cnn.simplify).to be cnn
      end
      it 'pp & pn' do
        expect(cpp.dup.union!(cpn).simplify).to eq(assign(1=>true))
      end
      it 'pp & np' do
        expect(cpp.dup.union!(cnp).simplify).to eq(assign(2=>true))
      end
      it 'pp & nn' do
        expect(cpp.dup.union!(cnn).simplify).to eq(assign(2=>-1))
      end
      it 'pn & np' do
        expect(cpn.dup.union!(cnp).simplify).to eq(assign(2=>1))
      end
      it 'pn & nn' do
        expect(cpn.dup.union!(cnn).simplify).to eq(assign(2=>false))
      end
      it 'np & nn' do
        expect(cnp.dup.union!(cnn).simplify).to eq(assign(1=>false))
      end
      it 'pp & pn & np' do
        expect(cpp.dup.union!(cpn).union!(cnp).simplify).to eq assign(1=>true, 2=>true)
      end
      it 'pp & pn & nn' do
        expect(cpp.dup.union!(cpn).union!(cnn).simplify).to eq assign(1=>true, 2=>false)
      end
      it 'pp & np & nn' do
        expect(cpp.dup.union!(cnp).union!(cnn).simplify).to eq assign(1=>false, 2=>true)
      end
      it 'pn & np & nn' do
        expect(cpn.dup.union!(cnp).union!(cnn).simplify).to eq assign(1=>false, 2=>false)
      end
      it 'pp & pn & np & nn' do
        expect(cpp.dup.union!(cpn).union!(cnp).union!(cnn).simplify).to eq false
      end
      it 'case 1' do
        cls = Clause2LiteralSet[[4, 8], [-4, 8]]
        expect(cls.to_s).to eq "[4, 8], [-4, 8]"
        expect(cls.simplify).to eq assign(8=>true)
      end
      it 'case 2' do
        cls = Clause2LiteralSet[[-1, 8], [-1, -8]]
        expect(cls.to_s).to eq "[-1, 8], [-1, -8]"
        expect(cls.simplify).to eq assign(1=>false)
      end
    end

    context 'set vars' do
      it 'preconditions' do
        c = cc.dup
        expect(c.var1).to eq 10
        expect(c.var2).to eq 20
      end
      it 'var1 set' do
        c = cc.dup
        c.var1 = 5
        expect(c.var1).to eq 5
      end
      it 'var2 set' do
        c = cc.dup
        c.var2 = 15
        expect(c.var2).to eq 15
      end
    end

    context 'reduce' do
      it 'unchanged' do
        c = cpp.dup
        expect(c.reduce(Equivalences.new)).to be c
      end
      it 'pp && 2==1' do
        c = cpp.dup
        expect(c.reduce(Equivalences[{2=>1, -2=>-1}])).to eq({1=>true, -1=>false})
      end
      it 'pp && 2!=1' do
        c = cpp.dup
        expect(c.reduce(Equivalences[{2=>-1, -2=>1}])).to eq true
      end
      it 'pn && 2==1' do
        c = cpn.dup
        expect(c.reduce(Equivalences[{2=>1, -2=>-1}])).to eq true
      end
      it 'pn && 2!=1' do
        c = cpn.dup
        expect(c.reduce(Equivalences[{2=>-1, -2=>1}])).to eq ({1=>true, -1=>false})
      end
      it 'np && 2==1' do
        c = cnp.dup
        expect(c.reduce(Equivalences[{2=>1, -2=>-1}])).to eq true
      end
      it 'np && 2!=1' do
        c = cnp.dup
        expect(c.reduce(Equivalences[{2=>-1, -2=>1}])).to eq ({1=>false, -1=>true})
      end
      it 'nn && 2==1' do
        c = cnn.dup
        expect(c.reduce(Equivalences[{2=>1, -2=>-1}])).to eq({-1=>true, 1=>false})
      end
      it 'nn && 2!=1' do
        c = cnn.dup
        expect(c.reduce(Equivalences[{2=>-1, -2=>1}])).to eq true
      end

      context "truth assignments" do
        it 'pp && 1==true' do
          c = cpp.dup
          expect(c.reduce(Equivalences[{1=>true, -1=>false}])).to eq true
        end
        it 'pp && 1==false' do
          c = cpp.dup
          expect(c.reduce(Equivalences[{1=>false, -1=>true}])).to eq({2=>true, -2=>false})
        end
        it 'pn && 1==true' do
          expect(cpn.reduce(Equivalences[{1=>true, -1=>false}])).to eq true
        end
        it 'pn && 1==false' do
          expect(cpn.reduce(Equivalences[{1=>false, -1=>true}])).to eq({-2=>true, 2=>false})
        end
        it 'np && 1==true' do
          expect(cnp.reduce(Equivalences[{1=>true, -1=>false}])).to eq({2=>true, -2=>false})
        end
        it 'np && 1==false' do
          expect(cnp.reduce(Equivalences[{1=>false, -1=>true}])).to eq true
        end
        it 'nn && 1==true' do
          expect(cnn.reduce(Equivalences[{1=>true, -1=>false}])).to eq({-2=>true, 2=>false})
        end
        it 'nn && 1==false' do
          expect(cnn.reduce(Equivalences[{1=>false, -1=>true}])).to eq true
        end

        it 'pp && 2==true' do
          c = cpp.dup
          expect(c.reduce(Equivalences[{2=>true, -2=>false}])).to eq true
        end
        it 'pp && 2==false' do
          c = cpp.dup
          expect(c.reduce(Equivalences[{2=>false, -2=>true}])).to eq({1=>true, -1=>false})
        end
        it 'pn && 2==true' do
          expect(cpn.reduce(Equivalences[{2=>true, -2=>false}])).to eq({1=>true, -1=>false})
        end
        it 'pn && 2==false' do
          expect(cpn.reduce(Equivalences[{2=>false, -2=>true}])).to eq true
        end
        it 'np && 2==true' do
          expect(cnp.reduce(Equivalences[{2=>true, -2=>false}])).to eq true
        end
        it 'np && 2==false' do
          expect(cnp.reduce(Equivalences[{2=>false, -2=>true}])).to eq({-1=>true, 1=>false})
        end
        it 'nn && 2==true' do
          expect(cnn.reduce(Equivalences[{2=>true, -2=>false}])).to eq({-1=>true, 1=>false})
        end
        it 'nn && 2==false' do
          expect(cnn.reduce(Equivalences[{2=>false, -2=>true}])).to eq true
        end
        it 'nn && 1==true && 2==false' do
          expect(cnn.reduce(assign(1=>true, 2=>false))).to eq true
        end
        it 'nn && 1==true && 2==true' do
          expect(cnn.reduce(assign(1=>true, 2=>true))).to eq false
        end
        it 'nn && 1==false && 2==false' do
          expect(cnn.reduce(assign(1=>false, 2=>false))).to eq true
        end
        it 'nn && 1==false && 2==true' do
          expect(cnn.reduce(assign(1=>false, 2=>true))).to eq true
        end

        it 'case 1' do
          cx = Clause2LiteralSet.new -6, -7
          expect(cx.reduce(Equivalences[{7=>-4, -7=>4}]).to_a).to eq [[4, -6]]
        end
        it 'case 2' do
          cx = cpp.dup
          cx.union!(cpn, cnp, cnn)
          result = cx.reduce assign(1=>false)
          expect(result).to eq false
        end
        it 'case 3' do
          # [1, 2], [-1, 2], [-1, -2]
          # {1=>false, -1=>true, 2=>true, -2=>false}
          cx = cpp.dup
          cx.union!(cnp, cnn)
          ec = assign(1=>false, 2=>-1)
          result = cx.reduce ec
          expect(result).to eq({1=>false, -1=>true, 2=>true, -2=>false})
        end
        it 'case 4' do
          # [1, 2], [1, -2], [-1, -2] [{1=>false, -1=>true}]
          cx = cpp.dup
          cx.union!(cpn, cnn)
          expect(cx.to_s).to eq "[1, 2], [1, -2], [-1, -2]"
          result = cx.reduce assign(1=>false)
          expect(result).to eq false
        end
        it 'case 5' do
          # [-1, -2] [{2=>1, -2=>-1}, {1=>false, -1=>true}]
          cx = cnn.dup
          expect(cx.to_s).to eq "[-1, -2]"
          result = cx.reduce assign(1=>false, 2=>1)
          expect(result).to eq true
        end
      end

      it 'lower var1' do
        c = cc.dup
        cx = c.reduce(Equivalences[{10=>5, -10=>-5}])
        expect(cx).not_to be c
        expect(cx.var1).to eq 5
        expect(cx.var2).to eq 20
        expect(cx.set_vector).to eq 0b0001
      end
      it 'lower neg var1' do
        c = cc.dup
        cx = c.reduce(Equivalences[{10=>-5, -10=>5}])
        expect(cx).not_to be c
        expect(cx.var1).to eq 5
        expect(cx.var2).to eq 20
        expect(cx.set_vector).to eq 0b0100
      end
      it 'lower var2' do
        c = cc.dup
        cx = c.reduce(Equivalences[{20=>15, -20=>-15}])
        expect(cx).not_to be c
        expect(cx.var1).to eq 10
        expect(cx.var2).to eq 15
        expect(cx.set_vector).to eq 0b0001
      end
      it 'lower neg var2' do
        c = cc.dup
        cx = c.reduce(Equivalences[{20=>-15, -20=>15}])
        expect(cx.var1).to eq 10
        expect(cx.var2).to eq 15
        expect(cx.set_vector).to eq 0b0010
      end
      it 'lower var2 less than var1' do
        c = cc.dup
        cx = c.reduce(Equivalences[{20=>5, -20=>-5}])
        expect(cx.var1).to eq 5
        expect(cx.var2).to eq 10
        expect(cx.set_vector).to eq 0b0001
      end
    end

    context 'equality' do
      it 'cpp' do
        cppx = cpp.dup
        expect(cppx).to eq cpp
        expect(cppx).not_to be cpp
      end

      it 'intersection' do
        ary1 = [cpp, cpn]
        ary2 = [cnp,cpp.dup]
        expect(ary1.intersection ary2).to eq [cpp]
        expect(ary1.size).to eq 2
      end
    end

    def all_conjunctions k=0, seq=[], &block
      if k == 4
        yield seq
        return
      end
      (k...4).each do |choice|
        seq.push choice
        all_conjunctions choice + 1, seq, &block
        seq.pop
      end
    end

    def all_assignments k=0, seq=[], &block
      if k == 6
        yield seq
        return
      end
      (k...6).each do |choice|
        seq.push choice
        all_conjunctions choice + 1, seq, &block
        seq.pop
      end
    end

    def conjunction_clause2s clauses
      clauses.inject(clauses.pop.dup){|sum, clause| sum.union! clause}
    end

    def conjunction_bitsets bitsets
      bitsets.inject(bitsets.pop.bit_set) do |bit_set, clause|
        bit_set & clause.bit_set
      end
    end

    def conjunction_assignments assignments
      assignments.inject(Equivalences.new) do |all, assignment|
        #print "xxx #{all} #{assignment}"
        #raise "cain"
        return false unless all.merge! assignment
        #puts "   -> #{all}"
        all
      end
    end


    context 'mass testing' do
      let(:c2s){[cpp.dup, cpn.dup, cnp.dup, cnn.dup]}
      let(:bss){[[1,2],[1,-2],[-1,2],[-1,-2]].map{|a,b| OrBitSet.new a, b}}
      let(:ec2s){[{2=>1}, {-2=>1},
                  {1=>true}, {1=>false},
                  {2=>true}, {2=>false}].map{|x| assign **x}}
      let(:ebss){[EqBitSet.new(1, 2, 2), EqBitSet.new(1, -2, 2),
                  OrBitSet.new(1, nil), OrBitSet.new(-1, nil),
                  OrBitSet.new(2, nil), OrBitSet.new(-2, nil)]}

      def hash_to_bs h
        bs = 0b1111
        h.keys.map(&:abs).union.sort.each do |a|
          b = h[a]
          case b
          when Integer
            bs = bs & EqBitSet.new(a, b, 2).bit_set
            # puts ">>> #{a} == #{b}"
          when true
            v = OrBitSet.new(a, nil).bit_set
            bs = bs & v
            # puts ">>> #{a} == true  #{bs.to_s(2)} #{v.to_s(2)}"
          when false
            v = OrBitSet.new(-a, nil).bit_set
            bs = bs & v
            # puts ">>> #{a} == false  #{bs.to_s(2)} #{v.to_s(2)}"
          end
        end
        bs
      end
      it 'conjuctions' do
        all_conjunctions do |seq|
          # puts seq.inspect
          conj = conjunction_clause2s seq.map{|idx| c2s[idx]}
          # puts conj
          sconj = conj.simplify
          # puts sconj
          bs_conj = conjunction_bitsets seq.map{|idx| bss[idx]}
          # puts bs_conj.to_s(2)
          # puts conj.covers.to_s(2)
          expect(bs_conj).to eq conj.covers
          case sconj
          when Hash
            bs = hash_to_bs sconj
            # puts "bs_conj = %5s   bs = %5s" % [bs_conj.to_s(2), bs.to_s(2)]
            expect(bs_conj).to eq bs
          when true
            expect(bs_conj).to eq 0b1111
          when false
            expect(bs_conj).to eq 0b0000
          else
            expect(bs_conj).to eq sconj.covers
          end
        end
      end

      it 'conjuctions with assignments' do
        all_conjunctions do |seq|
          conj = conjunction_clause2s seq.map{|idx| c2s[idx]}
          bs_conj = conjunction_bitsets seq.map{|idx| bss[idx]}
          expect(bs_conj).to eq conj.covers
          all_assignments do |seq|
            # puts "=" * 30
            ax = seq.map{|idx| ec2s[idx]}
            # puts "  #{conj} #{ax}"
            eq_conj = conjunction_assignments ax
            # puts "  eq_conj = #{eq_conj}"
            eq_bs = conjunction_bitsets seq.map{|idx| ebss[idx]}
            # puts "  eq_bs = #{eq_bs.to_s(2)}"
            case eq_conj
            when false
              expect(eq_bs).to eq 0
            when true
              puts seq.map{|idx| ec2s[idx]}.map(&:to_s).inspect
              raise "cain #{seq.inspect}  #{eq_bs}"
            else
              # puts "  siplified conj = #{conj.simplify}"
              final_conj = conj.reduce eq_conj
              # puts "  final_conj = #{final_conj}"
              # puts "  bs_conj = %5s eq_bs = %5s " %
              #        [bs_conj.to_s(2), eq_bs.to_s(2)]
              case final_conj
              when false
                expect(bs_conj & eq_bs).to eq 0b0000
              when Hash
                bs = hash_to_bs final_conj
                # puts "  bs = %5s" % bs.to_s(2)
                expect(bs_conj & eq_bs).to eq bs
              when true
                expect(bs_conj & eq_bs).to be > 0
                # only one bit should be on for the true assignmetn
                z = bs_conj & eq_bs
                z = z >> 1 while z > 1
                expect(z).to eq 1
              else
                raise "wtf?"
              end
            end
          end
        end
      end
    end
  end
end

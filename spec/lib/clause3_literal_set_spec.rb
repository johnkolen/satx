module Satx
  RSpec.describe Clause3LiteralSet do
    let(:cppp) { Clause3LiteralSet.new 1, 2, 3 }
    let(:cppn) { Clause3LiteralSet.new 1, 2, -3 }
    let(:cpnp) { Clause3LiteralSet.new 1, -2, 3 }
    let(:cpnn) { Clause3LiteralSet.new 1, -2, -3 }
    let(:cnpp) { Clause3LiteralSet.new -1, 2, 3 }
    let(:cnpn) { Clause3LiteralSet.new -1, 2, -3 }
    let(:cnnp) { Clause3LiteralSet.new -1, -2, 3 }
    let(:cnnn) { Clause3LiteralSet.new -1, -2, -3 }
    let(:all_cxxx) {[cppp.dup, cppn.dup, cpnp.dup, cpnn.dup,
                     cnpp.dup, cnpn.dup, cnnp.dup, cnnn.dup]}
    # these showup as results
    let(:cppx) { Clause2LiteralSet.new 1, 2 }
    let(:cpnx) { Clause2LiteralSet.new 1, -2 }
    let(:cnpx) { Clause2LiteralSet.new -1, 2 }
    let(:cnnx) { Clause2LiteralSet.new -1, -2 }
    let(:cpxp) { Clause2LiteralSet.new 1, 3 }
    let(:cpxn) { Clause2LiteralSet.new 1, -3 }
    let(:cnxp) { Clause2LiteralSet.new -1, 3 }
    let(:cnxn) { Clause2LiteralSet.new -1, -3 }
    let(:cxpp) { Clause2LiteralSet.new 2, 3 }
    let(:cxpn) { Clause2LiteralSet.new 2, -3 }
    let(:cxnp) { Clause2LiteralSet.new -2, 3 }
    let(:cxnn) { Clause2LiteralSet.new -2, -3 }
    let(:all_cxxx_binary) {[cppx.dup, cpnx.dup, cnpx.dup, cnnx.dup,
                            cpxp.dup, cpxn.dup, cnxp.dup, cnxn.dup,
                            cxpp.dup, cxpn.dup, cxnp.dup, cxnn.dup ]}

    let(:cc){ Clause3LiteralSet.new 10, 20, 30 }
    context 'initializes' do
      it 'plus plus plus' do
        expect(cppp).to be_a Clause3LiteralSet
        expect(cppp.var1).to eq 1
        expect(cppp.var2).to eq 2
        expect(cppp.var3).to eq 3
        expect(cppp.to_s).to eq "[1, 2, 3]"
        expect(cppp.size).to eq 1
        expect(cppp.covers).to eq 0b01111111
      end

      it 'plus plus plus reverse' do
        c = Clause3LiteralSet.new 3, 2, 1
        expect(c).to be_a Clause3LiteralSet
        expect(c.to_s).to eq "[1, 2, 3]"
        expect(c.size).to eq 1
      end
      it 'plus plus neg' do
        expect(cppn).to be_a Clause3LiteralSet
        expect(cppn.var1).to eq 1
        expect(cppn.var2).to eq 2
        expect(cppn.var3).to eq 3
        expect(cppn.to_s).to eq "[1, 2, -3]"
        expect(cppn.size).to eq 1
        expect(cppn.covers).to eq 0b10111111
      end

      it 'neg plus plus reverse' do
        c = Clause3LiteralSet.new -3, 2, 1
        expect(c).to be_a Clause3LiteralSet
        expect(c.to_s).to eq "[1, 2, -3]"
        expect(c.size).to eq 1
      end
      it 'neg plus plus' do
        expect(cnpp).to be_a Clause3LiteralSet
        expect(cnpp.to_s).to eq "[-1, 2, 3]"
        expect(cnpp.size).to eq 1
        expect(cnpp.covers).to eq 0b11110111
      end
      it 'neg neg neg' do
        expect(cnnn).to be_a Clause3LiteralSet
        expect(cnnn.to_s).to eq "[-1, -2, -3]"
        expect(cnnn.size).to eq 1
      end
      it 'bad args' do
        expect{Clause3LiteralSet.new 1, 1, 3}.to raise_error Error
        expect{Clause3LiteralSet.new 1, 3, 1}.to raise_error Error
        expect{Clause3LiteralSet.new 1, 4, 4}.to raise_error Error
        # TODO: new 1, 1 and new 1, -1
      end
    end

    context 'union' do
      it 'ppp & pnp' do
        c = cppp.dup
        c.union! cpnp
        expect(c.to_s).to eq "[1, 2, 3], [1, -2, 3]"
      end
    end
    context 'simplify' do
      [:cppp, :cppn, :cpnp, :cpnn, :cppp, :cppn, :cpnp, :cpnn].each do |tgt|
        it tgt do
          cx = send tgt
          expect(cx.simplify).to be cx
        end
      end
      it 'ppp & ppn' do
        expect(cppp.dup.union!(cppn).simplify).to eq(cppx)
      end
      it 'ppp & ppn & pnn & npp & nnp' do
        cx = cppp.dup.union!(cppn, cpnn, cnpp, cnnp)
        result = cx.simplify
        expect(result[0]).to eq cppx
        expect(result[1]).to eq assign(3=>1)
      end
      it 'cppp, cppn, cpnp, cpnn, cnpp, cnpn, cnnn' do
        cx = cppp.dup
        cx.union!(cppn, cpnp, cpnn, cnpp, cnpn, cnnn)
        expect(cx.simplify).to eq assign(1=>true, 2=>true, 3=>false)
      end
      it 'cppp, cppn, cpnp, cpnn, cnnn' do
        cx = cppp.dup
        cx.union!(cppn, cpnp, cpnn, cnnn)
        expect(cx.simplify).to eq [cxnn, assign(1=>true)]
      end
    end

    context 'reduce' do
      it 'unchanged' do
        cx = cppp.dup
        expect(cx.reduce(Equivalences.new)).to be cx
      end
      it 'ppp && 2==1' do
        c = cppp.dup
        expect(c.reduce(assign(2=>1))).to eq cpxp
      end
      it 'ppp && 3==1' do
        c = cppp.dup
        expect(c.reduce(assign(3=>1))).to eq cppx
      end
      it 'ppp && 3==2' do
        c = cppp.dup
        #puts c.reduce(assign(3=>2)).inspect
        expect(c.reduce(assign(3=>2))).to eq cppx
      end
      it 'ppp && 3==2 && 2==1' do
        c = cppp.dup
        expect(c.reduce(assign(3=>2, 2=>1))).to eq assign(1=>true)
      end
      it 'case 1' do
        ec = assign(9=>true, 1=>true, 3=>true)
        c = Clause3LiteralSet.new -3, -7, -11
        expect(c.reduce(ec)).to eq Clause2LiteralSet.new(-7, -11)
      end
      it 'case 2' do
        ec = assign(9=>true, 1=>true, 3=>true, 8=>true, 7=>false, 11=>false,
                    15=>true)
        c = Clause3LiteralSet.new -2, -14, -15
        expect(c.reduce(ec)).to eq Clause2LiteralSet.new(-2, -14)
      end
    end

    context 'unify' do
      it 'merges cls' do
        result = Clause3LiteralSet.unify [cppx]
        expect(result).to eq cppx
        expect(cppx.to_s).to eq "[1, 2]"
      end
      it 'merges two cls' do
        result = Clause3LiteralSet.unify [cppx, cpnx]
        expect(result.to_s).to eq "[1, 2], [1, -2]"
        expect(cppx.to_s).to eq "[1, 2]"
      end
    end

    context 'subsume' do
      it 'all pairs' do
        all_cxxx.each do |c3|
          all_cxxx_binary.each do |c2|
            a, b = c2.to_a.first
            result = c3.subsumed_by c2
            puts "#{c3} & #{c2} => #{result}"
            ex = c3.to_a.delete_if{|c| c.index(a) && c.index(b)}.inspect
            if ex == '[]'
              expect(result).to eq true
            elsif ex == "[#{c3}]"
              expect(result).to be c3
            end
          end
        end
      end
      it 'ppp & ppx' do
        result = cppp.subsumed_by cppx
        puts result.inspect
      end
      it 'ppp & xpp' do
        result = cppp.subsumed_by cxpp
        puts result.inspect
        expect(result).to eq true
      end
      it '[-5, 7, -8] & [-5, 7] subsume ==> true' do
        c3 = Clause3LiteralSet.new -5, 7, -8
        c2 = Clause2LiteralSet.new -5, 7
        result = c3.subsumed_by c2
        expect(result).to eq true
      end
      it '[-5, -6, -7] & [-5, -6] subsume ==> true' do
        c3 = Clause3LiteralSet.new -5, -6, -7
        c2 = Clause2LiteralSet.new -5, -6
        result = c3.subsumed_by c2
        expect(result).to eq true
      end
      it '[3, -5, -7] &[-3, -5, 7] & [-5, 7] subsume ==> [3, -5, -7]' do
        c2 = Clause2LiteralSet.new -5, 7
        c3 = Clause3LiteralSet.new -3, -5, 7
        tgt = c3.dup
        puts "#{c3} & #{c2}"
        expect(c3.subsumed_by c2).to eq true
        foil = Clause3LiteralSet.new 3, -5, -7
        puts "#{foil} & #{c2}"
        expect(foil.subsumed_by c2).to be foil
        c3.union! foil
        puts "#{c3} & #{c2}"
        result = c3.subsumed_by c2
        puts result
        expect(result).to eq tgt
      end

      it 'produce contradiction' do
        c = cpnp.dup
        c.union! cpnp, cpnn, cnpp, cnpn, cnnp, cnnn
        result = c.subsumed_by cppx
        expect(result).to eq false
      end
    end

    context 'reduce' do
      let(:c3s){[cppp.dup, cppn.dup, cpnp.dup, cpnn.dup,
                 cnpp.dup, cnpn.dup, cnnp.dup, cnnn.dup]}
      let(:cz){ Clause3LiteralSet.new 10, 20, 30 }
      it 'unchanged' do
        ec = Equivalences.new
        c3s.each do |c|
          expect(c.reduce(ec)).to be c
        end
      end
      it 'decrease var 3' do
        c = cz.dup
        cx = c.reduce(assign(30=>25))
        expect(cx.to_s).to eq '[10, 20, 25]'
        expect(c.covers).to eq cx.covers
      end
      it 'decrease var 3 < var 2' do
        c = cz.dup
        cx = c.reduce(assign(30=>15))
        expect(cx.to_s).to eq '[10, 15, 20]'
        expect(c.covers).to eq cx.covers
      end
      it 'decrease var 3 < var 1' do
        c = cz.dup
        cx = c.reduce(assign(30=>5))
        expect(cx.to_s).to eq '[5, 10, 20]'
        expect(c.covers).to eq cx.covers
      end
      it 'decrease neg var 3' do
        c = cz.dup
        cx = c.reduce(assign(-30=>25))
        expect(cx.to_s).to eq '[10, 20, -25]'
      end
      it 'decrease neg var 3 < var 2' do
        c = cz.dup
        cx = c.reduce(assign(-30=>15))
        expect(cx.to_s).to eq '[10, -15, 20]'
      end
      it 'decrease neg var 3 < var 1' do
        c = cz.dup
        cx = c.reduce(assign(-30=>5))
        expect(cx.to_s).to eq '[-5, 10, 20]'
      end

      it 'decrease var 2' do
        c = cz.dup
        cx = c.reduce(assign(20=>15))
        expect(cx.to_s).to eq '[10, 15, 30]'
      end
      it 'decrease var 2 < var 1' do
        c = cz.dup
        cx = c.reduce(assign(20=>5))
        expect(cx.to_s).to eq '[5, 10, 30]'
      end
      it 'decrease neg var 2' do
        c = cz.dup
        cx = c.reduce(assign(-20=>15))
        expect(cx.to_s).to eq '[10, -15, 30]'
      end
      it 'decrease neg var 2 < var 1' do
        c = cz.dup
        cx = c.reduce(assign(20=>-5))
        expect(cx.to_s).to eq '[-5, 10, 30]'
      end
    end

    context 'each variable assignment' do
      it 'ppp' do
        rv = cppp.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>true}, {2=>true}, {3=>true}]
      end
      it 'ppn' do
        rv = cppn.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>true}, {2=>true}, {3=>false}]
      end
      it 'pnp' do
        rv = cpnp.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>true}, {2=>false}, {3=>true}]
      end
      it 'pnn' do
        rv = cpnn.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>true}, {2=>false}, {3=>false}]
      end
      it 'npp' do
        rv = cnpp.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>false}, {2=>true}, {3=>true}]
      end
      it 'npn' do
        rv = cnpn.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>false}, {2=>true}, {3=>false}]
      end
      it 'nnp' do
        rv = cnnp.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>false}, {2=>false}, {3=>true}]
      end
      it 'nnn' do
        rv = cnnn.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>false}, {2=>false}, {3=>false}]
      end
      it 'ppp && ppn' do
        c = cppp
        c.union!(cppn)
        rv = c.each_variable_assignment
        # puts rv.inspect
        expect(rv).to eq [{1=>true}, {2=>true}, {3=>true}, {3=>false}]
      end
    end

    def all_conjunctions k=0, seq=[], &block
      if k == 8
        yield seq
        return
      end
      (k...8).each do |choice|
        seq.push choice
        all_conjunctions choice + 1, seq, &block
        seq.pop
      end
    end

    def all_assignments k=0, seq=[], &block
      if k == 12
        yield seq
        return
      end
      (k...12).each do |choice|
        seq.push choice
        all_conjunctions choice + 1, seq, &block
        seq.pop
      end
    end

    def conjunction_clauses clauses
      clauses.inject(clauses.pop.dup){|sum, clause| sum.union! clause}
    end

    def conjunction_bitsets bitsets, log=false
      init = bitsets.pop
      puts "bitsets: %20s  %8s" % [init, init.bit_set.to_s(2)] if log
      rv = bitsets.inject(init.bit_set) do |bit_set, clause|
        puts "bitsets: %20s  %8s" % [clause, clause.bit_set.to_s(2)] if log
        bit_set & clause.bit_set
      end
      puts "bitsets: %20s  %8s" % ['', rv.to_s(2)] if log
      rv
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
      let(:c2s){[cppp.dup, cppn.dup, cpnp.dup, cpnn.dup,
                 cnpp.dup, cnpn.dup, cnnp.dup, cnnn.dup]}
      let(:bss){[[1,2,3],[1,2,-3],[1,-2,3],[1,-2,-3],
                 [-1,2,3],[-1,2,-3],[-1,-2,3],[-1,-2,-3]
                ].map{|a,b,c| OrBitSet.new a, b, c}}
      let(:ec2s){[{2=>1}, {-2=>1},
                  {3=>1}, {-3=>1},
                  {3=>2}, {-3=>2},
                  {1=>true}, {1=>false},
                  {2=>true}, {2=>false},
                  {3=>true}, {3=>false}].map{|x| assign **x}}
      let(:ebss){[EqBitSet.new(1, 2, 3), EqBitSet.new(1, -2, 3),
                  EqBitSet.new(1, 3, 3), EqBitSet.new(1, -3, 3),
                  EqBitSet.new(2, 3, 3), EqBitSet.new(2, -3, 3),
                  OrBitSet.new(1, nil, nil), OrBitSet.new(-1, nil, nil),
                  OrBitSet.new(2, nil, nil), OrBitSet.new(-2, nil, nil),
                  OrBitSet.new(3, nil, nil), OrBitSet.new(-3, nil, nil)]}

      it 'basic covers' do
        c2s.zip(bss) do |c, b|
          # puts "#{c} #{b}"
          expect(c.covers).to eq b.bit_set
        end
        ec2s.zip(ebss) do |e, b|
          # puts "#{e} #{b}"
          expect(hash_to_bs e).to eq b.bit_set
        end
      end

      def hash_to_bs h
        # raise "todo  #{h.inspect}"
        bs = 0b11111111
        return 0b0000000 if h == false
        h.keys.map(&:abs).union.sort.each do |a|
          b = h[a]
          case b
          when Integer
            bs = bs & EqBitSet.new(a, b, 3).bit_set
            # puts ">>> #{a} == #{b}"
          when true
            v = OrBitSet.new(a, nil, nil).bit_set
            bs = bs & v
            # puts ">>> #{a} == true  #{bs.to_s(2)} #{v.to_s(2)}"
          when false
            v = OrBitSet.new(-a, nil, nil).bit_set
            bs = bs & v
            # puts ">>> #{a} == false  #{bs.to_s(2)} #{v.to_s(2)}"
          end
        end
        bs
      end
      def bitset_from_binary elem, conj
        c = elem.covers
        ci = c
        c3 = 0
        if elem.var1 == conj.var1 &&
           elem.var2 == conj.var2
          c3 |= 0b00000011 if 0 < c & 0b0001
          c3 |= 0b00001100 if 0 < c & 0b0010
          c3 |= 0b00110000 if 0 < c & 0b0100
          c3 |= 0b11000000 if 0 < c & 0b1000
        elsif elem.var1 == conj.var1 &&
              elem.var2 == conj.var3
          c3 |= 0b00000101 if 0 < c & 0b0001
          c3 |= 0b00001010 if 0 < c & 0b0010
          c3 |= 0b01010000 if 0 < c & 0b0100
          c3 |= 0b10100000 if 0 < c & 0b1000
        elsif elem.var1 == conj.var2 &&
              elem.var2 == conj.var3
          c3 |= 0b00010001 if 0 < c & 0b0001
          c3 |= 0b00100010 if 0 < c & 0b0010
          c3 |= 0b01000100 if 0 < c & 0b0100
          c3 |= 0b10001000 if 0 < c & 0b1000
        else
          raise "TODO"
        end
        puts "c2:%8s    %8s" % [c3.to_s(2), ci.to_s(2)]
        c3
      end

      def bitset_from_array sconj, conj
        bs = 0b11111111
        sconj.each do |elem|
          puts elem
          case elem
          when Hash
            hbs = hash_to_bs elem
            puts "hb:%8s" % hbs.to_s(2)
            bs &= hbs
          when Clause2LiteralSet
            bs &= bitset_from_binary elem, conj
          when Clause3LiteralSet
            puts "c3:%8s" % elem.covers.to_s(2)
            bs &= elem.covers
          else
            raise Error.new("unknown element in #{sconj}")
          end
        end
        bs
      end

      before(:each) { @num = 0 }
      it 'conjuctions' do
        only = ENV["ONLY_NUM"] && ENV["ONLY_NUM"].to_i
        all_conjunctions do |seq|
          if only && @num + 1 != only
            @num += 1
            next
          end
          puts "#{'=' * 15} #{@num += 1} #{'=' * 15}"
          puts seq.inspect
          conj = conjunction_clauses seq.map{|idx| c2s[idx]}
          puts conj
          puts Clause3LiteralSet::SIMPLIFY[conj.set_vector].inspect
          puts "conj covers: #{conj.covers.to_s(2)}"
          sconj = conj.simplify
          puts sconj.inspect
          if sconj.is_a? Array
            puts sconj.map(&:to_s).join(", ")
          end
          bs_conj = conjunction_bitsets seq.map{|idx| bss[idx]}, true
          puts "bs_conj: %8s" % bs_conj.to_s(2)
          expect(conj.covers).to eq bs_conj
          # puts conj.covers.to_s(2)
          #puts Clause3LiteralSet.new(-2, -3, nil).covers.to_s(2)
          expect(bs_conj).to eq conj.covers
          case sconj
          when Array
            bs = bitset_from_array sconj, conj
            expect(bs_conj).to eq bs
          when Hash
            bs = hash_to_bs sconj
            # puts "bs_conj = %9s   bs = %9s" % [bs_conj.to_s(2), bs.to_s(2)]
            expect(bs_conj).to eq bs
          when true
            expect(bs_conj).to eq 0b11111111
          when false
            expect(bs_conj).to eq 0b00000000
          when Clause2LiteralSet
            bs = bitset_from_binary sconj, conj
            expect(bs_conj).to eq bs
          else
            puts "else: #{sconj.class} #{sconj}"
            expect(bs_conj).to eq sconj.covers
          end
        end
      end

      it 'conjuctions with assignments' do
        only = ENV["ONLY_NUM"] && ENV["ONLY_NUM"].to_i
        all_conjunctions do |cseq|
          expr_cls = conjunction_clauses cseq.map{|idx| c2s[idx]}
          expr_bs = conjunction_bitsets cseq.map{|idx| bss[idx]}
          expect(expr_bs).to eq expr_cls.covers
          all_assignments do |seq|
            if only && @num + 1 != only
              @num += 1
              next
            end
            puts "#{'=' * 15} #{@num += 1} #{'=' * 15}"
            puts "expr seq: #{cseq.inspect}"
            puts "expr_cls: #{expr_cls}"
            puts "expr_cls covers: '%8s'" % expr_cls.covers.to_s(2)
            puts "simplified expr: " \
                 "#{Clause3LiteralSet::SIMPLIFY[expr_cls.set_vector].inspect}"
            ax = seq.map{|idx| ec2s[idx]}
            puts "  assignments:  #{ax}"
            asgn_ec = conjunction_assignments ax
            puts "  asgn_ec   = #{asgn_ec}"
            asgn_ec_bs = hash_to_bs asgn_ec
            asgn_bs = conjunction_bitsets seq.map{|idx| ebss[idx]}
            puts "  expr_cls_cvr = %8s" % expr_cls.covers.to_s(2)
            puts "  expr_bs      = %8s" % expr_bs.to_s(2)
            puts "  asgn_ec_bs   = %8s" % asgn_ec_bs.to_s(2)
            puts "  asgn_bs      = %8s" % asgn_bs.to_s(2)
            target_bs = asgn_bs & expr_bs
            puts "  target_bs    = %8s" % target_bs.to_s(2)
            expect(asgn_ec_bs).to eq asgn_bs
            case asgn_ec
            when false
              expect(target_bs).to eq 0
            when true
              puts seq.map{|idx| ec2s[idx]}.map(&:to_s).inspect
              raise "cain #{seq.inspect}  #{eq_bs}"
            else
              # puts "  simplified conj = #{conj.simplify}"
              expr_final = expr_cls.reduce asgn_ec
              # puts "  final_conj = #{final_conj}"
              # puts "  bs_conj = %5s eq_bs = %5s " %
              #        [bs_conj.to_s(2), eq_bs.to_s(2)]
              case expr_final
              when false
                puts "  final     = false"
                expect(target_bs).to eq 0b0000
              when Hash
                bs = hash_to_bs expr_final
                # bs_conj is conj.convers
                f = bs & asgn_bs & expr_bs
                puts "  hash bs   = %8s #{expr_final}" % bs.to_s(2)
                puts "  asgn_bs   = %8s" % asgn_bs.to_s(2)
                puts "  expr_bs   = %8s" % expr_bs.to_s(2)
                puts "  final     = %8s" % f.to_s(2)
                expect(target_bs).to eq f
              when true
                puts "  final     = true"
                expect(target_bs).to be > 0
                # only one bit should be on for the true assignment
                z = target_bs
                z = z >> 1 while z > 1
                expect(z).to eq 1
              when Clause2LiteralSet
                bs = bitset_from_binary expr_final, expr_cls
                f = bs & asgn_bs & expr_bs
                puts "  final bs  = %8s #{expr_final}" % bs.to_s(2)
                puts "  asgn_bs   = %8s" % asgn_bs.to_s(2)
                puts "  expr_bs   = %8s" % expr_bs.to_s(2)
                puts "  final     = %8s" % f.to_s(2)
                expect(target_bs).to eq f
              else
                raise "wtf? #{expr_final.inspect}"
              end
            end
          end
        end
      end
    end


  end
end

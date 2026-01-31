require_relative 'problems'
require_relative 'clause_sets'

module Satx
  RSpec.describe Problem do
    let(:p3){ Problem.new 3 }
    before(:each) do
      p3.clear
    end
    context 'initializes' do
      it '3 variables' do
        expect(p3).to be_a Problem
        expect(p3.variables).to eq 3
        expect(p3.size).to eq 0
        expect(p3).to be_empty
      end
    end
    context 'add' do
      it 'one' do
        p3.add 1, 2
        expect(p3.size).to eq 1
      end
      it 'dup one' do
        p3.add 1, 2
        p3.add 1, 2
        expect(p3.size).to eq 1
      end
      it 'two' do
        p3.add 1, 2
        p3.add 3, 2
        expect(p3.size).to eq 2
        expect(p3.to_s).to eq "[[1, 2], [2, 3]]"
      end
      it 'random four' do
        p3.add_random_unique_clauses 4, 2
        expect(p3.size).to eq 4
        expect(eval(p3.to_s).union.size).to eq 4
      end
      it 'random 16' do
        p3.add_random_unique_clauses 16, 2
        expect(p3.size).to eq 16
        expect(eval(p3.to_s).union.size).to eq 16
      end
    end

    context 'brute force' do
      it 'simple' do
        p = Problem.new 2
        p.add [1,2]
        rv = p.brute_force
        expect(rv).to eq(assign 2=>true)
      end
      it 'simple near unsat' do
        p = Problem.new 2
        p.add [1, 2], [1, -2], [-1, 2]
        rv = p.brute_force
        expect(rv).to eq(assign 2=>true, 1=>true)
      end
      it 'simple unsat' do
        p = Problem.new 2
        p.add [1, 2], [1, -2], [-1, 2], [-1, -2]
        rv = p.brute_force
        expect(rv).to eq false
      end
    end

    context 'brute force' do
      it 'v = 16 c = 80 3CNF' do
        v = 4
        p = Problem.new v
        p.add_random_unique_clauses v * 5 , 3, Random.new(1234)
        puts p.clauses
        bf = p.brute_force
        unless bf == false
          puts "BF solution verification: #{p.verify(bf)}"
          puts p.failed.inspect
        end
        bfv = p.brute_force_vars
        puts '----'
        puts p.clauses
        puts bf
        puts bfv
        expect(bf && true).to eq(bfv && true)
      end
      it 'v = 32 c = 160 3CNF' do
        v = 24
        p = Problem.new v
        p.add_random_unique_clauses v * 5 , 3, Random.new(1234)
        t = Time.now
        bf = p.brute_force
        puts "elapsed #{Time.now - t} secs"
        expect(bf).to eq false
      end
    end

    def trial vars, clauses, valence, prng=nil
      p = Problem.new vars
      p.clear
      p.add_random_unique_clauses clauses, valence, prng
      compare p
    end
    def pretty h
      h.keys.map(&:abs).uniq!.sort.inject({}){|g, x| g[x] = h[x]; g[-x] = h[-x]; g}
    end
    def compare p
      begin
        puts "verifying with brute force"
        bf = p.brute_force
        if bf.is_a? Hash
          puts "brute force solution"
          puts pretty bf
          vbf = p.verify bf
          puts "VERIFY BF #{vbf}"
        end
        puts "verifying with brute force vars"
        bfv = p.brute_force_vars
        if bfv.is_a? Hash
          vbfv = p.verify bfv
          puts "VERIFY BFV #{vbfv}"
        end
      rescue Exception => e
        puts "failed on #{e}"
        puts p.clauses
      end
      if (bf && true) != (bfv && true)
        puts "    pnew #{p.clauses.to_a}"
      end
      expect(bf && true).to eq bfv && true
    end

    context 'brute force' do
      it 'many v=4 c=8' do
        v = 4
        1000.times do
          trial v, 2 * v, 3
        end
      end
      it 'many v=4 c=20' do
        v = 4
        100.times do
          trial v, 5 * v, 3
        end
      end
      it 'many v=8 c=40' do
        v = 8
        100.times do
          trial v, 5 * v, 3
        end
      end
      it 'many v=8 c=48' do
        v = 8
        100.times do
          trial v, 6 * v, 3
        end
      end
      it 'many v=16 c=80' do
        v = 16
        100.times do
          trial v, 5 * v, 3
        end
      end
      it 'Pv4c8k3sat001' do
        compare Pv4c8k3sat001
      end
      it 'Pv4c8k3unsat001' do
        compare Pv4c8k3unsat001
      end

    end

    context "validate problem examples" do
      Satx.constants.select{|x| /Pv\d+c\d+k\d.*sat\d+/ =~ x.to_s}.sort.each do |pname|
        it pname do
          p = Satx.const_get pname
          bf = p.brute_force
          if bf
            unless p.known_sat?
              puts pname
              puts "known: :sat"
            end
            if p.solution.nil? || bf != p.solution
              puts pname
              puts "solution: assign#{Equivalences[bf].to_assign}".
                     sub("{",'(').sub("}",')')
            end
            expect(p.known_sat?).to eq true
            expect(bf).to eq p.solution
          else
            unless p.known_unsat?
              puts pname
              puts "known: :unsat"
              puts "verify: #{p.verify p.solution}" if p.solution
            end
            expect(p.known_unsat?).to eq true
          end
        end
      end
    end
  end
end

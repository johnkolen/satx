require_relative 'clause_sets'
require_relative 'problems'

module Satx
  RSpec.describe Zipper do
    let(:p2sat){ Problem[[1, 2], [1, -2], [-1, 2]] }
    let(:p2unsat){ Problem[[1, 2], [1, -2], [-1, 2], [-1, -1]] }
    # let(:ss2sat){ SearchState.new p2sat }
    # let(:ss2unsat){ SearchState.new p2unsat }
    before(:each) do
    end
    context 'initializes' do
      it 'empty' do
        z = Zipper.new p2sat
        expect(z).to be_a Zipper
        expect(z.size).to eq 0
        expect(z).to be_empty
        expect(z.final).to be_empty
        expect(z.final.equivalences).to eq assign(2=>true, 1=>true)
      end
    end

    def trials n, clauses, valence
      n.times do
        p.clear
        p.add_random_unique_clauses clauses, valence
        begin
          z = Zipper.new p
        rescue Exception=>e
            puts "^^^^^^^^^ EXCEPTION ^^^^^^^^^^"
            puts p
            raise e
        end
        if p.brute_force
          unless z.final
            puts "^^^^^^^^^ SAT ^^^^^^^^^^"
            puts p
            puts z
          end
          expect(z.final).to be_truthy
        else
          ss = z.solve
          if z.final
            puts "^^^^^^^^^ UNSAT ^^^^^^^^^^"
            puts p
            puts z
          end
          expect(z.final).to eq false
        end
      end
    end

    def verify problem
      expect(problem.known?).to eq true
      z = Zipper.new problem
      # puts '$$$$$$$$$$$$$$$$$'
      # puts problem
      # puts problem.brute_force
      # puts z
      if problem.known_unsat?
        puts "known unsat"
        ss = z.solve
        # puts ss
        expect(z.final).to eq false
      else
        puts "known sat #{problem.solution}"
        expect(z.final).to be_truthy
      end
    end

    context '2-SAT 8 variables' do
      let(:p) { Problem.new 8 }
      it 'random 4 clauses' do
        trials 100000, 4, 2
      end
      it 'random 8 clauses' do
        trials 100000, 8, 2
      end
      it 'random 16 clauses' do
        trials 100000, 16, 2
      end
      it 'Pv8c8k2sat001' do
       verify Pv8c8k2sat001
      end
      it 'Pv8c8k2sat004' do
        verify Pv8c8k2sat004
      end
      it 'Pv8c16k2unsat001' do
        verify Pv8c16k2unsat001
      end
      it 'Pv8c16k2unsat002' do
        verify Pv8c16k2unsat002
      end
      it 'Pv8c8k2sat003' do
        verify Pv8c8k2sat003
      end

      it 'Pv8c16k2unsat003' do
        verify Pv8c16k2unsat003
      end
    end

    context '3-SAT 8 variables' do
      let(:p) { Problem.new 8 }
      it 'random 4 clauses' do
        trials 100, 4, 3
      end
      it 'random 8 clauses' do
        trials 100, 8, 3
      end
      it 'random 16 clauses' do
        trials 100, 16, 3
      end
      it 'Pv4c12k3sat001' do
        verify Pv4c12k3sat001
      end
    end
  end
end

require_relative 'search_states'

module Satx
  RSpec.describe SearchState do
    let(:p2sat){ Problem[[1, 2], [1, -2], [-1, 2]] }
    let(:p2unsat){ Problem[[1, 2], [1, -2], [-1, 2], [-1, -1]] }
    let(:ss2sat){ SearchState.new p2sat }
    let(:ss2unsat){ SearchState.new p2unsat }
    before(:each) do
    end
    context 'initializes' do
      it 'empty' do
        ss = SearchState.new Problem.new(3)
        expect(ss).to be_a SearchState
        expect(ss.size).to eq 0
        expect(ss).to be_empty
      end
      it 'p2sat' do
        ss = ss2sat
        expect(ss).to be_a SearchState
        expect(ss.size).to eq 3
        expect(ss).not_to be_empty
      end
    end

    context 'deletion' do
      it 'case 1' do
        ss1 = SearchState.new clauses: [[-5, -8], [2, -7]]
        ss1.delete Clause2LiteralSet.new(-5, -8)
        expect(ss1.clauses_to_a).to eq [[2, -7]]
      end
    end

    context 'subtraction' do
      it 'case 1' do
        ss1 = SearchState.new clauses: [[-5, -8], [2, -7]]
        ss2 = SearchState.new clauses: [[-5, -8], [3, 4]]
        ss1.subtract! ss2
        expect(ss1.clauses_to_a).to eq [[2, -7]]
      end
      it 'shared equivalences' do
        ss1 = SearchState.new(
          equivalences: {7=>4, -7=>-4, 3=>true, -3=>false})
        ss2 = SearchState.new(
          equivalences: {7=>4, -7=>-4, 8=>true, -8=>false})
        ss1.subtract! ss2
        expect(ss1.equivalences).to eq assign(3 => true)
      end
    end

    def ss_validate_simplify tgt
      ss = tgt.dup
      rv = ss.simplify
      if tgt.verify(ss.equivalences)
        expect(rv).to eq true
        expect(ss.unsatisfiable).to be_falsey
      else
        expect(rv).to eq false
        expect(ss.unsatisfiable).to be_truthy
      end
    end

    context 'simplify' do
      Satx.constants.select{|x| /SSv\d+c\d+k\d+/ =~ x.to_s}.sort.each do |test|
        it test do
          ss_validate_simplify Satx.const_get test
        end
      end
      context '3-SAT' do
        it 'case 1' do
          ss = SearchState.new(clauses: [[9, 13, 15], [1, 8, -11], [9, 13, -15]])
          result = ss.simplify
          puts result
          puts ss
        end
      end
    end

    context 'intersection' do
      it 'case 1' do
        ss1 = SearchState.new clauses: [[-5, -8], [2, -7]],
                          equivalences: {3=>1, -3=>-1, -1=>true, 1=>false,
                                         6=>true, -6=>false, -4=>true, 4=>false,
                                         -5=>true, 5=>false}
        ss2 = SearchState.new clauses: [[-5, -8], [2, -7], [1, 6], [-1, -4],
                                    [-1, 2], [4, -5], [1, -8]],
                              equivalences: {3=>-1, -3=>1}
        puts ss1.to_s
        puts ss2.to_s
        ss = ss1.intersection ss2
        puts ss.to_s
        expect(ss.clauses_to_a).to eq [[-5, -8], [2, -7]]
        expect(ss.equivalences).to be_empty
      end

      it 'case 2' do
        # While [[2,4],[2,-4]] and [[2,4]] have the same variables, they are not
        # identical. This interpretation may change later on, but for the zipper
        # it's ok.
        ss1 = SearchState.new(
          clauses:[[3, 4], [3, -4], [3, -6], [-1, -8], [-4, -5], [2, 4], [2, -4],
                   [-1, -4]],
          equivalences: {7=>4, -7=>-4})
        ss2 = SearchState.new(
          clauses:   [[3, 4], [3, -4], [3, -6], [-1, -8], [-4, -5], [2, 4], [-1, 4]],
          equivalences: {7=>-4, -7=>4})
        ss12 = ss1.intersection ss2
        ss21 = ss2.intersection ss1
        expect(ss12).to eq ss21
        expect(ss12.clauses_to_a).to eq [[3, 4], [3, -4], [3, -6], [-1, -8],
                                         [-4, -5]]
        expect(ss12.equivalences).to be_empty
      end
      it 'shared equivalences' do
        ss1 = SearchState.new(
          equivalences: {7=>4, -7=>-4, 3=>true, -3=>false})
        ss2 = SearchState.new(
          equivalences: {7=>4, -7=>-4, 8=>true, -8=>false})
        ss12 = ss1.intersection ss2
        expect(ss12.equivalences).to eq assign(7 => 4)
      end
    end
  end
end

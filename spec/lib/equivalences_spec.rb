module Satx
  RSpec.describe Equivalences do
    let(:ec){ Equivalences.new }
    it 'initializes' do
      expect(ec).to be_a Equivalences
      expect(ec.size).to be 0
    end

    context "assign" do
      it 'integer a < b' do
        ecx = ec.dup
        puts ecx.inspect
        rv = ecx.assign 1, 2
        expect(rv).to be true
        puts ecx.inspect
        expect(ecx[2]).to eq 1
        expect(ecx[-2]).to eq -1
      end
      it 'integer b < a' do
        ecx = ec.dup
        puts ecx.inspect
        rv = ecx.assign 2, 1
        expect(rv).to be true
        puts ecx.inspect
        expect(ecx[2]).to eq 1
        expect(ecx[-2]).to eq -1
      end
      it 'integer a == a' do
        ecx = ec.dup
        puts ecx.inspect
        rv = ecx.assign 2, 2
        expect(rv).to be true
        puts ecx.inspect
        expect(ecx[2]).to be_nil
        expect(ecx[-2]).to be_nil
      end
      it 'a = true' do
        ecx = ec.dup
        puts ecx.inspect
        rv = ecx.assign 1, true
        expect(rv).to be true
        puts ecx.inspect
        expect(ecx[1]).to eq true
        expect(ecx[-1]).to eq false
      end
      it 'a = false' do
        ecx = ec.dup
        puts ecx.inspect
        rv = ecx.assign 1, false
        expect(rv).to be true
        puts ecx.inspect
        expect(ecx[1]).to eq false
        expect(ecx[-1]).to eq true
      end

      it 'duplicate 2 = 1' do
        ecx = ec.dup
        rv = ecx.assign 2, 1
        puts ecx
        expect(ecx.size).to eq 2
        rv = ecx.assign 2, 1
        puts ecx
        expect(ecx.size).to eq 2
      end

      it 'duplicate 1 = 2' do
        ecx = ec.dup
        rv = ecx.assign 1, 2
        puts ecx
        expect(ecx.size).to eq 2
        rv = ecx.assign 1, 2
        puts ecx
        expect(ecx.size).to eq 2
      end

      context 'contradictions' do
        it 'direct true = false' do
          ecx = ec.dup
          rv = ecx.assign 1, true
          puts ecx.inspect
          rv = ecx.assign 1, false
          expect(rv).to be false
          puts ecx.inspect
          # ecx unchanged
          expect(ecx[1]).to eq true
          expect(ecx[-1]).to eq false
        end
        it 'transitive' do
          ecx = ec.dup
          rv = ecx.assign 5, 3
          rv = ecx.assign 3, 1
          rv = ecx.assign 4, true
          rv = ecx.assign 8, -3
          rv = ecx.assign 6, -1
          expect(rv).to eq true
          rv = ecx.assign 6, 3
          expect(rv).to eq false
        end
      end
    end
    it 'transitive' do
      ecx = ec.dup
      expect(ecx[3]).to be_nil
      ecx[3] = 2
      expect(ecx[3]).to eq 2
      ecx[2] = 1
      expect(ecx[2]).to eq 1
      puts ecx.inspect
      expect(ecx[2]).to eq 1
      expect(ecx[3]).to eq 1
      expect(ecx[4]).to be_nil
      ecx[1] = true
      puts ecx.inspect
      expect(ecx[3]).to eq true
      expect(ecx[2]).to eq true
    end
    it 'bad transitive' do
      ecx = Equivalences.new
      {3=>2, -3=>-2, 2=>1, -2=>-1, 1=>true, -1=>false, 8=>true,
       -8=>false, -5=>true, 5=>false, 4=>true, -4=>false, 7=>true,
       -7=>false}.each do |k, v|
        ecx[k] = v
      end
      expect(ecx[-2]).to eq false
    end

    context "subtraction" do
      it 'case 1' do
        e1 = Equivalences[{7=>4, -7=>-4, 3=>true, -3=>false}]
        expect(e1.size).to eq 4
        e2 = Equivalences[{7=>4, -7=>-4, 8=>true, -8=>false}]
        e1.subtract! e2
        expect(e1).to eq assign(3 => true)
      end
    end
    context "merge" do
      it 'case 1' do
        e1 = Equivalences[{6=>4, -6=>-4, 1=>false, -1=>true, 3=>false, -3=>true}]
        e2 = Equivalences[{8=>1, -8=>-1}]
        e1.merge! e2
        expect(e1).to eq assign(6=>4, 1=>false, 3=>false, 8=>1)
      end
      it 'case 2' do
        e1 = Equivalences.new
        e1.merge!({1=>2, -1=>-2})
        expect(e1[2]).to eq 1
        expect(e1[-2]).to eq -1
        expect(e1.size).to eq 2
      end
    end
  end
end

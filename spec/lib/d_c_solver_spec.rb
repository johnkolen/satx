require_relative 'problems'

module Satx
  RSpec.describe DCSolver do
    context 'initializes' do
      it 'empty' do
        dcs = DCSolver.new Pv4c12k3sat001
        puts dcs.sizes.inspect
      end
    end
    def trial vars, clauses, valence, prng=nil
      p = Problem.new vars
      p.clear
      p.add_random_unique_clauses clauses, valence, prng
      search p, prng
    end
    def search p, prng=nil
      dcs = DCSolver.new p
      begin
        puts "verifying with brute force"
        bf = p.brute_force
        if bf.is_a? Hash
          vbf = p.verify bf
          puts "verify bf #{vbf}"
        end
        puts "verifying with brute force vars"
        bfv = p.brute_force_vars
        if bfv.is_a? Hash
          vbfv = p.verify bfv
          puts "verify bfv #{vbfv}"
        end
      rescue Exception => e
        puts "failed on #{e}"
        puts p.clauses
      end
      if (bf && true) != (bfv && true)
        puts p.clauses
      end
      expect(bf && true).to eq bfv && true
      s = dcs.sizes
      puts s.inspect
      #puts "assigns: #{s[2] / 4} of #{vars / 2}"
      #puts "binary: #{s[1] / 2} of #{vars / 2}"
      result = dcs.solve
      puts "trial: #{result}"
      puts "bf #{bf}"
      if result == :failed
        puts "^^^^^^^^^^^^^^ #{bf ? "" : "UN"}SAT ^^^^^^^^^^^^"
        puts p.clauses.inspect
      elsif result == false
        if bf
          puts "^^^^^^^^^^^^^^ #{bf ? "" : "UN"}SAT ^^^^^^^^^^^^"
          puts "pnew #{p.clauses.inspect.gsub('[[','[').gsub(']]',']')},"
          puts "known: #{bf ? "" : "un"}sat,"
          puts "solution: #{Equivalences[**bf].to_assign}"
        end
        expect(bf).to eq false
      else
        expect(bf && true).to eq true
      end
    end
    it 'large problem' do
      v = 8
      trial v, 2 * v, 3, Random.new(1001)
    end
    it 'many poroblems' do
      v = 8
      1000.times do
        trial v, 5 * v, 3
      end
    end

    context 'verify_a210' do
      it 'case 1 ' do
        dc = DCSolver.new Pv8c40k3sat002
        rv = dc.verify_a210 assign(1=>false, 2=>false, 3=>false, 4=>false)
        puts rv
        expect(rv).to be_truthy
      end
    end

    context "problem examples" do
      Satx.constants.select{|x| /Pv\d+c\d+k\d.*sat\d+/ =~ x.to_s}.sort.each do |pname|
        it pname do
          search Satx.const_get pname
        end
      end
    end
  end
end

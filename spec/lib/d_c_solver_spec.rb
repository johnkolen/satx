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
      if result == :failed
        puts "^^^^^^^^^^^^^^ #{bf ? "" : "UN"}SAT ^^^^^^^^^^^^"
        puts p.clauses.inspect
      elsif result == false
        if bf
          puts "^^^^^^^^^^^^^^ UNSAT ^^^^^^^^^^^^"
          puts p.clauses.inspect
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
    it 'many problems' do
      v = 8
      1000.times do
        trial v, 5 * v, 3
      end
    end

    it 'Pv8c40k3unsat001' do
      search Pv8c40k3unsat001
    end
  end
end

module Satx
  RSpec.describe Simulator do
    it '8 variables k=3 alpha=4' do
      s = Simulator.new
      s.create_uniform_sampled 8, 3, 4
      puts "simulating"
      s.simulate_max_occurence
    end
  end
end

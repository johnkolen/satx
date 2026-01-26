# frozen_string_literal: true

require "satx"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def assign **vars
  neg = {}
  vars.each do |u,v|
    if v.is_a? Integer
      neg[-u] = -v
    else
      neg[-u] = !v
    end
  end
  Satx::Equivalences[vars.merge neg]
end

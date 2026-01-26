# frozen_string_literal: true

module Satx
  class Error < StandardError; end
  # Your code goes here...
  VARIABLE_BITS = 10
  VARIABLE_MASK = 2**VARIABLE_BITS - 1
end

require_relative "satx/version"
require_relative "satx/noisy"
require_relative "satx/clause_literal_set"
require_relative "satx/clause2_literal_set"
require_relative "satx/clause3_literal_set"
require_relative "satx/clause_set"
require_relative "satx/equivalences"
require_relative "satx/problem"
require_relative "satx/search_state"

require_relative "satx/zipper"
require_relative "satx/d_c_solver"

require_relative "satx/bitsets"
require_relative "satx/simulator"

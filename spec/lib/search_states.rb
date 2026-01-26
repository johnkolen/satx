require_relative 'problems'

module Satx
  def self.ssnew **opts
    SearchState.new **opts
  end

  SSv8c12k2_001 =
    ssnew clauses: [[4, 8], [-4, 8], [2, 4], [2, -4], [-2, 4], [1, 4], [-1, -4],
                    [-5, -8], [2, 7], [-4, -5], [4, 7], [1, -3], [1, -8], [3, -4]],
          equivalences: {6=>4, -6=>-4}
  SSv8c12k2_002 =
    ssnew clauses: [[4, 8], [-4, 8], [2, 4], [2, -4], [-2, 4], [1, 4], [-1, -4],
                    [-5, -8], [2, 7], [-4, -5], [4, 7], [1, -3], [1, -8], [3, -4]],
          equivalences: {6=>4, -6=>-4}
  SSv8c12k2_003 =
    ssnew clauses:   [[4, 7], [3, -4]],
          equivalences: {6=>4, -6=>-4, 1=>false, -1=>true, 3=>false, -3=>true,
                         8=>1, -8=>-1, 5=>false, -5=>true, 4=>false, -4=>true,
                         7=>true, -7=>false, 2=>true, -2=>false}
  SSv8c12k2_004 =
    ssnew clauses: [[4, 8], [-4, 8], [2, 4], [2, -4], [-2, 4], [1, 4], [-1, -4],
                    [-5, -8], [2, 7], [-4, -5], [4, 7], [1, -3], [1, -8], [3, -4]],
          equivalences: {6=>4, -6=>-4, 1=>false, -1=>true, 3=>false, -3=>true}

end

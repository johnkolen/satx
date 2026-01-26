module Satx
  class ClauseLiteralSet
    def equiv a, b
      ec = Equivalences.new
      raise "wtf?" unless ec.assign a, b
      ec
    end
  end
end

module Satx
  module Noisy
    def noisy msg=nil, &block
      @noisy ||= ENV["NOISY"].is_a? String
      return unless @noisy
      puts "#{self.class}: #{msg}" if msg
      puts "#{self.class}: #{yield}" if block_given?
    end
  end
end

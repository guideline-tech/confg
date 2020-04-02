# frozen_string_literal: true

require "erb"

module Confg
  class ErbContext

    def evaluate(raw_content)
      ::ERB.new(raw_content).result(binding)
    end

  end
end

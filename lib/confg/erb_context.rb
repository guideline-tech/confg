require 'yaml'
require 'erb'

module Confg
  class ErbContext

    def evaluate(raw_content)
      raw_content = ERB.new(raw_content).result(binding)
      YAML.load(raw_content)
    end

  end
end

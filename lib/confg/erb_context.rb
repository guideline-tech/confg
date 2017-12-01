require 'yaml'
require 'erb'

module Confg
  class ErbContext

    def evaluate(raw_content)
      raw_content = ERB.new(raw_content).result(binding)
      puts raw_content
      YAML.load(raw_content)
    end

  end
end

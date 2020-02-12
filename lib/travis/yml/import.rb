require 'travis/yml/import/configs'
require 'travis/yml/import/errors'

module Travis
  module Yml
    module Import
      include Errors

      def self.new(*args)
        Configs.new(*args)
      end
    end
  end
end

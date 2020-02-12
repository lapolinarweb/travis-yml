require 'travis/yml/import/imports'

module Travis
  module Yml
    module Import
      class Ctx < Struct.new(:opts)
        def imports
          @imports ||= Imports.new(self)
        end

        def repos
          @repos ||= Repos.new(opts[:token])
        end

        def data
          opts[:data] || {}
        end
      end
    end
  end
end

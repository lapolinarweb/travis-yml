require 'travis/yml/import/config/base'

module Travis
  module Yml
    module Import
      module Config
        class Api < Struct.new(:ctx, :repo, :ref, :raw, :mode)
          include Base, Memoize

          attr_reader :config, :parent, :path

          def load(&block)
            super
            @config = parse(raw)
            store
            loaded
          end

          def imports
            return [] if mode == :replace
            imports = super
            imports.any? ? imports : [travis_yml]
          end
          memoize :imports

          def source
            'api'
          end

          def mode
            super || config.delete(:mode)
          end

          def to_s
            source
          end

          private

            def import
              { source: source }
            end

            def travis_yml
              Config.travis_yml(ctx, self, repo.slug, ref, mode)
            end
        end
      end
    end
  end
end

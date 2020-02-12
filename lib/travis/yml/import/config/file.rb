require 'travis/yml/import/github/content'
require 'travis/yml/import/config/base'

module Travis
  module Yml
    module Import
      module Config
        class File < Struct.new(:ctx, :parent, :import)
          include Base

          attr_reader :path, :ref, :raw, :config

          def load(&block)
            super
            _, @path, @ref = expand(source)
            @raw = fetch
            @config = parse(raw)
            store
            loaded
          end

          def repo
            @repo ||= ctx.repos[Ref.new(source).repo || parent.repo.slug]
          end

          def source
            import[:source]
          end

          def mode
            import[:mode]&.to_sym
          end

          def to_s
            "#{repo.slug}:#{path}@#{ref}"
          end

          private

            def expand(source)
              ref = local? ? parent&.ref : repo.default_branch
              ref = Ref.new(source, repo: repo.slug, ref: ref, path: parent&.path)
              ref.parts
            end

            def fetch
              Github::Content.new(repo.slug, path, ref, token).content
            rescue Github::Error => e
              handle_error(e)
              {}
            end

            def handle_error(e)
              unauthorized if e.status == 401
              github_error if e.status != 404
              # not_found unless travis_yml? && request.api?  # TODO
            end

            def token
              opts[:token]
            end
        end
      end
    end
  end
end

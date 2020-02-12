# require 'travis/gatekeeper/model/request/configs/encrypt'
# require 'travis/gatekeeper/helpers/metrics'
# require 'travis/yml/import/filter'
# require 'travis/yml/import/source/api'
require 'travis/yml/import/model/repos'
require 'travis/yml/import/config/api'
require 'travis/yml/import/config/file'
require 'travis/yml/import/ctx'

module Travis
  module Yml
    module Import
      class Configs < Struct.new(:repo, :type, :ref, :raw, :mode, :opts)
        include Enumerable #, Helpers::Context, Helpers::Metrics, Encrypt

        attr_reader :configs, :config

        # - we need to supply both Travis CI and GitHub API tokens (GitHub contents, Travis CI repo settings)
        # - port all specs
        # - reencrypt api endpoint
        # - reencrypt if config is remote, private, and has secure vars
        # - add metrics

        def load
          fetch
          compact
          merge
          reencrypt
          # filter
        end

        def to_h
          { raw_configs: configs.map(&:to_h), config: config, msgs: msgs }
        end

        def to_a
          configs
        end

        def msgs
          @msgs ||= []
        end

        def each(&block)
          configs.each(&block)
        end

        def to_s
          map(&:to_s).join(', ')
        end

        private

          def fetch
            imports.load(api? ? api : travis_yml)
            @configs = imports.configs
            msgs.concat(imports.msgs)
          end

          def merge
            doc = Yml.load(configs.map(&:part))
            @config = doc.serialize
            msgs.concat(doc.msgs)
          end

          def imports
            ctx.imports
          end

          def compact
            configs.reject!(&:empty?)
          end

          def reencrypt
            keys = configs.select(&:reencrypt?).map(&:repo).uniq.map(&:key)
            @config = repo.reencrypt(config, keys) if keys.any?
          end

          # def filter
          #   @config, msgs = Filter.new(request, config).apply
          #   @msgs.concat(msgs)
          # end

          def travis_yml
            Config.travis_yml(ctx, nil, repo.slug, ref, mode)
          end

          def api
            Config::Api.new(ctx, repo, ref, raw, mode)
          end

          def api?
            type == 'api'
          end

          def ctx
            @ctx ||= Ctx.new(opts).tap { |ctx| ctx.repos[repo.slug] = repo }
          end

          def repo
            @repo ||= Repo.new(super)
          end
      end
    end
  end
end

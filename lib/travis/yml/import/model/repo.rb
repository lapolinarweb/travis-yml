require 'travis/yml/import/model/config'
require 'travis/yml/import/model/key'

module Travis
  module Yml
    module Import
      class Repo < Struct.new(:attrs)
        def owner_name
          @owner_name ||= slug.split('/').first
        end

        def slug
          attrs[:slug]
        end

        def private?
          attrs[:private]
        end

        def public?
          !private?
        end

        def default_branch
          attrs[:default_branch] || 'master'
        end

        def allow_config_imports?
          attrs[:allow_config_imports]
        end

        def key
          Key.new # TODO
        end

        def reencrypt(config, keys)
          encrypt(keys.inject(config) { |config, key| decrypt(config, key) })
        end

        def decrypt(config, key)
          Model::Config.new(config, key).decrypt
        end

        def encrypt(config)
          Model::Config.new(config, key).encrypt
        end

        def ==(other)
          slug == other.slug
        end
      end
    end
  end
end

require 'travis/yml/helper/obj'
require 'travis/yml/helper/synchronize'
require 'travis/yml/import/model/repo'
require 'travis/yml/import/github/repo'
require 'travis/yml/import/travis/settings'

module Travis
  module Yml
    module Import
      class Repos
        include Synchronize

        attr_reader :repos, :token, :mutex, :mutexes

        def initialize(token)
          @repos = {}
          @token = token
          @mutex = Mutex.new
          @mutexes = {}
        end

        def [](slug)
          mutex_for(slug).synchronize do
            return repos[slug] if repos.key?(slug)
            repos[slug] = Repo.new(fetch(slug))
          end
        end

        def []=(slug, repo)
          repos[slug] = repo
        end

        def fetch(slug)
          repo = Github::Repo.new(slug, token).fetch
          repo[:allow_config_imports] = allow_config_imports?(repo)
          repo
        end

        def allow_config_imports?(repo)
          return true unless repo[:private]
          Travis::Settings.new(repo[:slug], token).allow_config_imports?
        end

        def mutex_for(slug)
          mutexes[slug] ||= Mutex.new
        end
        synchronize :mutex
      end
    end
  end
end

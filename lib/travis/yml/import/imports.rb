require 'forwardable'
require 'travis/yml/helper/condition'
require 'travis/yml/helper/lock'
require 'travis/yml/helper/synchronize'
require 'travis/yml/import/errors'
require 'travis/yml/import/model/repos'

Thread::abort_on_exception = true

module Travis
  module Yml
    module Import
      class Imports
        extend Forwardable
        include Errors, Synchronize

        def_delegators :config, :repo, :ref, :path

        attr_reader :ctx, :config, :sources, :lock, :mutex, :queue, :threads

        def initialize(ctx)
          @ctx = ctx
          @sources = []
          @lock = Lock.new
          @queue = Queue.new
          @mutex = Mutex.new
          @threads = []
        end

        def load(config)
          @config = config
          config.load(&method(:on_load))
          lock.wait unless config.loaded?
        end

        def configs
          config.flatten
        end

        def size
          sources.size
        end

        def msgs
          @msgs ||= []
        end

        def store(config)
          return unless import?(config)
          sources << config.to_s
          push(config)
        end
        synchronize :store

        private

          def push(config)
            config.imports.each do |config|
              threads << Thread.new(&method(:process))
              queue << config
            end
          end

          def process
            config = queue.pop
            config.load
          end

          def on_load
            too_many_imports(size, max_imports) if limit?
            configs.each(&:validate)
            lock.release
          end

          def import?(config)
            return true if unique?(config.to_s) && !limit? && config.matches?
            config.skip
            false
          end

          def limit?
            size >= max_imports
          end

          def unique?(source)
            !sources.include?(source)
          end

          def max_imports
            Yml.config[:imports][:max]
          end
      end
    end
  end
end

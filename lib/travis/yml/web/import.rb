require 'oj'
require 'travis/yml/web/helpers'

module Travis
  module Yml
    module Web
      class Import < Sinatra::Base
        include Helpers

        post '/import' do
          status 200
          json configs.to_h
        rescue => e
          puts e.message, e.backtrace[0..20]
        rescue Oj::Error, EncodingError => e
          status 400
          error(e)
        end

        private

          def configs
            Travis::Yml.import(*args, opts).tap(&:load)
          end

          def args
            data.values_at(:repo, :type, :ref, :config, :mode)
          end

          def data
            Oj.load(request_body, symbol_keys: true, mode: :strict, empty_string: false)
          end

          def request_body
            request.body.read.tap { request.body.rewind }
          end

          def opts
            keys = OPTS.keys.map(&:to_s) & params.keys
            opts = symbolize(keys.map { |key| [key, params[key.to_s] == 'true'] }.to_h)
            # TODO merge in tokens from headers
            opts
          end

          def symbolize(hash)
            hash.map { |key, value| [key.to_sym, value] }.to_h
          end
      end
    end
  end
end

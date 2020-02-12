require 'faraday_middleware'

module Travis
  module Yml
    module Import
      module Travis
        class Client < Struct.new(:token)
          HEADERS  = {
            'User-Agent': 'Travis-CI-Yml/Faraday',
            'Travis-API-Version': '3',
          }

          def get(path, opts = {})
            client.get(path, opts)
          end

          def client
            # TODO
            # config.travis.api_url
            Faraday.new(url: 'https://api-staging.travis-ci.org', headers: HEADERS, ssl: ssl_options) do |c|
              # c.response :logger
              c.use FaradayMiddleware::FollowRedirects
              # c.request  :authorization, :token, token.to_s if token
              c.request  :retry
              c.response :raise_error
              c.adapter  :net_http
            end
          end

          def headers
            headers = HEADERS
            headers['Authorization'] = "token #{token}"
            headers
          end

          def ssl_options
            # TODO
            # compact(config.ssl.to_h.merge(config.github.ssl || {}))
            {}
          end
        end
      end
    end
  end
end

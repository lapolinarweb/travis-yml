require 'faraday_middleware'

module Travis
  module Yml
    module Import
      module Github
        class Client < Struct.new(:token)
          HEADERS  = {
            'User-Agent': 'Travis-CI-Yml/Faraday',
            'Accept': 'application/vnd.github.v3+json',
            'Accept-Charset': 'utf-8'
          }

          def get(path, opts = {})
            client.get(path, opts)
          end

          def client
            # TODO
            # config.github.api_url
            Faraday.new(url: 'https://api.github.com', headers: HEADERS, ssl: ssl_options) do |c|
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
            headers['Authorization'] = basic_auth
            headers
          end

          def basic_auth
            'Basic %s' % Base64.encode64("#{client_id}:#{client_secret}").gsub("\n", "")
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

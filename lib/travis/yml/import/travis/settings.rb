require 'travis/yml/import/travis/client'
require 'travis/yml/helper/obj'

module Travis
  module Yml
    module Import
      module Travis
        class Settings < Struct.new(:slug, :token)
          include Helper::Obj

          def allow_config_imports?
            settings[:allow_config_imports]
          end

          def settings
            @settings ||= fetch
          end

          private

            # TODO error handling
            def fetch
              resp = client.get("repo/#{slug.sub('/', '%2F')}/settings")
              attrs = Oj.load(resp.body)
              symbolize(attrs)
            end

            def map(attrs)
              {
                slug: attrs['full_name'],
                private: attrs['private'],
                default_branch: attrs['default_branch'],
                token: token
              }
            end

            def client
              Client.new(token)
            end
        end
      end
    end
  end
end

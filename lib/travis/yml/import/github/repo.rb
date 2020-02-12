require 'travis/yml/helper/obj'
require 'travis/yml/import/github/client'

module Travis
  module Yml
    module Import
      module Github
        class Repo < Struct.new(:slug, :token)
          def fetch
            resp = client.get("repos/#{slug}")
            # TODO error handling
            attrs = Oj.load(resp.body)
            map(attrs)
          end

          private

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

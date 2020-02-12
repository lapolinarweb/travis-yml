require 'base64'
require 'travis/yml/import/github/client'

module Travis
  module Yml
    module Import
      module Github
        Error = Class.new(StandardError)

        class Content < Struct.new(:slug, :path, :ref, :token)
          include Base64

          def content
            @content ||= normalize(fetch)
          end

          private

            def fetch
              resp = client.get("repos/#{slug}/contents/#{path}", ref: ref)
              data = Oj.load(resp.body)
              decode64(data['content'])
            rescue TypeError => e
              nil
            end

            NBSP = "\xC2\xA0".force_encoding('binary')

            def normalize(str)
              str = normalize_nbsp(str)
              str = remove_utf8_bom(str)
              str
            end

            def normalize_nbsp(str)
              str.gsub(/^(#{NBSP})+/) { |match| match.gsub(NBSP, ' ') }
            end

            def remove_utf8_bom(str)
              str.force_encoding('UTF-8').sub /^\xEF\xBB\xBF/, ''
            end

            def client
              Client.new
            end
        end
      end
    end
  end
end

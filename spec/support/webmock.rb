module Spec
  module Support
    module Webmock
      def stub_content(repo, path, config)
        url = %r(https://api.github.com/repos/#{repo}/contents/#{path})
        body = JSON.dump(content: Base64.encode64(config))
        stub_request(:get, url).to_return(body: body)
      end

      def stub_repo(slug, attrs)
        url = "https://api.github.com/repos/#{slug}"
        stub_request(:get, url).to_return(body: JSON.dump(attrs.merge(full_name: slug)))
      end

      def stub_settings(slug, attrs)
        url = "https://api-staging.travis-ci.org/repo/#{slug.sub('/', '%2F')}/settings"
        stub_request(:get, url).to_return(body: JSON.dump(attrs))
      end
    end
  end
end



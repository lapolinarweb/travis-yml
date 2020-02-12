# frozen_string_literal: true
require 'travis/config'

module Travis
  module Yml
    class Config < Travis::Config
      define auth_keys:  ['abc123'],
             enterprise: ENV['TRAVIS_ENTERPRISE'] || false,
             github:     { api_url: 'https://github.com' },
             travis:     { api_url: 'https://travis-ci.com' },
             imports:    { max: 25 },
             metrics:    { reporter: 'librato' }

      def metrics
        # TODO fix travis-metrics ...
        super.to_h.merge(librato: librato.to_h.merge(source: librato_source), graphite: graphite)
      end
    end
  end
end

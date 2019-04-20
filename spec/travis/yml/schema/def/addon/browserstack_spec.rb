describe Travis::Yml::Schema::Def::Addon::Browserstack, 'structure' do
  describe 'definitions' do
    subject { Travis::Yml.schema[:definitions][:addon][:browserstack] }

    # it { puts JSON.pretty_generate(subject) }

    it do
      should eq(
        '$id': :browserstack,
        title: 'Browserstack',
        type: :object,
        properties: {
          username: {
            type: :string
          },
          access_key: {
            '$ref': '#/definitions/secure'
          },
          forcelocal: {
            type: :boolean
          },
          only: {
            type: :string
          },
          proxyHost: {
            type: :string
          },
          proxyPort: {
            type: :string
          },
          proxyUser: {
            type: :string
          },
          proxyPass: {
            '$ref': '#/definitions/secure'
          }
        },
        additionalProperties: false,
        normal: true
      )
    end
  end

  # describe 'schema' do
  #   subject { described_class.new.schema }
  #
  #   it do
  #     should eq(
  #       '$ref': '#/definitions/addon/browserstack'
  #     )
  #   end
  # end
end
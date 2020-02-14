describe Travis::Yml::Import::Configs do
  let(:repo)    { { slug: 'travis-ci/travis-yml', default_branch: 'master' } }
  let(:type)    { 'push' }
  let(:ref)     { 'ref' }
  let(:config)  { nil }
  let(:data)    { nil }
  let(:mode)    { nil }
  let(:opts)    { { token: 'token', data: data } }
  let(:configs) { described_class.new(repo, type, ref, config, mode, opts) }
  let(:msgs)    { subject.msgs }

  let(:travis_yml) { 'import: one/one.yml' }
  let(:one_yml)    { 'script: ./one' }
  let(:two_yml)    { 'script: ./two' }

  before { stub_content(repo[:slug], '.travis.yml', travis_yml) }
  before { stub_content(repo[:slug], 'one/one.yml', one_yml) }
  before { stub_content(repo[:slug], 'one/two.yml', two_yml) }

  subject { configs.tap(&:load) }

  def self.imports(sources)
    it { expect(subject.map(&:to_s)).to eq sources }
  end

  describe 'push' do
    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      travis-ci/travis-yml:one/one.yml@ref
    )
  end

  describe 'api' do
    let(:type) { 'api' }

    describe 'by default (imports .travis.yml)' do
      let(:config) { 'script: ./api' }

      imports %w(
        api
        travis-ci/travis-yml:.travis.yml@ref
        travis-ci/travis-yml:one/one.yml@ref
      )
    end

    describe 'given imports (skips .travis.yml)' do
      let(:config) { 'import: one/one.yml' }

      imports %w(
        api
        travis-ci/travis-yml:one/one.yml@ref
      )
    end

    describe 'merge_mode replace (skips all)' do
      let(:config) { 'import: one/one.yml' }
      let(:mode) { :replace }

      imports %w(
        api
      )
    end
  end

  describe 'remote import' do
    let(:travis_yml) { 'import: other/other:one.yml' }

    before { stub_content('other/other', 'one.yml', one_yml) }
    before { stub_content('other/other', 'two.yml', one_yml) }
    before { stub_repo('other/other', private: false, default_branch: 'default') }

    describe "defaults the repo to the parent config's repo" do
      let(:one_yml) { 'import: two.yml@master' }

      imports %w(
        travis-ci/travis-yml:.travis.yml@ref
        other/other:one.yml@default
        other/other:two.yml@master
      )
    end

    describe 'defaults the ref to the repo default branch' do
      let(:one_yml) { 'import: other/other:two.yml' }

      imports %w(
        travis-ci/travis-yml:.travis.yml@ref
        other/other:one.yml@default
        other/other:two.yml@default
      )
    end
  end

  describe 'reencrypt' do
    let(:repo) { { slug: 'travis-ci/travis-yml', private: true } }
    before { stub_repo('travis-ci/other', private: private, default_branch: 'default') }
    before { stub_content('travis-ci/other', 'one.yml', one_yml) }
    before { stub_settings('travis-ci/other', allow_config_imports: true) }

    describe 'local config' do
      let(:private) { false }
      let(:travis_yml) { 'import: one/one.yml' }
    end

    describe 'remote, public config' do
      let(:private) { false }
      let(:travis_yml) { 'import: travis-ci/other:one.yml' }
    end

    describe 'remote, private config without secure vars' do
      let(:private) { true }
      let(:travis_yml) { 'import: travis-ci/other:one.yml' }
    end

    describe 'remote, private config with secure vars' do
      let(:private) { true }
      let(:travis_yml) { 'import: travis-ci/other:one.yml' }
      let(:one_yml) { "env:\n  - secure: str" }
      it { subject }
    end
  end

  describe 'expanding relative paths (local)' do
    let(:one_yml) { 'import: ./two.yml' }

    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      travis-ci/travis-yml:one/one.yml@ref
      travis-ci/travis-yml:one/two.yml@ref
    )
  end

  describe 'expanding relative paths (remote)' do
    let(:travis_yml) { 'import: other/other:one/one.yml' }
    let(:one_yml) { 'import: ./two.yml' }

    before { stub_content('other/other', 'one/one.yml', one_yml) }
    before { stub_content('other/other', 'one/two.yml', two_yml) }
    before { stub_repo('other/other', default_branch: 'default') }

    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      other/other:one/one.yml@default
      other/other:one/two.yml@default
    )
  end

  describe 'given a merge_mode' do
    let(:travis_yml) do
      <<~yml
        import:
          - source: one/one.yml
            mode: merge
      yml
    end

    let(:one_yml) do
      <<~yml
        import:
          - source: one/two.yml
            mode: deep_merge
      yml
    end

    it { expect(subject.map(&:merge_mode)).to eq [nil, :merge, :deep_merge] }
  end

  describe 'given a condition' do
    let(:travis_yml) do
      <<~yml
        import:
          - source: one/one.yml
            if: type = push
          - source: one/two.yml
            if: type = pull_request
      yml
    end

    let(:data) { { type: 'push' } }

    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      travis-ci/travis-yml:one/one.yml@ref
    )

    it { expect(msgs).to include [:imports, :info, :skip_import, reason: :condition, condition: 'type = pull_request'] }
  end

  describe 'visibility' do
    let(:repo) { { slug: 'travis-ci/travis-yml', private: visibilities[0] == :private } }
    let(:travis_yml) { "import: #{other}:one.yml" }

    before { stub_content(other, 'one.yml', one_yml) }
    before { stub_repo(other, private: visibilities[1] == :private) }
    before { stub_settings(other, allow_config_imports: true) }

    describe 'a public repo referencing a public repo' do
      let(:other) { 'other/other' }
      let(:visibilities) { [:public, :public] }
      it { expect { subject }.to_not raise_error }
    end

    describe 'a public repo referencing a private repo' do
      let(:error) { Travis::Yml::Import::InvalidVisibility }
      let(:other) { 'other/other' }
      let(:visibilities) { [:public, :private] }
      it { expect { subject }.to raise_error error }
    end

    describe 'a private repo referencing a public repo from the same owner' do
      let(:other) { 'travis-ci/other' }
      let(:visibilities) { [:private, :public] }
      it { expect { subject }.to_not raise_error }
    end

    describe 'a private repo referencing a public repo from another owner' do
      let(:other) { 'other/other' }
      let(:visibilities) { [:private, :public] }
      it { expect { subject }.to_not raise_error }
    end

    describe 'a private repo referencing a private repo from the same owner (setting: true)' do
      let(:other) { 'travis-ci/other' }
      let(:visibilities) { [:private, :private] }
      it { expect { subject }.to_not raise_error }
    end

    describe 'a private repo referencing a private repo from the same owner (setting: not true)' do
      let(:other) { 'travis-ci/other' }
      let(:visibilities) { [:private, :private] }
      let(:error) { Travis::Yml::Import::NotAllowed }
      before { stub_settings(other, allow_config_imports: false) }
      it { expect { subject }.to raise_error error }
    end

    describe 'a private repo referencing a private repo from another owner' do
      let(:other) { 'other/other' }
      let(:visibilities) { [:private, :private] }
      let(:error) { Travis::Yml::Import::InvalidOwnership }
      it { expect { subject }.to raise_error error }
    end
  end

  describe 'cyclic imports (1)' do
    let(:travis_yml) { 'import: .travis.yml' }

    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
    )
  end

  describe 'cyclic imports (2)' do
    let(:one_yml) { 'import: ./two.yml' }
    let(:two_yml) { 'import: ./one.yml' }

    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      travis-ci/travis-yml:one/one.yml@ref
      travis-ci/travis-yml:one/two.yml@ref
    )
  end

  describe 'cyclic imports (3)' do
    let(:one_yml) { 'import: .travis.yml' }
    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
      travis-ci/travis-yml:one/one.yml@ref
    )
  end

  describe 'malformed ref (skips the import, outputs a validation message)' do
    let(:travis_yml) { 'import: "@v1"' }
    let(:error) { Travis::Yml::Import::InvalidRef }
    imports %w(
      travis-ci/travis-yml:.travis.yml@ref
    )
  end

  describe 'unknown repo' do
    let(:travis_yml) { 'import: unknown/unknown:one.yml@v1' }
    let(:error) { Travis::Yml::Import::UnknownRepo }
    xit { expect { configs }.to raise_error(error) }
  end

  describe 'too many imports' do
    let(:error) { Travis::Yml::Import::TooManyImports }
    let(:travis_yml) { "import: \n#{1.upto(30).map { |i| "- #{i}.yml" }.join("\n")}" }
    before { 1.upto(30) { |i| stub_content(repo[:slug], "#{i}.yml", '') } }
    it { expect { subject }.to raise_error(error) }
  end

  # describe 'github api errors' do
  #   describe '401' do
  #     # TODO spec for both .travis.yml and referenced configs (needs tokens set up)
  #     let(:client) { Travis::Gatekeeper::Github::Api::Client.any_instance }
  #     let(:error) { Travis::Gatekeeper::Github::TokenInvalid.new(Token.new, nil) }
  #     before { client.stubs(:get).raises(error) }
  #     it { expect { configs.config }.to raise_error(Travis::Gatekeeper::Model::Request::Configs::Unauthorized) }
  #   end
  #
  #   describe 'fetching .travis.yml' do
  #     describe '404' do
  #       before { stub_content repo.slug, '.travis.yml', 'bf944c9', '', 404 }
  #       it { expect { configs.config }.to raise_error(Travis::Gatekeeper::Model::Request::Configs::NotFound) }
  #     end
  #
  #     describe '500' do
  #       before { stub_content repo.slug, '.travis.yml', 'bf944c9', '', 500 }
  #       it { expect { configs.config }.to raise_error(Travis::Gatekeeper::Model::Request::Configs::GithubError) }
  #     end
  #   end
  #
  #   describe 'fetching a referenced config' do
  #     describe '404' do
  #       before { stub_content repo.slug, 'one.yml', 'v1', '', 404 }
  #       it { expect { configs.config }.to raise_error(Travis::Gatekeeper::Model::Request::Configs::NotFound) }
  #     end
  #
  #     describe '500' do
  #       before { stub_content repo.slug, 'one.yml', 'v1', '', 500 }
  #       it { expect { configs.config }.to raise_error(Travis::Gatekeeper::Model::Request::Configs::GithubError) }
  #     end
  #   end
  # end

  describe 'order' do
    let(:repo) { { slug: 'owner/repo' } }
    let(:travis_yml) { 'import: [.travis.yml, 1.yml]' }
    let(:y1) { 'import: [2.yml, 5.yml, 6.yml]' }
    let(:y2) { 'import: [3.yml]' }
    let(:y3) { 'import: [4.yml, 1.yml]' }
    let(:y4) { 'script: ./4' }
    let(:y5) { 'script: ./5' }
    let(:y6) { 'script: ./6' }

    before { stub_content(repo[:slug], '.travis.yml', travis_yml) }
    before { stub_repo(repo[:slug], repo) }
    before { 1.upto(6) { |i| stub_content(repo[:slug], "#{i}.yml", send(:"y#{i}")) } }

    subject { configs.tap(&:load).map(&:to_s) }

    it do
      should eq %w(
        owner/repo:.travis.yml@ref
        owner/repo:1.yml@ref
        owner/repo:2.yml@ref
        owner/repo:3.yml@ref
        owner/repo:4.yml@ref
        owner/repo:5.yml@ref
        owner/repo:6.yml@ref
      )
    end
  end
end

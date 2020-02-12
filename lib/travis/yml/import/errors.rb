module Travis
  module Yml
    module Import
      module Errors
        class Error < Class.new(StandardError)
          def type
            self.class.name.demodulize.underscore.to_sym
          end
        end

        InvalidConfig = Class.new(Error)
        InvalidRef = Class.new(Error)
        InvalidVisibility = Class.new(Error)
        InvalidOwnership = Class.new(Error)
        NotAllowed = Class.new(Error)
        TooManyImports = Class.new(Error)
        UnknownRepo = Class.new(Error)
        ParseError = Class.new(Error)
        NotFound = Class.new(Error)
        Unauthorized = Class.new(Error)
        GithubError = Class.new(Error)

        MSGS = {
          invalid_config: 'Invalid config :import (given: %p)',
          invalid_ref: 'Invalid reference: %p',
          invalid_visibility: 'Private repo %s referenced from a public repo',
          invalid_ownership: 'Cannot import a private config file from another owner (%s)',
          not_allowed: 'Importing from the private repo %s is not allowed as per its settings',
          too_many_imports: 'Too many imports: %s, max: %s',
          unknown_repo: 'Unknown repo referenced: %s',
          parse_error: 'Could not parse %s',
          not_found: 'Not found: %s',
          unauthorized: 'Unable to authenticate with GitHub for %s',
          github_error: 'Error retrieving %s. Is GitHub down?'
        }

        def invalid_config(config)
          raise InvalidConfig.new(MSGS[:invalid_config] % [config])
        end

        def invalid_ref(ref)
          raise InvalidRef.new(MSGS[:invalid_ref] % ref)
        end

        def too_many_imports(count, max)
          raise TooManyImports.new(MSGS[:too_many_imports] % [count, max])
        end

        def invalid_visibility(repo)
          raise InvalidVisibility.new(MSGS[:invalid_visibility] % repo.slug)
        end

        def invalid_ownership(repo)
          raise InvalidOwnership.new(MSGS[:invalid_ownership] % repo.owner_name)
        end

        def not_allowed(repo)
          raise NotAllowed.new(MSGS[:not_allowed] % repo.slug)
        end

        def unknown_repo(slug)
          raise UnknownRepo.new(MSGS[:unknown_repo] % slug)
        end

        def parse_error
          raise ParseError.new(MSGS[:parse_error] % to_s)
        end

        def unauthorized
          raise Unauthorized.new(MSGS[:unauthorized] % to_s)
        end

        def not_found
          raise NotFound.new(MSGS[:not_found] % to_s)
        end

        def github_error
          raise GithubError.new(MSGS[:github_error] % to_s)
        end

        def raise(e)
          Thread.main.raise(e)
        end
      end
    end
  end
end

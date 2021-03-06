# frozen_string_literal: true
require 'travis/yml/doc/change/base'
require 'travis/yml/doc/helper/cast'

module Travis
  module Yml
    module Doc
      module Change
        class Cast < Base
          def apply
            apply? && cast? ? cast : value
          end

          private

            def apply?
              value.scalar? && !value.secure? && value.given?
            end

            def cast?
              !schema.is?(value.type) && !schema.secure? && !value.secure?
            end

            def cast
              return value if value.value == casted
              # store_msgs
              build(casted)
            end

            def casted
              @casted ||= caster.apply
            end

            def caster
              @caster ||= Doc::Cast.new(value.value, schema.type)
            end

            # def store_msgs
            #   msgs = caster.msgs.map { |msg| [:warn, *msg] }
            #   msgs << [:info, *msg] if msg?
            #   msgs.each { |msg| value.send *msg }
            # end
            #
            # def msg
            #   [:cast, given_value: value.value, given_type: value.type, value: casted, type: schema.type]
            # end
            #
            # def msg?
            #   !bool2str? && !str2bool? && !str2num? && !num2str?
            # end
            #
            # def bool2str?
            #   # e.g. `install: true`, as given in our docs
            #   value.bool? && schema.str?
            # end
            #
            # def num2str?
            #   # e.g. `python: 2.7`, when already parsed outside of travis-yml
            #   value.num? && schema.str?
            # end
            #
            # def str2num?
            #   # e.g. `git: depth: 10`, as given in our docs
            #   # e.g. `node_js: 2.10` being parsed into `node_js: 2.1`
            #   value.str? && schema.num?
            # end
            #
            # def str2bool?
            #   # e.g. `sudo: required`, as given in our docs
            #   value.str? && schema.bool?
            # end
        end
      end
    end
  end
end

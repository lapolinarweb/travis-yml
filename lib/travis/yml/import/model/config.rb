module Travis
  module Yml
    module Model
      class Config < Struct.new(:config, :key)
        def encrypt
          walk { |obj| secure?(obj) ? process(:encrypt, obj) : obj }
        end

        def decrypt
          walk { |obj| secure?(obj) ? process(:decrypt, obj) : obj }
        end

        def secure?(obj)
          obj.is_a?(Hash) && obj.key?(:secure)
        end

        def process(action, obj)
          { secure: key.send(action, obj[:secure]) }
        end

        def walk(obj = config, &block)
          case obj
          when Hash
            block.call(obj).map { |key, obj| [key, walk(obj, &block)] }.to_h
          when Array
            obj.map { |obj| walk(obj, &block) }
          else
            obj
          end
        end
      end
    end
  end
end

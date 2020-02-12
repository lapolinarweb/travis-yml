module Travis
  module Yml
    module Import
      class Key < Struct.new(:key)
        def encrypt(obj)
          p [:encrypt, obj]
          obj
        end

        def decrypt(obj)
          p [:decrypt, obj]
          obj
        end
      end
    end
  end
end

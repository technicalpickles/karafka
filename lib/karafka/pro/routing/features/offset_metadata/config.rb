# frozen_string_literal: true

# This code is part of Karafka Pro, a commercial component not licensed under LGPL.
# See LICENSE for details.

module Karafka
  module Pro
    module Routing
      module Features
        class OffsetMetadata < Base
          # Config for commit metadata feature
          Config = Struct.new(
            :active,
            :deserializer,
            :cache,
            keyword_init: true
          ) do
            alias_method :active?, :active
            alias_method :cache?, :cache
          end
        end
      end
    end
  end
end

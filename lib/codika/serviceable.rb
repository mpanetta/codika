module Codika
  module Serviceable
    def self.included(klass)
      klass.extend ClassMethods

      klass.include Actionable
    end

    module ClassMethods
      def execute(action:, params: {})
        execute!(params:) do |service|
          service.send(action)
          service.context
        end
      end
    end
  end
end

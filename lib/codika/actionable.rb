module Codika
  module Actionable
    class ActionableError < StandardError; end

    attr_reader :context

    def self.included(klass)
      klass.extend ClassMethods
    end

    def initialize(params: {})
      @context = Context.new(params)
    end

    def requires?(key)
      self.class.required_keys.include?(key)
    end

    def promises?(key)
      self.class.promised_keys.include?(key)
    end

    module ClassMethods
      def inherited(subclass)
        super

        subclass.instance_variable_set(:@required_keys, required_keys.dup)
        subclass.instance_variable_set(:@promised_keys, promised_keys.dup)
      end

      def execute!(params:, &block)
        executer = new(params:)

        validate_required_keys!(executer.context)
        block&.call(executer)
        validate_promised_keys!(executer.context) unless executer.context.failure?

        executer.context
      end

      def requires(*keys)
        required_keys.concat(keys)
      end

      def promises(*keys)
        promised_keys.concat(keys)
      end

      def required_keys
        @required_keys ||= []
      end

      def promised_keys
        @promised_keys ||= []
      end

      def validate_required_keys!(context)
        valid, missing = validate_keys(required_keys, context)

        return if valid

        keys = missing.join(", ")
        message = I18n.t!("codika.actions.errors.missing_required", keys: keys)

        raise ActionableError, message
      end

      def validate_promised_keys!(context)
        valid, missing = validate_keys(promised_keys, context)

        return if valid

        keys = missing.join(", ")
        message = I18n.t!("codika.actions.errors.missing_promised", keys: keys)

        raise ActionableError, message
      end

      def validate_keys(keys, context)
        bad_keys = keys.reject { |k| context.respond_to?(k) }

        [bad_keys.empty?, bad_keys]
      end
    end
  end
end

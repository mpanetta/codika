module Codika
  module Organizable
    attr_writer :context

    def self.included(klass)
      klass.extend ClassMethods

      klass.include Actionable
    end

    module ClassMethods
      def execute(params: {})
        execute!(params:) do |organizer|
          current_input_for_step = organizer.context

          organizer.actions.each do |action_klass, action_method_name|
            step_output_context = _perform_action_step(action_klass, action_method_name, current_input_for_step)
            _update_organizer_context_with_step_result(organizer.context, step_output_context)

            current_input_for_step = step_output_context
          end
        end
      end

      private

      def _perform_action_step(action_klass, action_method_name, input_context_for_step)
        params_for_action = input_context_for_step.to_h.except(*Codika::Context::RESERVED_KEYS)
        action_klass.execute(action: action_method_name, params: params_for_action)
      end

      def _update_organizer_context_with_step_result(organizer_main_context, step_output_context)
        step_output_context.to_h.each do |key, value|
          organizer_main_context[key] = value unless Codika::Context::RESERVED_KEYS.include?(key.to_sym)
        end

        return unless step_output_context.failure? && organizer_main_context.success?

        organizer_main_context.fail!(error: step_output_context.error)
      end
    end
  end
end

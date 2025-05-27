module Codika
  class Context < OpenStruct
    class ReservedKeyError < RuntimeError; end

    RESERVED_KEYS = %i[success error].freeze

    attr_reader :success, :error

    def initialize(params = {})
      validated = _validate_params!(params)

      @success = nil
      @error = nil

      super(validated)
    end

    private

    def _validate_params!(params)
      params.deep_symbolize_keys.tap do |symbolized|
        reserved_keys_used = RESERVED_KEYS & symbolized.keys

        raise ReservedKeyError, reserved_keys_used.join(", ") if reserved_keys_used.present?
      end
    end
  end
end

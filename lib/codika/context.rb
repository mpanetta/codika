module Codika
  class Context < OpenStruct
    class ReservedKeyError < RuntimeError; end

    RESERVED_KEYS = %i[success error].freeze

    attr_reader :success, :error

    def initialize(params = {})
      validated = _validate_params!(params)

      @success = true
      @error = nil

      super(validated)
    end

    def success?
      !!@success
    end

    def failure?
      !success?
    end

    def fail!(error: nil)
      @success = false
      @error = error
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

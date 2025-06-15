require "spec_helper"

RSpec.describe Codika::Actionable do
  subject(:actionable) do
    Class.new do
      include Codika::Actionable
    end
  end

  describe "execute!" do
    let(:params) { { foo: "bar" } }

    it "invokes the block" do
      expect do |block|
        actionable.execute!(params:, &block)
      end.to yield_with_args(an_instance_of(actionable))
    end

    context "when returning the context" do
      let(:result) { actionable.execute!(params:) }

      it "returns an instance of Context" do
        expect(result).to be_instance_of(Codika::Context)
      end

      it "builds the context from the params" do
        expect(result.foo).to eq("bar")
      end
    end

    context "when requiring keys" do
      before do
        actionable.class_eval do
          requires :key1, :key2
        end
      end

      context "when the keys are in the hash" do
        # `params` here refers to the outer `let(:params) { { foo: "bar" } }`
        let(:params_with_required_keys) { params.merge({ key1: "value1", key2: "value2" }) }

        it "does not raise an error" do # This was line 55
          expect { actionable.execute!(params: params_with_required_keys) }.not_to raise_error
        end
      end

      context "when the keys are not in the hash" do
        # `params` here refers to the outer `let(:params) { { foo: "bar" } }`, which doesn't have key1 or key2
        it "raises the expected exception" do
          expect do
            actionable.execute!(params: params) # Use the original params which lacks key1, key2
          end.to raise_error(described_class::ActionableError, /Missing required keys: (key1, key2|key2, key1)/)
        end
      end
    end

    context "when promising keys" do
      let(:result) { actionable.execute!(params:) }

      before do
        actionable.class_eval do
          promises :key1, :key2
        end
      end

      context "when the keys are returned" do
        before do
          actionable.class_eval do
            def call(context)
              context.key1 = "value1"
              context.key2 = "value2"
            end
          end
        end

        it "does not raise an error when promised keys are set" do
          expect do
            actionable.execute!(params:) { |instance| instance.call(instance.context) }
          end.not_to raise_error
        end
      end

      context "when the keys are not returned" do
        it "raises the expected exception" do
          expect do
            result
          end.to raise_error(described_class::ActionableError, /Missing promised keys: (key1, key2|key2, key1)/)
        end
      end
    end
  end
end

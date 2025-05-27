require "spec_helper"

RSpec.describe Codika::Context do
  describe "#new" do
    subject(:context) { described_class.new(**params) }

    context "when the params are valid" do
      let(:params) { { first: "value1", second: "value2" } }

      it "responds to the params as expected" do
        expect(context.first).to eq("value1")
      end
    end

    context "when a reserved key is included in the params" do
      let(:params) { { success: true, test: :param } }

      it "raises the expected error" do
        expect do
          context
        end.to raise_error(described_class::ReservedKeyError, "success")
      end

      context "when the keys are strings" do
        before { params.stringify_keys! }

        it "raises the expected error" do
          expect do
            context
          end.to raise_error(described_class::ReservedKeyError, "success")
        end
      end
    end
  end
end

require "spec_helper"

require_relative "../fixtures/test_organizer"

RSpec.describe Codika::Organizable do
  let(:result) { organizer_class.execute(params:) }

  let(:organizer_class) { TestOrganizer }
  let(:params) { { initial_data: "start_data" } }

  describe ".execute" do
    context "when all actions are successful" do
      before do
        organizer_class.actions_definition = [
          [organizer_class::ActionOne, :run],
          [organizer_class::ActionTwo, :run]
        ]
      end

      it "executes all actions in the defined order" do
        expect(result.history).to eq(%i[action_one_ran action_two_ran])
      end

      it "passes the context from one action to the next" do
        expected_output_one = "output_from_one_using_#{params[:initial_data]}"

        expect(result.action_two_output).to eq("output_from_two_using_#{expected_output_one}")
      end

      it "returns the final context from the last action" do
        expect(result.action_two_output).not_to be_nil
      end

      it "marks the final context as successful" do
        expect(result).to be_success
      end

      it "passes initial params to the first action" do
        expect(result.action_one_output).to include(params[:initial_data])
      end
    end

    context "when an action calls context.fail!" do
      before do
        organizer_class.actions_definition = [
          [organizer_class::ActionOne, :run], [organizer_class::FailingAction, :run], [organizer_class::ActionTwo, :run]
        ]
      end

      it "attempts to execute actions after the failing one" do
        expect(result.history).to eq(%i[action_one_ran failing_action_ran action_two_ran])
      end

      it "includes the error message from the failing action in the final context" do
        expect(result.error).to eq("custom_failing_action_error")
      end

      it "contains results from actions before the failure" do
        expect(result.action_one_output).not_to be_nil
      end

      it "contains results from the failing action itself" do
        expect(result.attempted_failing_action).to be true
      end

      it "contains results from actions after the failure if they could execute" do
        expect(result.action_two_output).not_to be_nil
      end

      it "marks the organizer's final context as failed" do
        expect(result).to be_failure
      end
    end

    context "when an action raises an unexpected error" do
      before do
        organizer_class.actions_definition = [
          [organizer_class::ActionOne, :run], [organizer_class::ErroringAction, :run],
          [organizer_class::ActionTwo, :run]
        ]
      end

      it "propagates the unexpected error" do
        expect { result }.to raise_error(StandardError, "unexpected_runtime_error_in_action")
      end
    end

    context "when the actions list is empty" do
      before do
        organizer_class.actions_definition = []
      end

      it "returns the initial context" do
        expect(result.to_h.slice(*params.keys)).to eq(params)
      end

      it "marks the context as successful" do
        expect(result).to be_success
      end

      it "does not raise an error" do
        expect { result }.not_to raise_error
      end
    end
  end
end

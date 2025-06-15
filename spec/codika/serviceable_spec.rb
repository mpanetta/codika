require "spec_helper"

RSpec.describe Codika::Serviceable do
  describe "execute" do
    let(:klass) do
      Class.new do
        include Codika::Serviceable

        def test_action
          context.ran = true
        end
      end
    end

    let(:params) do
      { foo: "bar", bar: "foo" }
    end

    it "executes the action" do
      context = klass.execute(action: :test_action, params:)

      expect(context.ran).to be(true)
    end
  end
end

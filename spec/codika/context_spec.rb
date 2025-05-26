require "spec_helper"

RSpec.describe Codika::Context do
  describe "#new" do
    it "makes a new one" do
      expect(described_class.new).to be_instance_of(described_class)
    end
  end
end

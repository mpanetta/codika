FactoryBot.define do
  factory :context, class: "Codika::Context" do
    initialize_with { new(**attributes) }
  end
end

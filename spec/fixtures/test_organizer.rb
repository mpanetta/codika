require_relative "organizer_actions"

class TestOrganizer
  include Codika::Organizable

  cattr_accessor :actions_definition, instance_accessor: false

  def actions
    self.class.actions_definition
  end

  ActionOne = OrganizerTestActionOne
  ActionTwo = OrganizerTestActionTwo
  FailingAction = OrganizerTestFailingAction
  ErroringAction = OrganizerTestErroringAction
end

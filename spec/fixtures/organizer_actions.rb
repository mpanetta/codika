class OrganizerTestActionOne
  include Codika::Serviceable

  requires :initial_data
  promises :action_one_output

  def run
    context.action_one_output = "output_from_one_using_#{context.initial_data}"
    context.history ||= []
    context.history << :action_one_ran
  end
end

class OrganizerTestActionTwo
  include Codika::Serviceable

  requires :action_one_output
  promises :action_two_output

  def run
    context.action_two_output = "output_from_two_using_#{context.action_one_output}"
    context.history ||= []
    context.history << :action_two_ran
  end
end

class OrganizerTestFailingAction
  include Codika::Serviceable

  promises :attempted_failing_action

  def run
    context.attempted_failing_action = true
    context.history ||= []
    context.history << :failing_action_ran
    context.fail!(error: "custom_failing_action_error")
  end
end

class OrganizerTestErroringAction
  include Codika::Serviceable

  def run
    context.history ||= []
    context.history << :erroring_action_ran
    raise StandardError, "unexpected_runtime_error_in_action"
  end
end

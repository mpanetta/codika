# Codika

Codika provides a set of simple, composable modules to help abstract and organize business logic in Ruby applications, particularly well-suited for Rails projects. It promotes clear contracts for inputs and outputs (via `requires` and `promises`), and facilitates the creation of service objects and multi-step organizers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'codika' # Replace 'codika' with your actual gem name if different
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install codika # Replace 'codika' with your actual gem name if different
```

## Core Concepts

### 1. `Codika::Context`

The `Context` object is the heart of Codika. It's an `OpenStruct`-like object responsible for:

*   Carrying data through your actions and organizers.
*   Tracking the success or failure state of an operation.
*   Automatically symbolizing keys from input parameters (deeply).

**Key Attributes & Methods:**
*   `success?`: Returns `true` if the operation was successful, `false` otherwise.
*   `failure?`: Returns `true` if the operation failed.
*   `error`: Contains the error message or object if `fail!` was called.
*   `fail!(error: "reason")`: Marks the context as failed and sets the error.
*   Any other attributes are dynamically added based on the params passed during initialization or set within actions.

**Reserved Keys:**
The keys `:success` and `:error` are reserved and cannot be used as data keys when initializing a `Codika::Context`. Doing so will raise a `Codika::Context::ReservedKeyError`.

### 2. `Codika::Actionable`

`Actionable` is the foundational module for creating individual, self-contained units of business logic.

**Key Features:**

*   **Contracts with `requires` and `promises`:**
    *   `requires :input_key1, :input_key2`: Declares keys that *must* be present in the context when the action begins. If a required key is missing, `execute!` will raise a `Codika::Actionable::ActionableError`.
    *   `promises :output_key1, :output_key2`: Declares keys that the action *guarantees* to set on the context upon successful completion. If a promised key is missing (and the action didn't explicitly fail via `context.fail!`), `execute!` will raise a `Codika::Actionable::ActionableError`.
    *   These declarations are inherited and duplicated correctly in subclasses.

*   **Execution with `execute!`:**
    Actions are run using the class method `execute!`. It takes `params:` to initialize the context and a block where the action's logic resides.
    ```ruby
    # lib/process_payment_action.rb
    class ProcessPaymentAction
      include Codika::Actionable
    
      requires :amount, :payment_token
      promises :transaction_id, :status
    end
    
    # --- Usage ---
    payment_params = { amount: 100, payment_token: "tok_123" }
    result_context = ProcessPaymentAction.execute!(params: payment_params) do |action|
      # action.context is available here
      puts "Processing payment for #{action.context.amount}..."
      
      # Simulate payment processing
      if action.context.payment_token == "tok_123" && action.context.amount > 0
        action.context.transaction_id = "txn_#{SecureRandom.hex(6)}"
        action.context.status = "succeeded"
        puts "Payment successful: #{action.context.transaction_id}"
      else
        action.context.status = "failed"
        action.context.fail!(error: "Invalid payment token or amount")
        puts "Payment failed."
      end
    end
    
    if result_context.success?
      puts "Final Status: #{result_context.status}, Transaction ID: #{result_context.transaction_id}"
    else
      puts "Final Error: #{result_context.error}"
    end
    # Example Output (Success):
    # Processing payment for 100...
    # Payment successful: txn_...
    # Final Status: succeeded, Transaction ID: txn_...
    ```
    The `execute!` method always returns the `Codika::Context` instance.

### 3. `Codika::Serviceable`

`Serviceable` is a convenience module built upon `Actionable`. It's designed for actions that primarily consist of a single public method performing the core logic.

**Key Features:**

*   Includes `Codika::Actionable`, so all its features (`requires`, `promises`, `context`) are available.
*   Provides a simplified `execute` class method that calls a specified instance method on the service.

**Example:**

```ruby
# lib/user_finder_service.rb
class UserFinderService
  include Codika::Serviceable # Includes Actionable

  requires :user_id
  promises :user_name, :user_email

  def find_user_details
    # self.context is available here, initialized with :user_id
    if context.user_id == 1
      context.user_name = "Alice Wonderland"
      context.user_email = "alice@example.com"
    elsif context.user_id == 2
      # Example of a promise not being fulfilled if logic dictates
      context.user_name = "Bob The Builder"
      # context.user_email is not set
    else
      context.fail!(error: "User not found")
    end
  end
end

# --- Usage ---
result1 = UserFinderService.execute(action: :find_user_details, params: { user_id: 1 })
if result1.success?
  puts "Found: #{result1.user_name} (#{result1.user_email})"
else
  puts "Error: #{result1.error}"
end
# Output: Found: Alice Wonderland (alice@example.com)

result2 = UserFinderService.execute(action: :find_user_details, params: { user_id: 2 })
# This will raise Codika::Actionable::ActionableError because :user_email is promised but not set,
# and the action didn't call context.fail!
# To handle this, UserFinderService#find_user_details should call context.fail! if it can't fulfill all promises.
# For example, if user_id == 2 and email is mandatory:
#   context.fail!(error: "User email could not be determined")

result3 = UserFinderService.execute(action: :find_user_details, params: { user_id: 99 })
if result3.success?
  puts "Found: #{result3.user_name}"
else
  puts "Error: #{result3.error}"
end
# Output: Error: User not found
```

### 4. `Codika::Organizable`

`Organizable` is used to orchestrate a sequence of multiple actions (which can be `Actionable` or `Serviceable` based). It helps manage complex workflows by breaking them into smaller, manageable steps.

**Key Features:**

*   Includes `Codika::Actionable`, so an organizer itself has a context and can have `requires` and `promises` (though often, its main role is orchestration).
*   **Defining the Action Sequence:** You must define an instance method named `actions` that returns an array of arrays. Each inner array should be `[ActionClass, :method_to_call_on_action_class]`. For `Serviceable` actions, this method is typically the main service method (e.g., `:run`, `:execute_logic`). For `Actionable` classes used directly in an organizer, the method name is less critical as `Actionable.execute!` uses a block, but a conventional name like `:perform` or `:run_step` can be used if the `Actionable` class defines such a method for clarity (though `Serviceable.execute` handles this for you).
*   **Context Propagation:**
    *   The organizer's initial context (from `params` passed to its `execute` method) is used as the basis for the first action's input.
    *   The data from one action's output context (excluding reserved keys like `:success`, `:error`) is available for the next action.
    *   All data set by individual actions is merged into the organizer's final context.
*   **Failure Handling:**
    *   If any action in the sequence calls `context.fail!`, the organizer's overall context will be marked as failed. The error message from the *first* failing action is captured in the organizer's context.
    *   Subsequent actions in the sequence are still attempted, but the organizer's final status will reflect the failure.
    *   If an action raises an unhandled exception (not a `context.fail!`), the organizer will propagate that exception, and subsequent actions will not run.

**Example:**

```ruby
# --- Define individual actions (can be Serviceable or Actionable) ---
class CreateUserAction
  include Codika::Serviceable
  requires :email, :password
  promises :user_id, :user_email # user_email is re-promised for clarity if needed by later steps

  def create
    puts "CreateUserAction: Creating user with email #{context.email}"
    # Simulate user creation
    context.user_id = SecureRandom.uuid
    context.user_email = context.email # Pass email along
    puts "CreateUserAction: User #{context.user_id} created."
  end
end

class SendWelcomeEmailAction
  include Codika::Serviceable
  requires :user_id, :user_email # Gets these from CreateUserAction's output
  promises :email_sent_at

  def send_email
    puts "SendWelcomeEmailAction: Sending welcome email to #{context.user_email} (ID: #{context.user_id})."
    # Simulate sending email
    if context.user_email.include?("fail") # Simulate a failure condition
      puts "SendWelcomeEmailAction: Failed to send email."
      context.fail!(error: "Email provider unavailable")
    else
      context.email_sent_at = Time.now.utc.to_s
      puts "SendWelcomeEmailAction: Email sent at #{context.email_sent_at}."
    end
  end
end

# --- Define the Organizer ---
# lib/user_signup_organizer.rb
class UserSignupOrganizer
  include Codika::Organizable

  # Organizers can also have their own requires/promises if needed for initial setup
  # For example: requires :signup_source

  def actions
    [
      [CreateUserAction, :create],
      [SendWelcomeEmailAction, :send_email]
    ]
  end
end

# --- Usage ---
puts "\n--- Scenario 1: Successful Signup ---"
signup_params_success = { email: "newuser@example.com", password: "securePassword123" }
result_success = UserSignupOrganizer.execute(params: signup_params_success)

if result_success.success?
  puts "Signup successful! User ID: #{result_success.user_id}, Email sent: #{result_success.email_sent_at}"
else
  puts "Signup failed: #{result_success.error}"
end

puts "\n--- Scenario 2: Signup with Email Failure ---"
signup_params_fail = { email: "newuser+fail@example.com", password: "securePassword123" }
result_fail = UserSignupOrganizer.execute(params: signup_params_fail)

if result_fail.success?
  puts "Signup successful! User ID: #{result_fail.user_id}, Email sent: #{result_fail.email_sent_at}"
else
  puts "Signup failed: #{result_fail.error}"
  puts "User was still created (ID: #{result_fail.user_id}) but email failed."
end

# Example Output:
# --- Scenario 1: Successful Signup ---
# CreateUserAction: Creating user with email newuser@example.com
# CreateUserAction: User ... created.
# SendWelcomeEmailAction: Sending welcome email to newuser@example.com (ID: ...).
# SendWelcomeEmailAction: Email sent at ...
# Signup successful! User ID: ..., Email sent: ...

# --- Scenario 2: Signup with Email Failure ---
# CreateUserAction: Creating user with email newuser+fail@example.com
# CreateUserAction: User ... created.
# SendWelcomeEmailAction: Sending welcome email to newuser+fail@example.com (ID: ...).
# SendWelcomeEmailAction: Failed to send email.
# Signup failed: Email provider unavailable
# User was still created (ID: ...) but email failed.
```

## Error Handling Summary

*   **Missing `requires` or `promises`**: `Codika::Actionable::ActionableError` is raised by `Actionable.execute!`.
*   **Explicit Failure within an Action**: Call `context.fail!(error: "reason")` on an action's context. The context's `failure?` will then be `true`, and `context.error` will hold the reason. Organizers will reflect this failure.
*   **Reserved Keys in `Codika::Context` Initialization**: `Codika::Context::ReservedKeyError` is raised if you attempt to initialize a context with `:success` or `:error` as data keys.
*   **Unexpected Runtime Errors**: Standard Ruby exceptions raised within an action's logic (and not rescued by your code) will propagate up as usual. In an `Organizable` sequence, this will halt the organizer.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/mpanetta/codika].

## License

The gem is available as open source under the terms of the MIT License.

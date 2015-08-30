# Bali

[ ![Codeship Status for saveav/bali](https://codeship.com/projects/d2f3ded0-20cf-0133-e425-0eade5a669ff/status?branch=release)](https://codeship.com/projects/95727)

Bali is a powerful, framework-agnostic, thread-safe Ruby language authorization library. It is a universal authorization library, in the sense that it does not assume you to use specific Ruby library/gem/framework in order for successful use of this gem.

Bali is short for Bulwark Authorization Library.

## Installation

It can be installed directly by using bundler's install:

    $ gem install bali

Otherwise, if you are using a framework such as Rails, you can add this into your gemfile:

```ruby
gem 'bali'
```

And then execute:

    $ bundle

## Usage

### Defining access rules

Rule in Bali is the law determining whether a user (called `subtarget`) can do or perform a specific operation on a target (which is your resource/model).

```ruby
  Bali.map_rules do
    rules_for My::Transaction, as: :transaction do
      describe(:supreme_user) { can_all }
      describe :admin_user do
        can_all
        # a more specific rule would be executed even if can_all is present
        can :cancel, 
          if: proc { |record| record.payment_channel == "CREDIT_CARD" && 
                              !record.is_settled? }
      end
      describe "general user", can: [:update, :edit], cant: [:delete]
      describe "finance user" do
        can :update, :delete, :edit
        can :delete, if: proc { |record| record.is_settled? }
        can :cancel, unless: proc { |record| record.is_settled? }
      end # finance_user description
      describe :guest { cant_all }
      describe nil { cant_all }
    end # rules_for
  end
```

You may or may not assign an alias name (`as`). Make sure to keep it unique had you decided to give alias name to your rules group.

It is also possible for a rule to be defined for multiple subtarget at once:

```ruby
  Bali.map_rules do
    rules_for My::Transaction do
      # rules described bellow will affect both :general_user and :finance_user
      describe :general_user, :finance_user do
        can :update, :edit
      end
    end
  end
```

### Can and Cant? testing

Say:

```ruby
class My::Transaction
  include Bali::Objector

  attr_accessor :is_settled
  attr_accessor :payment_channel

  alias :is_settled? :is_settled
end

class My::Employee
  include Bali::Objector

  # working experience in the company
  attr_accessor :exp_years

  # role/roles of this employee
  attr_accessor :roles
end
```

Assuming that there exist a variable `transaction` which is an instance of `My::Transaction`, we can query about whether the subtarget is granted to perform certain operation:

```ruby
transaction.cant?(:general_user, :delete)      # => true
transaction.can("general user", :update)       # => true
transaction.can?(:finance_user, :delete)       # depend on context
transaction.can?(:monitoring_user, :view)      # => true
transaction.can?(:admin_user, :cancel)         # depend on context
transaction.can?(:supreme_user, :cancel)       # => true
transaction.can?(:guest, :view)                # => false
transaction.can?(:undefined_subtarget, :see)   # => false
transaction.cant?(:undefined_subtarget, :new)  # => true
```

If a rule is depending on a certain context, then the context will be evaluated to determine whether the subtarget is authorized or not.

In the above example, deletion of `transaction` is only allowed if the subtarget is a "finance user" and, the `transaction` itself is already settled.

Also, asking `can?` on which the subtarget is not yet defined will always return `false`. In the example above, as `undefined_subtarget` is by itself has never been defined in `describe` under `My::Transaction` rule class, `can?` for `undefined_subtarget` will always return `false`. But, `cant` on simillar ocassion will return `true`.

Rule can also be tested on a class:

```ruby
My::Transaction.can?(:supreme_user, :new)      # => true
My::Transaction.can?(:guest, :view)            # => false
My::Employee.can?(:undefined_subtarget, :new)  # => false, rule class for this is by its own undefined
```

As we have never define the `rules_for` My::Employee before, any attempt to `can?` for `My::Employee` will return `false`, so does any attempt to object `cant?` on which will only return `true` for any given subtarget and operation.

### Can and Cant testing with multiple-roles subtarget

A subtarget may have multiple roles. For eg., a user may have a role of `finance_user` and `general_user`. A general user normally by itself cannot `delete`, or `cancel`; but a `finance_user` does can, so long the condition is met. But, if a subtarget has role of both `finance_user` and `general_user`, he/she can perform `delete` or `cancel` (so far that the condition is met.)

Thus, if we have:

```ruby
  txn = My::Transaction.new
  txn.process_transaction(from_user_input)

  # delete or cancel can only happen when a transaction is settled
  # as per rule definition
  txn.is_settled = true
  txn.save

  subtarget = User.new
  subtarget.roles = [:finance_user, :general_user]

  txn.can?(subtarget.roles, :delete)       # => true
  txn.cant?(subtarget.roles, :delete)      # => false
  txn.can?(:general_user, :delete)         # => false
```

That is, we can check `can?` and `cant?` with multiple roles by passing array of roles to it.

### Using subtarget's instance for Can and Cant testing

You may pass in real subtarget instance rather than (1) a symbol, (2) string or (3) array of string/symbol for can/cant testing. 

In order to do so, you need to specify the field/method in the subtarget that will be used to evaluating the subtarget's role(s). To do that, we define `roles_for` as follow inside `Bali.map_rules` block:

```ruby
Bali.map_rules do 
  roles_for My::Employee, :roles
  roles_for My::AdminUser, :admin_roles
  roles_for My::BankUser, :roles
  
  # rules definition
  # may follow
end
```

`roles_for` accept two parameters, namely the class of the subtarget, and the field/method that will be invoked on it to gain data about its role(s).

By doing so, we can now perform authorisation testing as follow:

```ruby
  txn = My::Transaction.new
  current_employee = My::Employee.find_by_id(1)
  txn.can?(current_employee, :print)
```

### Raises error on unauthorized access

`can?` and `cant?` just return boolean values on whether access is granted or not. If you want to raise an exception when an operation is inappropriate, use its variant: `can!` and `cant!`

When `can!` result in denied operation, it will raise `Bali::AuthorizationError`. In the other hand, `cant!` will raise `Bali::AuthorizationError` if it allows an operation.

`can!` and `cant` are invoked with a similar fashion as you would invoke `can?` and `cant?`

`Bali::AuthorizationError` is more than an exception, it also store information regarding:

1. `auth_level`: whether it is can, or cant testing.
2. `role`: the role under which authorisation is performed
3. `subtarget`: the object (if passing an object), or string/symbol representing the role
4. `operation`: the action
5. `target`: targeted object/class of the authorization

### Rule clause if/unless

Rule clause may contain `if` and `unless` (decider) proc as already seen before. This `if` and `unless` `proc` have three variants that can be used to express your rule in sufficient detail:

1. Zero arity
2. One arity
3. Two arity

When rule is very brief, use zero-arity rule clause as below:

```ruby
Bali.map_rules do 
  rules_for My::Transaction do
    describe(:staff) { can :cancel }
    describe(:finance) { can :cancel }
  end
end
```

Say that (for staff) to cancel a transaction, the transaction must have not been settled yet, you need to define the rule by using one-arity rule clause decider:

```ruby
describe :staff do
  can :cancel, if: { |txn| txn.is_settled? }
end
```

Good, but, in addition to that, how to allow transaction cancellation only to staff who has 3 years or so experience in working with the company? 

In order to do that, we need to resort to 2-arity decider, as follow:

```ruby
describe :staff do
  can :cancel, if: { |txn, usr| txn.is_settled? && usr.exp_years >= 3 }
end
```

This way, we can keep our controller/logic/model clean from unnecessary and un-DRY role-testing logic.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/saveav/bali. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

Bali is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Changelog

== Version 1.0.0beta1

1. Initial version

== Version 1.0.0rc1

1. Fix bug where user can't check on class
2. Adding new clause: cant_all

== Version 1.0.0rc2

1. [Fix bug when class's name, as a constant, is reloaded](http://stackoverflow.com/questions/2509350/rails-class-object-id-changes-after-i-make-a-request) (re-allocated to different address in the memory)
2. Allow describing rule for `nil`, useful if user is not authenticated thus role is probably `nil`
3. Remove pry from development dependency

== Version 1.0.0rc3

1. Each target class should includes `Bali::Objector`, for the following reasons:
   - Makes it clear that class do want to include the Bali::Objector
   - Transparant, and thus less confusing as to where "can?" and "cant" come from
   - When ruby re-parse the class's codes for any reasons, parser will be for sure include Bali::Objector
2. Return `true` to any `can?` for undefined target/subtarget alike
3. Return `false` to any `cant?` for undefined target/subtarget alike

== Version 1.0.0

1. Released the stable version of this gem

== Version 1.1.0rc1

1. Ability for rule class to be parsed later by passing `later: true` to rule class definition
2. Add `Bali.parse` and `Bali.parse!` (`Bali.parse!` executes "later"-tagged rule class, Bali.parse executes automatically after all rules are defined)
3. Added more thorough testing specs
4. Proc can be served under `unless` for defining the rule's decider

== Version 1.1.0rc2

1. Ability to check `can?` and `cant?` for subtarget with multiple roles
2. Describe multiple rules at once for multiple subtarget

== Version 1.2.0

1. Passing real object as subtarget's role, instead of symbol or array of symbol
2. Clause can also yielding user, along with the object in question
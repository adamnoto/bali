# Bali

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

### First things first: defining rules

Rule in Bali is the law determining whether a user (called 'subtarget') can specific operation on a target (which is your resource).

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
      end # finance_user description
    end # rules_for
  end
```

You may or may not assign an alias name (`as`). Make sure to keep it unique had you decided to give alias name to your rules group.

### Authorization

Assuming that there exist a variable `transaction` which is an instance of `My::Transaction`, we can query about whether the subtarget is granted to perform certain operation:

```ruby
transaction.cant?(:general_user, :delete)    # => true
transaction.can("general user", :update)     # => true
transaction.can?(:finance_user, :delete)     # depend on context
transaction.can?(:monitoring_user, :view)    # => true
transaction.can?("monitoring user", :view)   # => true
transaction.can?(:admin_user, :cancel)       # depend on context
transaction.can?(:supreme_user, :cancel)     # => true
```

If a rule is depending on a certain context, then the context will be evaluated to determine whether the subtarget is authorized or not.

In the above example, deletion of `transaction` is only allowed if the subtarget is a "finance user" and, the `transaction` itself is already settled.

Rule can also be called on a class, instead of on an object:

```ruby
My::Transaction.can?(:bank_corp, :new)      # => true
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/bali. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

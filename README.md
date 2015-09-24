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

## Deprecation notice

1. `cant` and `cant_all` which are used to declare rules will be deprecated on version 3.0, in favor of `cannot` and `cannot_all`. The reason behind this is that `can` and `cant` only differ by 1 letter, it is thought to be better to make it less ambiguous.
2. `cant?` and subsequently new-introduced `cant!` will be deprecated on version 3.0, in favor of `cannot?` and `cannot!` for the same reason as above.

## Usage

Please access [wiki pages](https://github.com/saveav/bali/wiki) for a more detailed, guided explanation.

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

Your task is to define rule, with context to `My::Transaction` object, in which:

1. Supreme user can do everything
2. Admin user can do everything, but:
   - Can only cancel transaction if the transaction is done using credit card, and the transaction itself is not settled yet
3. General user can:
   - Download transaction
4. Finance user can:
   - Index transaction
   - Download transaction
   - Delete transaction if the transaction is settled
   - Cancel transaction if the transaction is settled
5. Monitoring user can:
   - Index transaction
   - Download transaction
6. Sales team can:
   - Index transaction
   - Download transaction
6. Unlogged in user can:
   - Index transaction
   - Download transaction
   - Report fraud
7. Guest user can:
   - Index transaction
   - Download transaction
   - Report fraud

The specification above seems very terrifying, but with Bali, those can be defined in a succinct way, as follow:

```ruby
  Bali.map_rules do
    rules_for My::Transaction do
      describe(:supreme_user) { can_all }
      describe :admin_user do
        can_all
        # a more specific rule would be executed even if can_all is present
        can :cancel,
          if: proc { |record| record.payment_channel == "CREDIT_CARD" &&
                              !record.is_settled? }
      end
      describe "general user", can: [:download]
      describe "finance" do
        can :delete, if: proc { |record| record.is_settled? }
        can :cancel, unless: proc { |record| record.is_settled? }
      end # finance_user description
      describe :guest, nil { can :report_fraud }
      describe :client do
        can :create
      end
      others do
        cannot_all
        can :download, :index
        cannot :create
      end
    end # rules_for
  end
```

## Can and Cant? testing

Assuming that there exist a variable `transaction` which is an instance of `My::Transaction`:

```ruby
transaction.cant?(:general_user, :delete)         # => false
transaction.can("general user", :download)        # => true
transaction.can?(:finance, :delete)               # depends on context
transaction.can?(:monitoring, :index)             # => true
transaction.can?(:sales, :download)               # => true
transaction.can?(:admin_user, :cancel)            # depends on context
transaction.can?(:supreme_user, :cancel)          # => true
transaction.can?(:guest, :download)               # => false
transaction.can?(nil, :download)                  # => true
transaction.can?(nil, :report_fraud)              # => true
transaction.can?(:undefined_subtarget, :see)      # => false
transaction.cant?(:undefined_subtarget, :index)   # => true
transaction.can?(:client, :create)                # => true
transaction.can?(:finance, :create)               # => false
transaction.can?(:admin, :create)                 # => true
```

Rule can also be tested on a class:

```ruby
My::Transaction.can?(:client, :create)              # => true
My::Transaction.can?(:guest, :create)               # => false
My::Employee.can?(:undefined_subtarget, :create)    # => false
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/saveav/bali. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

Bali is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Changelog

Please refer to CHANGELOG.md to see it

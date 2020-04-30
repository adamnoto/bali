# Bali

[![Build Status](https://travis-ci.org/adamnoto/bali.svg?branch=release)](https://travis-ci.org/adamnoto/bali) [![Maintainability](https://api.codeclimate.com/v1/badges/7d8f2d978205bb768d06/maintainability)](https://codeclimate.com/github/adamnoto/bali/maintainability)

Bali is a to-the-point authorization library for Rails. Bali is short for Bulwark Authorization Library.

Why I created Bali?

- I want to segment access rules per roles
- I want to assign those roles to a user
- I don't want to force access rules to match controllers' actions
- I want an intuitive DSL
- I want to easily print those defined roles
- On top of that, it integrates well with Rails (and optionally, RSpec)

## Supported versions

* Ruby 2.4.4 until Ruby 2.7 (trunk)
* Rails 5.0, Rails 6.0, until Rails edge (master)

## Installation

Add this into your gemfile:

```ruby
gem 'bali'
```

And then execute:

    $ bundle

To generate a rule class, for example for a model named `User`:

    $ bundle rails g rules user

We can suplant `User` with something else

## Usage

In a nutshell, authorization rules are to be defined in a class extending `Bali::Rules` (by default located in `app/rules`). We use `can?` and `cant?` to check against those rules which we define using `can`, `cant`, `can_all`, and `cant`. Unscoped rules are inherited, otherwise we can scope rules by defining them within a `role` block.

Given a model as follows:

```ruby
# == Schema Information
#
# Table name: transactions
#
#  id               :bigint           not null, primary key
#  is_settled       :boolean          not null
class Transaction < ApplicationRecord
  alias :settled? :is_settled
end
```

And given the `TransactionRules` defined as follows:

```ruby
class TransactionRules < Bali::Rules
  can :update, :unsettle
  can :print

  # redefine :delete
  can :unsettle do |record, current_user|
    record.settled?
  end

  # will inherit update, and print
  role :supervisor, :accountant do
    can :unsettle
  end

  role :accountant do
    cant :update
  end

  role :supervisor do
    can :comment
  end

  role :clerk do
    cant_all
    can :unsettle
  end

  role :admin do
    can_all
  end
end
```

We can ask various permissions in this way:

```ruby
transaction = Transaction.new
TransactionRules.can?(current_user, :update, transaction)
TransactionRules.cant?(current_user, :update, transaction)
TransactionRules.can?(:archive, transaction)
TransactionRules.can?(:accept_new_transaction)
```

Inside a controller or a view; we can do:

```ruby
if can? current_user, :update, transaction
  # snip snip
end
```

Bali can automatically detect the rule class to use for such a query. That way, we don't have to manually spell out `TransactionRules` when it is clear that the `transaction` is a `Transaction`.

We may also omit `current_user` to make the call shorter and more concise:

```ruby
if can? :update, transaction
  # snip snip
end
```

For more coding examples, please take a look at the written test files. Otherwise, if you may encounter some unclear points, please feel free to suggest for edits. Thank you.

## Testing the rules

Bali is integrated into RSpec pretty well. There's a `be_able_to` matcher that we can use to test the rule:

```ruby
let(:transaction) { Transaction.new }
let(:accountant) { User.new(:accountant) }

# expectation on an instance of a class
it "allows accountant to print, but not update, transaction" do
  expect(accountant).to be_able_to :print, transaction
  expect(accountant).not_to be_able_to :update, transaction
end

# expectation on a class
it "allows User to sign in" do
  expect(User).to be_able_to :sign_in
end
```

## Printing defined roles

```ruby
puts Bali::Printer.printable
```

Or execute:

```
$ rails bali:print_rules
```

Will print, for example, this definition:

```
===== Transaction =====

      By default
      --------------------------------------------------------------------------------
        1. By default can update
        2. By default can unsettle, with condition
        3. By default can print
      Supervisor
      --------------------------------------------------------------------------------
        1. Supervisor can unsettle
        2. Supervisor can comment
      Accountant
      --------------------------------------------------------------------------------
        1. Accountant can unsettle
        2. Accountant cant update
      Clerk
      --------------------------------------------------------------------------------
        1. Clerk can unsettle
      Admin
      --------------------------------------------------------------------------------
        1. Admin can do anything except if explicitly stated otherwise


===== User =====

      By default
      --------------------------------------------------------------------------------
        1. By default can see_timeline, with condition
        2. By default can sign_in, with condition


Printed at 2020-01-01 12:34AM +00:00
```

## Contributing

Bug reports and pull requests are welcome. Bali is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

Bali is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Changelog

Please refer to CHANGELOG.md to see it

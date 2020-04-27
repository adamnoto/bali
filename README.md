# Bali

[ ![Codeship Status for saveav/bali](https://codeship.com/projects/d2f3ded0-20cf-0133-e425-0eade5a669ff/status?branch=release)](https://codeship.com/projects/95727)

[![Maintainability](https://api.codeclimate.com/v1/badges/7d8f2d978205bb768d06/maintainability)](https://codeclimate.com/github/adamnoto/bali/maintainability)

Bali is a to-the-point authorization library for Rails. Bali is short for Bulwark Authorization Library.

Why I created Bali?

- I wasn't able to segment rules per roles
- I want to break free from defining rules to match a controller's actions
- I want to allow single, or multiple (or, even no) roles to be assigned to a user
- I want inheritable system of defining the access/authorization rules
- I want that I can easily print the list of roles possible in my app

## Installation

Add this into your gemfile:

```ruby
gem 'bali'
```

And then execute:

    $ bundle

To generate a rule class for `User` model:

    $ bundle rails g rules user

You can change `User` with any name of your model to define rules on

## Usage

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

We can define the rules this way:

```ruby
class TransactionRules < Bali::Rules
  can :update, :unsettle
  can :print

  # redefine :delete
  can :unsettle do |record|
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

To ask for authorization:

```ruby
transaction = Transaction.new
transaction.can?(current_user, :update)
```

Passing `current_user` is optional. This is also possible:

```ruby
transaction.can?(:archive)
```

It can also works on a class:

```ruby
User.can?(:sign_up)
```

Within a controller or a view in Rails, we can also express authorization in this way:

```ruby
if can? current_user, :update, transaction
  # snip snip
end
```

For more coding example to better understand Bali, we would encourage you to take a look at the written spec files.

## Printing defined roles

```ruby
puts Bali::Printer.pretty_print
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

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

Bali is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Changelog

Please refer to CHANGELOG.md to see it

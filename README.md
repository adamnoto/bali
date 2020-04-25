# Bali

[ ![Codeship Status for saveav/bali](https://codeship.com/projects/d2f3ded0-20cf-0133-e425-0eade5a669ff/status?branch=release)](https://codeship.com/projects/95727)

[![Code Climate](https://codeclimate.com/github/saveav/bali/badges/gpa.svg)](https://codeclimate.com/github/saveav/bali)

Bali is a to-the-point authorization library for Rails. Bali is short for Bulwark Authorization Library.

Why I created Bali?

- I wasn't able to segment rules per roles
- I want to break free from defining rules to match a controller's actions

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

Given a model as follows:

```ruby
class Transaction
  include Bali::Objector

  attr_accessor :is_settled
  attr_accessor :payment_channel

  alias :settled? :is_settled
  alias :settled= :is_settled=
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

For more coding example to better understand Bali, we would encourage you to take a look at the written spec files.

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

Bali is proudly available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Changelog

Please refer to CHANGELOG.md to see it

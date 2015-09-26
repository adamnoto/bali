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

== Version 2.0.0rc1

1. `Bali::AuthorizationError` subclass of `StandardError` tailored for raising error regarding with authorisation
2. Deprecating `cant`, `cant?`, and `cant_all` in favor of `cannot`, `cannot?` and `cannot_all`
3. new objectors `can!` and `cannot!` to raise error on inappropriate access

== Version 2.0.0

1. Release!

== Version 2.1.0

1. `others` block would allow for rule definitions within it to be applied for all undefined subtargets of a target
2. Fixing bug when roles_for of a user object retrieves `nil` as the user's role, it won't acknowledge that the user is indeed having `nil`-role and raising an error instead.
3. Inherits rules by passing `:inherits` option when defining `rules_for`
4. `clear_rules` within `describe` or `others` block to remove all inherited rules (or any rules previously defined) for that subtarget
5. Adding `Bali::Printer` that would enable for rules to be printed by calling `.pretty_print` on it

== Version 2.1.1

1. Bug fixes on `clear_rules` which it clear rules defined in `others` even when not asked to
2. Bug fixes on `Bali::Printer` where inherited rules print the wrong target class due to another bug in an internal file (but doesn't hamper rules-checking logic)

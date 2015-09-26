describe "Printing Bali Rules" do
  before(:all) do
  end # before all

  it "doesn't print others if unnecessary" do
    Bali.map_rules do
      rules_for My::Transaction do
        describe(:supreme_user) { can_all }
        describe(:admin) do
          can_all
          cannot :delete
        end
        describe :finance do
          can :view, :print
          can :edit, :save
        end
        others do
          can :view, if: proc { |txn| txn.is_settled? }
        end
      end

      rules_for My::SecuredTransaction, inherits: My::Transaction do
        describe :finance do
          clear_rules
          can :view
        end
      end # rules for My::SecuredTransaction
    end # map rules
    output = %Q{===== My::Transaction =====

      Supreme_user, can all: true, cannot all: false
      --------------------------------------------------------------------------------
        1. Supreme_user can do anything except if explicitly stated otherwise

      Admin, can all: true, cannot all: false
      --------------------------------------------------------------------------------
        1. Admin can do anything except if explicitly stated otherwise
        2. Admin cannot delete My::Transaction

      Finance, can all: false, cannot all: false
      --------------------------------------------------------------------------------
        1. Finance can view My::Transaction
        2. Finance can print My::Transaction
        3. Finance can edit My::Transaction
        4. Finance can save My::Transaction

      Others, can all: false, cannot all: false
      --------------------------------------------------------------------------------
        1. Others can view My::Transaction, with condition



===== My::SecuredTransaction =====

      Supreme_user, can all: true, cannot all: false
      --------------------------------------------------------------------------------
        1. Supreme_user can do anything except if explicitly stated otherwise

      Admin, can all: true, cannot all: false
      --------------------------------------------------------------------------------
        1. Admin can do anything except if explicitly stated otherwise
        2. Admin cannot delete My::Transaction

      Finance, can all: false, cannot all: false
      --------------------------------------------------------------------------------
        1. Finance can view My::Transaction





Printed at 26-09-2015 12:09PM +07:00}

    expected_output_without_printed_at = output.gsub(/Printed.*/i, "")
    bali_output = Bali::Printer.pretty_print 
    bali_output_without_printed_at = bali_output.gsub(/Printed.*/, "")

    expect(expected_output_without_printed_at).to eq(bali_output_without_printed_at)
  end

  it "print others if necessary" do
    Bali.map_rules do
      rules_for My::Transaction do
        describe :general_user do
          can :edit, :save
        end
        others do
          can :view
        end
      end
    end

    expected_output = "===== My::Transaction =====\n\n      General_user, can all: false, cannot all: false\n      --------------------------------------------------------------------------------\n        1. General_user can edit My::Transaction\n        2. General_user can save My::Transaction\n\n      Others, can all: false, cannot all: false\n      --------------------------------------------------------------------------------\n        1. Others can view My::Transaction\n\n\n\n===== My::SecuredTransaction =====\n\n      Supreme_user, can all: true, cannot all: false\n      --------------------------------------------------------------------------------\n        1. Supreme_user can do anything except if explicitly stated otherwise\n\n      Admin, can all: true, cannot all: false\n      --------------------------------------------------------------------------------\n        1. Admin can do anything except if explicitly stated otherwise\n        2. Admin cannot delete My::Transaction\n\n      Finance, can all: false, cannot all: false\n      --------------------------------------------------------------------------------\n        1. Finance can view My::Transaction\n\n\n\n\n\nPrinted at 26-09-2015 12:19PM +07:00"
    bali_output = Bali::Printer.pretty_print

    # remove date
    expected_output.gsub!(/Printed.*/i, "")
    bali_output.gsub!(/Printed.*/i, "")

    expect(bali_output).to eq(expected_output)
  end

  it "has 'printed at' date" do
    Bali.map_rules do
      rules_for My::Transaction do
        describe(:general_user) do
          can :edit
        end # describe
      end # rules_for
    end # map_rules

    bali_output = Bali::Printer.pretty_print
    expect(bali_output).to match(/Printed at \d\d-\d\d-\d\d\d\d \d\d\:\d\d\w\w \+\d\d\:\d\d/)
  end

end

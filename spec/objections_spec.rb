describe "Model objections" do
  before(:each) { Bali.clear_rules }
  let(:txn) { My::Transaction.new }

  it "should return false to can? for undefined rule class" do
    Bali.rule_class_for(My::Employee).should be_nil
    My::Employee.can?(:undefined_subtarget, :new).should be_falsey
  end

  it "should return true to cant? for undefined rule class" do 
    Bali.rule_class_for(My::Employee).should be_nil
    My::Employee.cant?(:undefined_subtarget, :new).should be_truthy
  end

  it "should return false to can? for undefined rule group" do
    Bali.map_rules do
      rules_for My::Transaction do
      end
    end

    Bali.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    Bali.rule_group_for(My::Transaction, :undefined_subtarget).should be_nil
    My::Transaction.can?(:undefined_subtarget, :new).should be_falsey
  end

  it "should return true to cant? for undefined rule group" do
    Bali.map_rules do
      rules_for My::Transaction do
      end
    end

    Bali.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    Bali.rule_group_for(My::Transaction, :undefined_subtarget).should be_nil
    My::Transaction.cant?(:undefined_subtarget, :new).should be_truthy
  end

  RSpec.shared_examples "objector" do
    it "can answer to can? on a class" do
      My::Transaction.can?(:supreme_user, :new).should be_truthy
      My::Transaction.can?(:general_user, :delete).should be_falsey
    end

    it "can asnwer to cant? on a class" do
      My::Transaction.cant?(:supreme_user, :save).should be_falsey
      My::Transaction.cant?(:general_user, :new).should be_truthy
    end
  end

  context "Abstractly defined rules" do 
    before(:each) do 
      Bali.clear_rules
      Bali.map_rules do 
        rules_for My::Transaction, as: :transaction do
          describe(:supreme_user) { can_all }
          describe(:admin_user) do
            can_all
            cant :delete
          end
          describe(:general_user) do 
            cant_all
            can :view
            can :print, if: proc { |txn| txn.is_settled? }
          end
        end
      end
    end
    
    describe My::Transaction do
      it_behaves_like "objector"

      context "admin user" do 
        it "can do anything, but not delete" do 
          txn.can?(:admin_user, :cancel).should be_truthy
          txn.can?(:admin_user, :delete).should be_falsey
          txn.can?(:admin_user, :create).should be_truthy
          txn.can?(:admin_user, :update).should be_truthy

          txn.cant?(:admin_user, :cancel).should be_falsey
          txn.cant?(:admin_user, :delete).should be_truthy
          txn.cant?(:admin_user, :create).should be_falsey
          txn.cant?(:admin_user, :update).should be_falsey
        end
      end

      context "supreme user" do 
        it "can do anything" do
          txn.can?(:supreme_user, :cancel).should be_truthy
          txn.can?(:supreme_user, :delete).should be_truthy
          txn.can?(:supreme_user, :create).should be_truthy
          txn.can?(:supreme_user, :update).should be_truthy

          txn.cant?(:supreme_user, :cancel).should be_falsey
          txn.cant?(:supreme_user, :delete).should be_falsey
          txn.cant?(:supreme_user, :create).should be_falsey
          txn.cant?(:supreme_user, :update).should be_falsey
        end
      end

      context "general user" do 
        it "cannot do anything" do
          txn.can?(:general_user, :cancel).should be_falsey
          txn.can?(:general_user, :delete).should be_falsey
          txn.can?(:general_user, :create).should be_falsey
          txn.can?(:general_user, :update).should be_falsey

          txn.cant?(:general_user, :cancel).should be_truthy
          txn.cant?(:general_user, :delete).should be_truthy
          txn.cant?(:general_user, :create).should be_truthy
          txn.cant?(:general_user, :update).should be_truthy
        end

        it "can view transaction" do
          txn.can?(:general_user, :view).should be_truthy
          txn.cant?(:general_user, :view).should be_falsey
        end

        it "can print if transaction is settled" do
          txn.is_settled = true
          txn.can?(:general_user, :print).should be_truthy
          txn.cant?(:general_user, :print).should be_falsey
        end

        it "can't print if transaction is not settled" do
          txn.is_settled = false
          txn.can?(:general_user, :print).should be_falsey
          txn.cant?(:general_user, :print).should be_truthy
        end
      end
    end
  end
  
  context "Well defined rules" do
    before(:each) do
      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do
          describe(:supreme_user) { can_all }
          describe :admin_user do
            can_all
            can :cancel, 
              if: proc { |record| record.payment_channel == "CREDIT_CARD" && 
                                  !record.is_settled? }
          end
          describe :general_user, :finance_user, :monitoring do
            can :ask
          end
          describe "general user", can: [:view, :edit, :update], cant: [:delete]
          describe "finance user" do
            can :update, :delete, :edit
            can :delete, if: proc { |record| record.is_settled? }
          end # finance_user description
          describe :monitoring do
            cant_all
            can :monitor
          end
          describe nil do
            can :view
          end
        end # rules_for
      end
    end # before each

    describe My::Transaction do
      it_behaves_like "objector"

      context "multi-role" do
        it "allows user with role of nil and supreme to be able to do everything" do
          roles1, roles2 = [nil, :supreme_user], [:supreme_user, nil]

          txn.can?(nil, :monitor).should be_falsey
          txn.cant?(nil, :monitor).should be_truthy
          txn.can?(roles1, :monitor).should be_truthy
          txn.can?(roles2, :monitor).should be_truthy
          txn.cant?(roles1, :monitor).should be_falsey
          txn.cant?(roles2, :monitor).should be_falsey

          txn.can?(roles1, :delete).should be_truthy
          txn.can?(roles2, :delete).should be_truthy
          txn.can?(roles1, :cancel).should be_truthy
          txn.can?(roles2, :cancel).should be_truthy

          txn.cant?(roles1, :delete).should be_falsey
          txn.cant?(roles2, :delete).should be_falsey
          txn.cant?(roles1, :cancel).should be_falsey
          txn.cant?(roles2, :cancel).should be_falsey
        end

        it "allows user with role of admin and finance user to delete regardless whether transaction is settled or not" do
          roles1, roles2 = [:admin_user, :finance_user], [:finance_user, :admin_user]

          txn.is_settled = false
          txn.can?(:admin_user, :delete).should be_truthy
          txn.cant?(:admin_user, :delete).should be_falsey
          txn.can?(:finance_user, :delete).should be_falsey
          txn.cant?(:finance_user, :delete).should be_truthy

          [true, false].each do |settlement_status|
            txn.is_settled = settlement_status

            txn.can?(roles1, :delete).should be_truthy
            txn.can?(roles2, :delete).should be_truthy
            txn.cant?(roles1, :delete).should be_falsey
            txn.cant?(roles2, :delete).should be_falsey
          end
        end

        it "allows user with role of general user and finance user to delete settled transaction" do
          roles1, roles2 = [:general_user, :finance_user], [:finance_user, :general_user]

          txn.is_settled = true
          txn.can?(roles1, :delete).should be_truthy
          txn.can?(roles2, :delete).should be_truthy
          txn.cant?(roles1, :delete).should be_falsey
          txn.cant?(roles2, :delete).should be_falsey

          txn.is_settled = false
          txn.can?(roles1, :delete).should be_falsey
          txn.can?(roles2, :delete).should be_falsey
          txn.cant?(roles1, :delete).should be_truthy
          txn.cant?(roles2, :delete).should be_truthy
        end

        it "allows user with role of finance and monitoring to monitor" do
          txn.can?(:finance_user, :monitor).should be_falsey
          txn.can?(:monitoring, :monitor).should be_truthy
          txn.cant?(:finance_user, :monitor).should be_truthy
          txn.cant?(:monitoring, :monitor).should be_falsey

          txn.can?([:monitoring, :finance_user], :monitor).should be_truthy
          txn.can?([:finance_user, :monitoring], :monitor).should be_truthy

          txn.cant?([:monitoring, :finance_user], :monitor).should be_falsey
          txn.cant?([:finance_user, :monitoring], :monitor).should be_falsey
        end
      end

      context "unauthenticated/nil-role user" do
        it "can view transaction" do
          txn.can?(nil, :view).should be_truthy
        end

        it "can't edit or update transaction" do
          txn.can?(nil, :edit).should be_falsey
          txn.can?(nil, :update).should be_falsey
        end
      end

      context "general user" do
        it "can ask" do
          txn.can?(:general_user, :ask).should be_truthy
          txn.cant?("general user", :ask).should be_falsey
        end

        it "can view transaction" do
          txn.can?("general user", :view).should be_truthy
        end

        it "can edit transaction" do
          txn.can?(:general_user, :edit).should be_truthy
        end

        it "can update transaction" do
          txn.can?(:general_user, :update).should be_truthy
        end

        it "cannot delete transaction" do
          txn.can?("general user", :delete).should be_falsey
          Bali.rule_group_for(txn.class, "general user").get_rule(:cant, :delete)
            .class.should == Bali::Rule
        end

        context "undefined rule" do
          it "cannot save transaction" do
            txn.can?("general user", :save).should be_falsey
          end
        end

        it "can check rule by using symbol, instead of a String" do
          txn.can?("general user", :update).should == txn.can?(:general_user, :update)
        end
      end

      context "finance user" do
        it "can ask" do
          txn.can?("finance user", :ask).should be_truthy
          txn.cant?(:finance_user, :ask).should be_falsey
        end

        it "can update and edit transaction" do
          txn.can?(:finance_user, :update).should be_truthy
          txn.can?(:finance_user, :edit).should be_truthy
        end

        it "cannot delete when transaction is not settled" do
          txn.is_settled = false
          txn.can?(:finance_user, :delete).should be_falsey
        end

        it "can delete when transaction is settled" do
          txn.is_settled = true
          txn.can?(:finance_user, :delete).should be_truthy
        end
      end    

      context "admin user" do
        it "can update and edit transaction" do
          txn.can?(:admin_user, :update).should be_truthy
          txn.can?(:admin_user, :edit).should be_truthy
        end

        it "can delete transation, whether settled or not" do
          txn.is_settled = false
          txn.can?(:admin_user, :delete).should be_truthy
          
          txn.is_settled = true
          txn.can?(:admin_user, :delete).should be_truthy
        end

        it "cannot cancel transaction if it is not a credit card payment" do
          txn.payment_channel = "BANK_IN"
          txn.can?(:admin_user, :cancel).should be_falsey
        end

        it "cannot cancel credit card transaction if it is already settled" do
          txn.is_settled = true
          txn.payment_channel = "CREDIT_CARD"
          txn.can?(:admin_user, :cancel).should be_falsey
        end

        it "can cancel a settled, credit card transaction" do
          txn.is_settled = false
          txn.payment_channel = "CREDIT_CARD"
          txn.can?(:admin_user, :cancel).should be_truthy
        end
      end

      context "supreme user" do
        it "can do anything" do
          txn.can?(:supreme_user, :cancel).should be_truthy
          txn.can?(:supreme_user, :delete).should be_truthy
          txn.can?(:supreme_user, :create).should be_truthy
          txn.can?(:supreme_user, :update).should be_truthy
        end
      end

      it "can answer to can?" do
        My::Transaction.can?(:supreme_user, :delete).should be_truthy
        My::Transaction.can?(:admin_user, :delete).should be_truthy
        My::Transaction.can?(:general_user, :view).should be_truthy
        My::Transaction.can?(:general_user, :delete).should be_falsey
        My::Transaction.can?(:general_user, :do_something_undefined).should be_falsey
        My::Transaction.can?(:finance_user, :update).should be_truthy
        My::Transaction.can?(:finance_user, :save).should be_falsey
        My::Transaction.can?(:monitoring, :read).should be_falsey
        My::Transaction.can?(:monitoring, :monitor).should be_truthy
        My::Transaction.can?(:monitoring, :ask).should be_truthy
        My::Transaction.can?(nil, :view).should be_truthy
        My::Transaction.can?(nil, :save).should be_falsey
      end

      it "can answer to cant?" do
        My::Transaction.cant?(:supreme_user, :delete).should be_falsey
        My::Transaction.cant?(:admin_user, :delete).should be_falsey
        My::Transaction.cant?(:general_user, :edit).should be_falsey
        My::Transaction.cant?(:general_user, :view).should be_falsey
        My::Transaction.cant?(:general_user, :delete).should be_truthy
        My::Transaction.cant?(:finance_user, :update).should be_falsey
        My::Transaction.cant?(:finance_user, :new).should be_truthy
        My::Transaction.cant?(:monitoring, :read).should be_truthy
        My::Transaction.cant?(:monitoring, :monitor).should be_falsey
        My::Transaction.cant?(nil, :view).should be_falsey
        My::Transaction.cant?(nil, :save).should be_truthy
      end

    end
  end
end

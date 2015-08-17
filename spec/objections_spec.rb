describe "Model objections" do
  let(:txn) { My::Transaction.new }

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
      Bali.map_rules do 
        rules_for My::Transaction, as: :transaction do
          describe(:supreme_user) { can_all }
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

      context "supreme user" do 
        it "can do anything" do
          txn.can?(:supreme_user, :cancel).should be_truthy
          txn.can?(:supreme_user, :delete).should be_truthy
          txn.can?(:supreme_user, :create).should be_truthy
          txn.can?(:supreme_user, :update).should be_truthy
        end
      end

      context "general user" do 
        it "cannot do anything" do
          txn.can?(:general_user, :cancel).should be_falsey
          txn.can?(:general_user, :delete).should be_falsey
          txn.can?(:general_user, :create).should be_falsey
          txn.can?(:general_user, :update).should be_falsey
        end

        it "can view transaction" do
          txn.can?(:general_user, :view).should be_truthy
        end

        it "can print if transaction is settled" do
          txn.is_settled = true
          txn.can?(:general_user, :print).should be_truthy
        end

        it "can't print if transaction is not settled" do
          txn.is_settled = false
          txn.can?(:general_user, :print).should be_falsey
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
          describe "general user", can: [:view, :edit, :update], cant: [:delete]
          describe "finance user" do
            can :update, :delete, :edit
            can :delete, if: proc { |record| record.is_settled? }
          end # finance_user description
          describe nil do
            can :view
          end
        end # rules_for
      end
    end # before each

    describe My::Transaction do
      it_behaves_like "objector"

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

    end
  end
end

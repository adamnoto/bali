describe "Model objections" do
  before(:each) { Bali.clear_rules }
  let(:txn) { My::Transaction.new }
  let(:me)  { My::Employee.new }

  it "should return false to can? for undefined rule class" do
    Bali::Integrator::RuleClass.for(My::Employee).should be_nil
    My::Employee.can?(:undefined_subtarget, :new).should be_falsey
  end

  it "should return true to cant? for undefined rule class" do
    Bali::Integrator::RuleClass.for(My::Employee).should be_nil
    My::Employee.cant?(:undefined_subtarget, :new).should be_truthy
  end

  it "should return false to can? for undefined rule group" do
    Bali.map_rules do
      rules_for My::Transaction do
      end
    end

    Bali::Integrator::RuleClass.for(My::Transaction).class.should == Bali::RuleClass
    Bali::Integrator::RuleGroup.for(My::Transaction, :undefined_subtarget).should be_nil
    My::Transaction.can?(:undefined_subtarget, :new).should be_falsey
  end

  it "should return true to cant? for undefined rule group" do
    Bali.map_rules do
      rules_for My::Transaction do
      end
    end

    Bali::Integrator::RuleClass.for(My::Transaction).class.should == Bali::RuleClass
    Bali::Integrator::RuleGroup.for(My::Transaction, :undefined_subtarget).should be_nil
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

  context "when using delegation" do
    before do
      Bali.map_rules do
        roles_for My::Employee, :roles
        rules_for 'My::Transaction' do
          role :admin, :general_user do
            can :show, :edit, :new
          end
          role :general_user do
            can :copy
          end
          role :admin do
            can :delete
          end
          role nil, can: [:show]
        end
      end
    end

    let(:txn) { My::Transaction.new }

    it "can query when role is a symbol" do
      me.roles = :general_user
      expect(txn.can?(me, :copy)).to be_truthy
      expect(txn.cant?(me, :copy)).to be_falsey

      expect(txn.can?(me, :delete)).to be_falsey
      expect(txn.cant?(me, :delete)).to be_truthy
    end

    it "can query when role is a string" do
      me.roles = "general user"
      expect(txn.can?(me, :copy)).to be_truthy
      expect(txn.cant?(me, :copy)).to be_falsey

      expect(txn.can?(me, :delete)).to be_falsey
      expect(txn.cant?(me, :delete)).to be_truthy
    end

    it "can query when role is nil" do
      me.roles = nil
      expect(txn.can?(me, :copy)).to be_falsey
      expect(txn.cant?(me, :copy)).to be_truthy

      expect(txn.can?(me, :delete)).to be_falsey
      expect(txn.cant?(me, :delete)).to be_truthy

      expect(txn.can?(me, :show)).to be_truthy
      expect(txn.cant?(me, :show)).to be_falsey
    end

    it "can query when role is an array" do
      me.roles = [:general_user]

      txn.can?(:general_user, :copy).should be_truthy
      txn.can?(me, :copy).should be_truthy

      me.roles = [:admin]
      txn.can?(:admin, :delete).should be_truthy
      txn.can?(me, :delete).should be_truthy

      me.roles = [:admin, :general_user]
      txn.can?(me, :delete).should be_truthy
      txn.can?(me, :copy).should be_truthy
      txn.can?(me, :edit).should be_truthy
    end

    it "can query rule having if decider" do
      Bali.map_rules do
        roles_for My::Employee, :roles
        rules_for My::Transaction do
          role :admin, :general_user do
            can :show
          end
          role :general_user do
            can :edit, if: proc { |record, user| user.exp_years > 3 }
            can :cancel, if: proc { |record, user| !record.is_settled? && user.exp_years > 3 }
          end
          role(:admin) { can_all }
        end
      end

      txn.is_settled = false
      me.roles = [:general_user]

      txn.can?(me, :show).should be_truthy
      txn.cant?(me, :show).should be_falsey

      me.exp_years = 2
      txn.can?(me, :edit).should be_falsey
      txn.cant?(me, :edit).should be_truthy

      me.exp_years = 3
      txn.can?(me, :edit).should be_falsey
      txn.cant?(me, :edit).should be_truthy

      me.exp_years = 4
      txn.can?(me, :edit).should be_truthy
      txn.cant?(me, :edit).should be_falsey

      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :cancel).should be_falsey

      txn.is_settled = true
      txn.can?(me, :cancel).should be_falsey
      txn.cant?(me, :cancel).should be_truthy

      me.roles = :admin
      me.exp_years = 0
      txn.is_settled = true
      txn.can?(me, :show).should be_truthy
      txn.can?(me, :edit).should be_truthy
      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :show).should be_falsey
      txn.cant?(me, :edit).should be_falsey
      txn.cant?(me, :cancel).should be_falsey

      me.roles = [:general_user, :admin]
      txn.can?(me, :show).should be_truthy
      txn.can?(me, :edit).should be_truthy
      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :show).should be_falsey
      txn.cant?(me, :edit).should be_falsey
      txn.cant?(me, :cancel).should be_falsey
    end

    it "can query rule having unless decider" do
      Bali.map_rules do
        roles_for My::Employee, :roles
        rules_for My::Transaction do
          role :general_user do
            can :show
            can :edit, unless: proc { |record, user|
              (user.exp_years <= 3)
            }
            can :cancel, unless: proc { |record, user|
              record.is_settled? && (user.exp_years > 3)
            }
          end
          role(:admin) { can_all }
        end
      end

      txn.is_settled = false
      me.roles = [:general_user]

      txn.can?(me, :show).should be_truthy
      txn.cant?(me, :show).should be_falsey

      me.exp_years = 2
      txn.can?(me, :edit).should be_falsey
      txn.cant?(me, :edit).should be_truthy
      me.exp_years = 3
      txn.can?(me, :edit).should be_falsey
      txn.cant?(me, :edit).should be_truthy
      me.exp_years = 4
      txn.can?(me, :edit).should be_truthy
      txn.cant?(me, :edit).should be_falsey

      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :cancel).should be_falsey
      txn.is_settled = true
      txn.can?(me, :cancel).should be_falsey
      txn.cant?(me, :cancel).should be_truthy

      me.roles = :admin
      me.exp_years = 0
      txn.is_settled = true
      txn.can?(me, :show).should be_truthy
      txn.can?(me, :edit).should be_truthy
      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :show).should be_falsey
      txn.cant?(me, :edit).should be_falsey
      txn.cant?(me, :cancel).should be_falsey

      me.roles = [:general_user, :admin]
      txn.can?(me, :show).should be_truthy
      txn.can?(me, :edit).should be_truthy
      txn.can?(me, :cancel).should be_truthy
      txn.cant?(me, :show).should be_falsey
      txn.cant?(me, :edit).should be_falsey
      txn.cant?(me, :cancel).should be_falsey
    end
  end

  context "When having others block" do
    before(:each) do
      Bali.clear_rules
      Bali.map_rules do
        rules_for My::Transaction do
          role(:supreme_user) { can_all }
          role :admin do
            can_all
            cant :delete
          end
          role :finance do
            cant :view
            can :print
          end
          others do
            can :view, if: proc { |txn| txn.is_settled? }
            can :print, if: proc { |txn| txn.is_settled? }
            can :index
          end # others
        end # rules_for

        rules_for My::SecuredTransaction, inherits: My::Transaction do
          role :finance do
            cant_all
          end
        end
      end # map rules
    end # before

    let(:txn) { My::Transaction.new }

    describe "supreme user" do
      it "should allow to delete transaction" do
        expect(txn.can?(:supreme_user, :delete)).to be_truthy
        expect(txn.cant?(:supreme_user, :delete)).to be_falsey
      end

      it "should allow to print transaction" do
        # expect(txn.can?(:supreme_user, :print)).to be_truthy
        expect(txn.cant?(:supreme_user, :print)).to be_falsey
      end

      it "should allow to index transaction" do
        expect(txn.can?(:supreme_user, :index)).to be_truthy
        expect(txn.cant?(:supreme_user, :index)).to be_falsey
      end
    end # supreme user

    describe "admin user" do
      it "should not allow to delete transaction" do
        expect(txn.can?(:admin, :delete)).to be_falsey
        # expect(txn.cant?(:admin, :delete)).to be_truthy
      end

      it "should allow to print transaction" do
        expect(txn.can?(:admin, :print)).to be_truthy
        expect(txn.cant?(:admin, :print)).to be_falsey
      end
    end # admin user

    describe "finance user" do
      it "should not allow to view transaction" do
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy
      end

      it "should not allow finance to view secured transaction" do
        stxn = My::SecuredTransaction.new
        stxn.is_settled = true
        expect(stxn.can?(:finance, :view)).to be_falsey
        expect(stxn.cant?(:finance, :view)).to be_truthy
      end

      it "should allow finance to print" do
        txn.settled = true
        # expect(txn.is_settled?).to be_truthy
        # expect(txn.can?(:finance, :print)).to be_truthy
        expect(txn.cant?(:finance, :print)).to be_falsey

        txn.settled = false
        # expect(txn.is_settled?).to be_falsey
        # expect(txn.can?(:finance, :print)).to be_truthy
        # expect(txn.cant?(:finance, :print)).to be_falsey
      end

      it "should not allow finance to view even if transaction is settled" do
        txn.settled = true
        expect(txn.is_settled).to be_truthy
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy

        txn.settled = false
        expect(txn.is_settled).to be_falsey
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy
      end

      it "should allow finance to index transaction" do
        # expect(txn.can?(:finance, :index)).to be_truthy
        expect(txn.cant?(:finance, :index)).to be_falsey
      end
    end # finance_user

    context "when on undefined class" do
      it "should not allow employee to be created" do
        expect(My::Employee.can?(:finance, :create)).to be_falsey
        expect(My::Employee.cant?(:finance, :create)).to be_truthy
      end
    end
  end

  context "When having abstractly defined rules" do
    before(:each) do
      Bali.clear_rules
      Bali.map_rules do
        rules_for My::Transaction do
          role(:supreme_user) { can_all }
          role :admin do
            can_all
            cant :delete
          end
          role :finance do
            cant :view
            can :print
          end
          others do
            can :view, if: proc { |txn| txn.is_settled? }
            can :print, if: proc { |txn| txn.is_settled? }
            can :index
          end # others
        end # rules_for
      end # map rules
    end # before

    let(:txn) { My::Transaction.new }

    describe "supreme user" do
      it "should allow to delete transaction" do
        expect(txn.can?(:supreme_user, :delete)).to be_truthy
        expect(txn.cant?(:supreme_user, :delete)).to be_falsey
      end

      it "should allow to print transaction" do
        expect(txn.can?(:supreme_user, :print)).to be_truthy
        expect(txn.cant?(:supreme_user, :print)).to be_falsey
      end

      it "should allow to index transaction" do
        expect(txn.can?(:supreme_user, :index)).to be_truthy
        expect(txn.cant?(:supreme_user, :index)).to be_falsey
      end
    end # supreme user

    describe "admin user" do
      it "should not allow to delete transaction" do
        expect(txn.can?(:admin, :delete)).to be_falsey
        expect(txn.cant?(:admin, :delete)).to be_truthy
      end

      it "should allow to print transaction" do
        expect(txn.can?(:admin, :print)).to be_truthy
        expect(txn.cant?(:admin, :print)).to be_falsey
      end
    end # admin user

    describe "finance user" do
      it "should not allow to view" do
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy
      end

      it "should allow finance to print" do
        txn.settled = true
        expect(txn.is_settled?).to be_truthy
        expect(txn.can?(:finance, :print)).to be_truthy
        expect(txn.cant?(:finance, :print)).to be_falsey

        txn.settled = false
        expect(txn.is_settled?).to be_falsey
        expect(txn.can?(:finance, :print)).to be_truthy
        expect(txn.cant?(:finance, :print)).to be_falsey
      end

      it "should not allow finance to view even if transaction is settled" do
        txn.settled = true
        expect(txn.is_settled).to be_truthy
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy

        txn.settled = false
        expect(txn.is_settled).to be_falsey
        expect(txn.can?(:finance, :view)).to be_falsey
        expect(txn.cant?(:finance, :view)).to be_truthy
      end

      it "should allow finance to index transaction" do
        expect(txn.can?(:finance, :index)).to be_truthy
        expect(txn.cant?(:finance, :index)).to be_falsey
      end
    end # finance_user

    context "when on undefined class" do
      it "should not allow employee to be created" do
        expect(My::Employee.can?(:finance, :create)).to be_falsey
        expect(My::Employee.cant?(:finance, :create)).to be_truthy
      end
    end
  end

  context "When having abstractly defined rules" do
    before(:each) do
      Bali.clear_rules
      Bali.map_rules do
        rules_for My::Transaction do
          role(:supreme_user) { can_all }
          role :admin_user do
            can_all
            cant :delete
          end
          role :general_user do
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
        it "cant do anything" do
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
        rules_for My::Transaction do
          role(:supreme_user) { can_all }
          role :admin_user do
            can_all
            can :cancel,
              if: proc { |record| record.payment_channel == "CREDIT_CARD" &&
                                  !record.is_settled? }
          end
          role :general_user, :finance_user, :monitoring do
            can :ask
          end
          role "general user", can: [:view, :edit, :update], cant: [:delete]
          role "finance user" do
            can :update, :delete, :edit
            can :delete, :undelete, if: proc { |record| record.is_settled? }
          end # finance_user description
          role :monitoring do
            cant_all
            can :monitor
          end
          role nil do
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

        # this also test that rules with decider described simultaneously
        # is also working as expected
        it "allows undeleting with role of finance" do
          txn.is_settled = false
          expect(txn.can?(:finance_user, :undelete)).to be_falsey
          txn.is_settled = true
          expect(txn.can?(:finance_user, :undelete)).to be_truthy
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

        it "cant delete transaction" do
          txn.can?("general user", :delete).should be_falsey
          Bali::Integrator::RuleGroup.for(txn.class, "general user").get_rule(:cant, :delete)
            .class.should == Bali::Rule
        end

        context "undefined rule" do
          it "cant save transaction" do
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

        it "cant delete when transaction is not settled" do
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

        it "cant cancel transaction if it is not a credit card payment" do
          txn.payment_channel = "BANK_IN"
          txn.can?(:admin_user, :cancel).should be_falsey
        end

        it "cant cancel credit card transaction if it is already settled" do
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

    context "when clearing rules" do
      before do
        Bali.map_rules do
          rules_for My::SecuredTransaction, inherits: My::Transaction do
            role :general_user do
              clear_rules
              can :view
            end
          end
        end
      end

      let(:stxn) { My::SecuredTransaction.new }

      context "general user" do
        it "can view transaction" do
          expect(stxn.can?(:general_user, :view)).to be_truthy
          expect(stxn.cant?(:general_user, :view)).to be_falsey
        end

        it "canot ask" do
          expect(stxn.can?(:general_user, :ask)).to be_falsey
          expect(stxn.cant?(:general_user, :ask)).to be_truthy
        end

        it "cant edit" do
          expect(stxn.can?(:general_user, :edit)).to be_falsey
          expect(stxn.cant?(:general_user, :edit)).to be_truthy
        end

        it "cant delete" do
          expect(stxn.can?(:general_user, :delete)).to be_falsey
          expect(stxn.cant?(:general_user, :delete)).to be_truthy
        end

        it "cant edit" do
          expect(stxn.can?(:general_user, :edit)).to be_falsey
          expect(stxn.cant?(:general_user, :edit)).to be_truthy
        end
      end
    end

    context "cloned for My::SecuredTransaction" do
      before(:each) do
        Bali.map_rules do
          roles_for My::Employee, :roles
          rules_for My::SecuredTransaction, inherits: My::Transaction do
            role :admin_user do
              # only overwrite cancel
              can :cancel, if: proc { |record, user|
                record.payment_channel == "CREDIT_CARD" && !record.is_settled &&
                  user.exp_years >= 3
              }
            end
            role :general_user do
              cant :update, :edit
            end
            role :finance_user do
              cant :delete
            end
            role(nil) { cant_all }
          end
        end # map_rules
      end # before

      let(:stxn) { My::SecuredTransaction.new }

      context "admin user" do
        it "can edit" do
          expect(stxn.can?(:admin_user, :edit)).to be_truthy
          # expect(stxn.cant?(:admin_user, :edit)).to be_falsey
        end

        it "can cancel only if payment channel is credit card, and it is not settled, and admin have had 3 years experience" do
          emp = My::Employee.new
          emp.roles = [:admin_user]
          emp.exp_years = 3
          stxn.payment_channel = "CREDIT_CARD"
          stxn.is_settled = false

          expect(stxn.can?(emp, :cancel)).to be_truthy
          expect(stxn.cant?(emp, :cancel)).to be_falsey

          emp.exp_years = 2
          expect(stxn.can?(emp, :cancel)).to be_falsey
          expect(stxn.cant?(emp, :cancel)).to be_truthy
          emp.exp_years = 3

          stxn.payment_channel = "VIRTUAL_ACCOUNT"
          expect(stxn.can?(emp, :cancel)).to be_falsey
          expect(stxn.cant?(emp, :cancel)).to be_truthy
          stxn.payment_channel = "CREDIT_CARD"

          stxn.is_settled = true
          expect(stxn.can?(emp, :cancel)).to be_falsey
          expect(stxn.cant?(emp, :cancel)).to be_truthy
          stxn.is_settled = false

          expect(stxn.can?(emp, :cancel)).to be_truthy
        end
      end

      context "general user" do
        it "cant update" do
          expect(stxn.can?(:general_user, :update)).to be_falsey
          expect(stxn.cant?(:general_user, :update)).to be_truthy
        end

        it "cant edit" do
          expect(stxn.can?(:general_user, :edit)).to be_falsey
          expect(stxn.cant?(:general_user, :edit)).to be_truthy
        end

        it "can view" do
          expect(stxn.can?(:general_user, :view)).to be_truthy
          expect(stxn.cant?(:general_user, :view)).to be_falsey
        end

        it "can ask" do
          expect(stxn.can?(:general_user, :ask)).to be_truthy
          expect(stxn.cant?(:general_user, :ask)).to be_falsey
        end
      end

      context "monitoring" do
        it "can monitor" do
          expect(stxn.can?(:monitoring, :monitor)).to be_truthy
          expect(stxn.cant?(:monitoring, :monitor)).to be_falsey
        end
      end

      context "finance user" do
        it "can update" do
          expect(stxn.can?(:finance_user, :update)).to be_truthy
          expect(stxn.cant?(:finance_user, :update)).to be_falsey
        end

        it "can edit" do
          expect(stxn.can?(:finance_user, :edit)).to be_truthy
          expect(stxn.cant?(:finance_user, :edit)).to be_falsey
        end

        it "cant delete" do
          expect(stxn.can?(:finance_user, :delete)).to be_falsey
          expect(stxn.cant?(:finance_user, :delete)).to be_truthy
        end
      end
    end
  end

  it "should respect precedence" do
    Bali.map_rules do
      rules_for My::Transaction do
        role :user do
          cant_all
          can :show

          cant :edit
          can :edit

          can :update
          cant :update
        end
      end
    end

    txn = My::Transaction.new
    txn.can?(:user, :show).should be_truthy
    txn.cant?(:user, :show).should be_falsey

    txn.can?(:user, :edit).should be_truthy
    txn.cant?(:user, :edit).should be_falsey

    txn.can?(:user, :update).should be_falsey
    txn.cant?(:user, :update).should be_truthy
  end
end

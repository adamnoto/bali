describe Bali do
  it 'has a version number' do
    expect(Bali::VERSION).not_to be nil
  end

  context "DSL" do
    before(:each) do
      Bali.clear_rules
    end

    context "delegating way to obtain roles with roles_for" do
      it "doesn't throw error when defining delegation for querying roles" do
        expect do
          Bali.map_rules do
            roles_for My::Employee, :roles
          end
        end.to_not raise_error

        Bali::TRANSLATED_SUBTARGET_ROLES["My::Employee"].should == :roles
      end
    end

    context "when describing rules_for" do
      it "throws error when rules_for is used for other than a class" do
        expect do
          Bali.map_rules do
            rules_for "my string" do
            end
          end.to raise_error(Bali::DslError)
        end
      end

      it "does not throw an error when rules_for is used with a class" do
        expect do
          Bali.map_rules do
            rules_for My::String do
            end
          end.to_not raise_error
        end
      end

      it "should redefine rule if same operation is re-described" do
        Bali::Integrators::Rule.rule_classes.size.should == 0

        Bali.map_rules do
          rules_for My::Transaction do
            describe :general_user do |record|
              can :update, :delete
              can :delete, if: -> { record.is_settled? }
            end
          end
        end

        rc = Bali::Integrators::Rule.rule_class_for(My::Transaction)
        expect(rc.rules_for(:general_user).get_rule(:can, :delete).has_decider?)
          .to eq(true)
      end

      it "does not allow subtarget definition other than using string, symbol, array and hash" do
        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                can :print
              end
            end
          end
        end.to_not raise_error

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe "finance user" do
                can :print
              end
            end
          end
        end.to_not raise_error

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe [:general_user, "finance user"] do
                can :print
              end
            end
          end
        end.to_not raise_error

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user, can: [:print]
            end
          end
        end.to_not raise_error

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user, :finance_user, [:guess, nil], can: [:show] do
                can :print
              end
            end
          end
        end.to_not raise_error
      end

      context "when inheriting" do
        it "throws error when inheriting undefined rule class" do
          expect do
            Bali.map_rules do
              rules_for My::Transaction, inherits: My::SecuredTransaction do
              end 
            end
          end.to raise_error(Bali::DslError)
        end

        it "does not throw an error when inheriting defined rule class" do
          expect do
            Bali.map_rules do
              rules_for My::Transaction do
              end
              rules_for My::SecuredTransaction do
              end
            end
          end.to_not raise_error
        end
      end
    end

    context "when describing each rules using describe" do
      it "can define nil rule group" do
        expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
        Bali.map_rules do
          rules_for My::Transaction do
            describe nil do
              can :view
            end
          end
        end
        Bali::Integrators::Rule.rule_classes.size.should == 1
        Bali::Integrators::Rule.rule_class_for(My::Transaction).class.should == Bali::RuleClass
      end

      it "disallows calling describe outside of rules_for" do
        expect do
          Bali.map_rules do
            describe :general_user, can: :show
          end.to raise_error(Bali::DslError)
        end

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                can :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling can outside of describe block" do
        expect do
          Bali.map_rules do
            can :show
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                can :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling cannot outside of describe block" do
        expect do
          Bali.map_rules do
            cannot :show
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                cannot :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling can_all outside of describe block" do
        expect do
          Bali.map_rules do
            can_all
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                can_all
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling cannot_all outside of describe block" do
        expect do
          Bali.map_rules do
            cannot_all
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :general_user do
                cannot_all
              end
            end
          end
        end.to_not raise_error
      end
    end # context describe

    context "others" do
      it "disallow calling others outside of rules_for" do
        expect do
          Bali.map_rules do
            others can: :show
          end.to raise_error(Bali::DslError)
        end

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              others do
                can :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling can outside of others block" do
        expect do
          Bali.map_rules do
            can :show
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              others do
                can :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling cannot outside of others block" do
        expect do
          Bali.map_rules do
            cannot :show
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              others do
                cannot :show
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling can_all outside of describe block" do
        expect do
          Bali.map_rules do
            can_all
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              others do
                can_all
              end
            end
          end
        end.to_not raise_error
      end

      it "disallows calling cannot_all outside of describe block" do
        expect do
          Bali.map_rules do
            cannot_all
          end
        end.to raise_error(Bali::DslError)

        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              others do
                cannot_all
              end
            end
          end
        end.to_not raise_error
      end
    end # context others

    it "allows definition of rules per subtarget" do
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: :show
          describe :finance_user do
            can :update, :delete, :edit
            can :delete, if: proc { |record| record.is_settled? }
          end
        end
      end
      Bali::Integrators::Rule.rule_classes.size.should == 1
      Bali::Integrators::Rule.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    end

    it "allows definition of rules per multiple subtarget" do
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction do
          describe(:general_user, :finance_user, can: [:show])
          describe :general_user, :finance_user do
            can :print
          end
          describe :finance_user do
            can :delete, if: proc { |record| record.is_settled? }
          end
        end
      end

      Bali::Integrators::Rule.rule_classes.size.should == 1
      Bali::Integrators::Rule.rule_class_for(My::Transaction).class.should == Bali::RuleClass

      rule_group_gu = Bali::Integrators::Rule.rule_group_for(My::Transaction, :general_user)
      rule_group_fu = Bali::Integrators::Rule.rule_group_for(My::Transaction, :finance_user)

      rule_group_gu.get_rule(:can, :show).class.should == Bali::Rule
      rule_group_gu.get_rule(:can, :print).class.should == Bali::Rule
      rule_group_fu.get_rule(:can, :show).class.should == Bali::Rule
      rule_group_gu.get_rule(:can, :print).class.should == Bali::Rule
      rule_group_fu.get_rule(:can, :delete).class.should == Bali::Rule
      rule_group_gu.get_rule(:can, :delete).class.should == NilClass
    end

    it "does not allowe describe without rules_for" do
      expect do
        Bali.map_rules do
          describe :general_user, can: [:print]
        end
      end.to raise_error(Bali::DslError)
    end



    it "allows if-decider to be executed in context" do
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction do
          describe :finance_user do
            can :delete, if: proc { |record| record.is_settled? }
            cannot :payout, if: proc { |record| !record.is_settled? }
          end
        end
      end

      txn = My::Transaction.new
      txn.is_settled = false
      txn.can?(:finance_user, :delete).should be_falsey
      txn.cannot?(:finance_user, :delete).should be_truthy
      txn.can?(:finance_user, :payout).should be_falsey
      txn.cannot?(:finance_user, :payout).should be_truthy

      txn.is_settled = true
      txn.can?(:finance_user, :delete).should be_truthy
      txn.cannot?(:finance_user, :delete).should be_falsey
      txn.can?(:finance_user, :payout).should be_truthy
      txn.cannot?(:finance_user, :payout).should be_falsey

      # reverse meaning of the above, should return the same
      Bali.clear_rules
      Bali.map_rules do
        rules_for My::Transaction do
          describe :finance_user do
            cannot :delete, unless: proc { |record| record.is_settled? }
            can :payout, unless: proc { |record| !record.is_settled? }
          end
        end
      end

      txn = My::Transaction.new
      txn.is_settled = false
      txn.can?(:finance_user, :delete).should be_falsey
      txn.cannot?(:finance_user, :delete).should be_truthy

      txn.is_settled = true
      txn.can?(:finance_user, :delete).should be_truthy
      txn.cannot?(:finance_user, :delete).should be_falsey
    end

    it "allows unless-decider to be executed in context" do
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction do
          describe :finance_user do
            cannot :chargeback, unless: proc { |record| record.is_settled? }
          end
        end
      end

      txn = My::Transaction.new
      txn.is_settled = false
      txn.cannot?(:finance_user, :chargeback).should be_truthy
      txn.can?(:finance_user, :chargeback).should be_falsey

      txn.is_settled = true
      txn.cannot?(:finance_user, :chargeback).should be_falsey
      txn.can?(:finance_user, :chargeback).should be_truthy

      # reverse meaning of the above, should return the same
      Bali.clear_rules
      Bali.map_rules do
        rules_for My::Transaction do
          describe :finance_user do
            can :chargeback, if: proc { |record| record.is_settled? }
          end
        end
      end

      txn = My::Transaction.new
      txn.is_settled = false
      txn.cannot?(:finance_user, :chargeback).should be_truthy
      txn.can?(:finance_user, :chargeback).should be_falsey

      txn.is_settled = true
      txn.cannot?(:finance_user, :chargeback).should be_falsey
      txn.can?(:finance_user, :chargeback).should be_truthy
    end

    it "should allow rule group to be defined" do
      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: :show
        end
      end
      Bali::Integrators::Rule.rule_classes.size.should == 1
      rc = Bali::Integrators::Rule.rule_class_for(My::Transaction)
      rc.class.should == Bali::RuleClass
      rc.rules_for(:general_user).class.should == Bali::RuleGroup
      rc.rules_for(:general_user).get_rule(:can, :show).class.should == Bali::Rule
      expect(Bali::Integrators::Rule.rule_class_for(My::Transaction)).to_not be_nil

      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: :show
        end
      end
      Bali::Integrators::Rule.rule_classes.size.should == 1
      rc = Bali::Integrators::Rule.rule_class_for(My::Transaction)
      rc.class.should == Bali::RuleClass
      rc.rules_for(:general_user).class.should == Bali::RuleGroup
      rc.rules_for(:general_user).get_rule(:can, :show).class.should == Bali::Rule
      Bali::Integrators::Rule.rule_class_for(My::Transaction).should == rc
    end

    it "should redefine rule class if Bali.map_rules is called" do
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: [:update, :delete, :edit]
        end
      end
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(1)
      expect(Bali::Integrators::Rule.rule_class_for(My::Transaction)
        .rules_for(:general_user)
        .rules.size).to eq(3)

      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: :show
          describe :finance_user, can: [:update, :delete, :edit]
        end
      end
      expect(Bali::Integrators::Rule.rule_classes.size).to eq(1)
      rc = Bali::Integrators::Rule.rule_class_for(My::Transaction)
      expect(rc.rules_for(:general_user).rules.size).to eq(1)
      expect(rc.rules_for(:finance_user).rules.size).to eq(3)
    end


    context "when with others" do
      it "can define others block" do
        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :admin_user do
                can_all
              end
              others do
                cannot_all
                can :read
              end
            end
          end # map rules
        end.to_not raise_error

        rc = Bali::Integrators::Rule.rule_class_for(My::Transaction)
        expect(rc.rules_for("__*__").get_rule(:can, :read)).to_not be_nil
      end

      it "can define others by passing array to it" do
        expect do
          Bali.map_rules do
            rules_for My::Transaction do
              describe :admin_user do
                can_all
              end
              others can: [:view]
            end # rules for
          end # map rules
        end.to_not raise_error
      end
    end
  end # main module context DSL
end

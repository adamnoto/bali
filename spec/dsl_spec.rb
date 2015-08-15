describe Bali do
  it 'has a version number' do
    expect(Bali::VERSION).not_to be nil
  end

  context "DSL" do
    before(:each) do
      Bali.clear_rules
    end

    it "allows definition of rules" do
      expect(Bali.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do
          describe :general_user, can: :show
          describe :finance_user do |record|
            can :update, :delete, :edit
            can :delete, if: -> { record.is_settled? }
          end
        end
      end
      Bali.rule_classes.size.should == 1
      Bali.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    end

    it "can define nil rule group" do
      expect(Bali.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do
          describe nil do
            can :view
          end
        end
      end
      Bali.rule_classes.size.should == 1
      Bali.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    end

    it "should allow rule group to be defined with or without alias" do
      Bali.map_rules do
        rules_for My::Transaction do
          describe :general_user, can: :show
        end
      end
      Bali.rule_classes.size.should == 1
      rc = Bali.rule_class_for(My::Transaction)
      rc.class.should == Bali::RuleClass
      rc.rules_for(:general_user).class.should == Bali::RuleGroup
      rc.rules_for(:general_user).get_rule(:can, :show).class.should == Bali::Rule
      expect { Bali.rule_class_for(:transaction) }.to raise_error(Bali::DslError)

      Bali.map_rules do 
        rules_for My::Transaction, as: :transaction do
          describe :general_user, can: :show
        end
      end
      Bali.rule_classes.size.should == 1
      rc = Bali.rule_class_for(My::Transaction)
      rc.class.should == Bali::RuleClass
      rc.rules_for(:general_user).class.should == Bali::RuleGroup
      rc.rules_for(:general_user).get_rule(:can, :show).class.should == Bali::Rule
      Bali.rule_class_for(My::Transaction).should == rc
    end

    it "should redefine rule class if map_rules is called" do 
      expect(Bali.rule_classes.size).to eq(0)
      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do
          describe :general_user, can: [:update, :delete, :edit]
        end
      end
      expect(Bali.rule_classes.size).to eq(1)
      expect(Bali.rule_class_for(My::Transaction).rules_for(:general_user)
        .rules.size).to eq(3)

      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do 
          describe :general_user, can: :show
          describe :finance_user, can: [:update, :delete, :edit]
        end
      end
      expect(Bali.rule_classes.size).to eq(1)
      rc = Bali.rule_class_for(:transaction)
      expect(rc.rules_for(:general_user).rules.size).to eq(1)
      expect(rc.rules_for(:finance_user).rules.size).to eq(3)
    end

    it "should redefine rule if same operation is re-defined" do
      Bali.rule_classes.size.should == 0

      Bali.map_rules do
        rules_for My::Transaction, as: :transaction do
          describe :general_user do |record|
            can :update, :delete
            can :delete, if: -> { record.is_settled? }
          end
        end
      end

      rc = Bali.rule_class_for(:transaction)
      expect(rc.rules_for(:general_user).get_rule(:can, :delete).has_decider?)
        .to eq(true)
    end
  end # main module 
end

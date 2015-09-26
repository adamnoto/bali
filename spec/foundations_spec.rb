describe "Bali foundations" do
  before(:each) { Bali.clear_rules }

  describe "Bali::RuleClass" do
    it "is creatable" do
      rule_class = Bali::RuleClass.new(My::Transaction)
    end

    it "does not allow defining rule group for __*__" do
      expect do
        rule_group = Bali::RuleGroup.new(My::Transaction, "__*__")
        rule_class = Bali::RuleClass.new(My::Transaction)
        rule_class.add_rule_group(rule_group)
      end.to raise_error Bali::DslError
    end

    it "does not allow creation of instance for target other than class" do
      expect { Bali::RuleClass.new(Object.new) }.to raise_error(Bali::DslError)
    end

    # non-nil rule group is rule group that is defined with proper-named group
    # such as :user, :admin, :supreme, etc
    it "can add non-nil rule group" do
      rule_group = Bali::RuleGroup.new(My::Transaction, :user)
      rule_class = Bali::RuleClass.new(My::Transaction)
      expect { rule_class.add_rule_group(rule_group) }.to_not raise_error
      rule_class.rules_for(:user).class.should == Bali::RuleGroup
    end

    # nil rule group is for rule group that rules is targeting nil/un-authorized
    # un-authenticated or other un-available group for that matter: nil
    it "can add nil rule group" do
      rule_group = Bali::RuleGroup.new(My::Transaction, nil)
      rule_class = Bali::RuleClass.new(My::Transaction)
      expect { rule_class.add_rule_group(rule_group) }.to_not raise_error
      rule_class.rules_for(nil).class.should == Bali::RuleGroup
    end

    it "cannot add rule class other than of class Bali::RuleClass" do
      expect { Bali::Integrators::Rule.add_rule_class(nil) }.to raise_error(Bali::DslError)
      expect { Bali::Integrators::Rule.add_rule_class("adam") }.to raise_error(Bali::DslError)
      Bali::Integrators::Rule.add_rule_class(Bali::RuleClass.new(My::Transaction)).should_not be_nil
    end

    it "rule class for is only defined for a Class" do
      expect { Bali::Integrators::Rule.rule_class_for("adam") }.to raise_error(Bali::DslError)

      Bali::Integrators::Rule.add_rule_class(Bali::RuleClass.new(My::Transaction))
      Bali::Integrators::Rule.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    end

    it "should return nil whenever trying to search for inexistent rule class" do
      Bali::Integrators::Rule.rule_class_for(My::Transaction).should be_nil
    end

    it "should return Bali::RuleClass if rule class is defined" do
      Bali::Integrators::Rule.add_rule_class(Bali::RuleClass.new(My::Transaction))
      Bali::Integrators::Rule.rule_class_for(My::Transaction).class.should == Bali::RuleClass
    end

    context "cloning" do
      let(:rule) { Bali::Rule.new(:can, :delete) }
      let(:rule_group) { Bali::RuleGroup.new(My::Transaction, :finance) }
      let(:rule_class) { Bali::RuleClass.new(My::Transaction) }

      before do
        rule_group.add_rule(rule)
        rule_class.add_rule_group(rule_group)
      end

      it "can be cloned" do
        expect { cloned_rc = rule_class.clone(target_class: My::SecuredTransaction) }.to_not raise_error
      end

      it "all has unique object ID" do
        cloned_rc = rule_class.clone(target_class: My::SecuredTransaction)

        expect(cloned_rc.object_id).to_not eq(rule_class.object_id)
        expect(cloned_rc.rule_groups.object_id).to_not eq(rule_class.rule_groups.object_id)
        expect(cloned_rc.others_rule_group.object_id).to_not eq(rule_class.others_rule_group.object_id)

        rule_class.rule_groups.each do |subtarget, rule_group|
          cloned_rg = cloned_rc.rule_groups[subtarget] 
          expect(cloned_rg.object_id).to_not eq(rule_group.object_id)

          expect(cloned_rg.cants.object_id).to_not eq(rule_group.cants.object_id)
          expect(cloned_rg.cans.object_id).to_not eq(rule_group.cans.object_id)

          expect(cloned_rg.cans[:delete].object_id).to_not eq(rule_group.cans[:delete].object_id)
        end
      end
    end
  end

  describe "Bali::RuleGroup" do
    let(:rule_can_delete) { Bali::Rule.new(:can, :delete) }
    let(:rule_can_new)    { Bali::Rule.new(:can, :new)    }
    let(:rule_cant_edit)  { Bali::Rule.new(:cant, :edit)  }

    it "should return nil whenever trying to search for inexistent rule group" do
      Bali::Integrators::Rule.rule_group_for(My::Transaction, :basic_user).should be_nil
    end

    it "should return Bali::RuleGroup if rule group is defined" do
      Bali::Integrators::Rule.add_rule_class(Bali::RuleClass.new(My::Transaction))
      rule_class = Bali::Integrators::Rule.rule_class_for(My::Transaction)
      rule_class.add_rule_group(Bali::RuleGroup.new(My::Transaction, :basic))
      Bali::Integrators::Rule.rule_group_for(My::Transaction, :basic).class.should == Bali::RuleGroup
    end

    RSpec.shared_examples "rule" do
      context "rule objection" do
        it "can responds to can?" do
          transaction = My::Transaction.new
          expect(transaction.respond_to?(:can?)).to eq true
          transaction.class.ancestors.include?(Bali::Objector).should be_truthy

          # class-level question too
          My::Transaction.respond_to?(:can?).should == true
        end

        it "can responds to cannot?" do
          transaction = My::Transaction.new
          expect(transaction.respond_to?(:cannot?)).to eq true
          transaction.class.ancestors.include?(Bali::Objector).should be_truthy

          # class-level question too
          My::Transaction.respond_to?(:can?).should == true
        end
      end

      context "rule manipulation" do
        it "allows adding new rule" do
          rule_group.rules.size.should == 0
          rule_group.add_rule(rule_can_delete)
          rule_group.rules.size.should == 1

          rule_group.add_rule(rule_can_new)
          rule_group.rules.size.should == 2

          rule_group.add_rule(rule_cant_edit)
          rule_group.rules.size.should == 3
        end

        it "allows retrieval of defined rule" do
          rule_group.add_rule rule_can_delete
          rule_group.add_rule rule_can_new

          rule_group.get_rule(:can, :delete).should == rule_can_delete
          rule_group.get_rule(:can, :new).should == rule_can_new
        end
      end
    end # shared examples

    context "for :user" do
      let(:rule_group) { Bali::RuleGroup.new(My::Transaction, :user) }

      it "is creatable" do
        rule_group.target.should == My::Transaction
        rule_group.subtarget.should == :user
      end

      it_behaves_like "rule"
    end # context for :user

    context "for nil" do
      let(:rule_group) { Bali::RuleGroup.new(My::Transaction, nil) }

      it "is creatable" do
        rule_group.target.should == My::Transaction
        rule_group.subtarget.should == nil
      end

      it_behaves_like "rule"
    end
  end

  describe "Bali::Rule" do
    it "is creatable" do
      rule = Bali::Rule.new(:can, :delete)
      rule.auth_val.should == :can
      rule.operation.should == :delete
      rule.decider.should be_nil

      rule = Bali::Rule.new(:cannot, :delete)
      rule.auth_val.should == :cannot
      rule.operation.should == :delete
      rule.decider.should be_nil
    end

    it "can have decider" do
      rule = Bali::Rule.new(:can, :delete)
      expect(rule.has_decider?).to be_falsey

      rule.decider = -> { true }
      expect { rule.has_decider? }.to raise_error(Bali::DslError)
      expect { rule.decider_type = :whatever }.to raise_error(Bali::DslError)

      expect { rule.decider_type = :if }.to_not raise_error
      expect(rule.has_decider?).to be_truthy
      rule.decider_type.should == :if

      expect { rule.decider_type = :unless }.to_not raise_error
      expect(rule.has_decider?).to be_truthy
      rule.decider_type.should == :unless
    end

    context "based on auth_val" do
      it "can only be either can or cant type" do
        expect {Bali::Rule.new(:xyz, :delete) }.to raise_error(Bali::DslError)
        expect {Bali::Rule.new(:can, :delete) }.to_not raise_error
        expect {Bali::Rule.new(:cannot, :delete)}.to_not raise_error
      end
      context "cant-type rule" do
        let(:rule) { Bali::Rule.new(:cant, :delete) }

        it "is a discouragement" do
          expect(rule.is_discouragement?).to be_truthy
        end
      end

      context "can-type rule" do
        let(:rule) { Bali::Rule.new(:can, :delete ) }

        it "is not a discouragement" do
          expect(rule.is_discouragement?).to be_falsey
        end
      end
    end # context
  end # describing Bali::Rule
end

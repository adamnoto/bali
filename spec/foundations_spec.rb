describe Bali::RuleClass do
  it "is creatable" do
    rule_class = Bali::RuleClass.new(My::Transaction)
  end

  it "does not allow creation of instance for target other than class" do
    expect { Bali::RuleClass.new(Object.new) }.to raise_error(Bali::DslError)
  end
end

describe Bali::RuleGroup do
  let(:rule_can_delete) { Bali::Rule.new(:can, :delete) }
  let(:rule_can_new)    { Bali::Rule.new(:can, :new)    }
  let(:rule_cant_edit)  { Bali::Rule.new(:cant, :edit)  }

  before(:each) do
    @rule_group = Bali::RuleGroup.new(My::Transaction, :transaction, :user)
  end

  it "is creatable" do
    @rule_group.target.should == My::Transaction
    @rule_group.alias_tgt.should == :transaction
    @rule_group.subtarget.should == :user
  end

  context "rule manipulation" do
    it "allows adding new rule" do
      @rule_group.rules.size.should == 0
      @rule_group.add_rule(rule_can_delete)
      @rule_group.rules.size.should == 1

      @rule_group.add_rule(rule_can_new)
      @rule_group.rules.size.should == 2

      @rule_group.add_rule(rule_cant_edit)
      @rule_group.rules.size.should == 3
    end

    it "allows retrieval of defined rule" do
      @rule_group.add_rule rule_can_delete
      @rule_group.add_rule rule_can_new

      @rule_group.get_rule(:can, :delete).should == rule_can_delete
      @rule_group.get_rule(:can, :new).should == rule_can_new
    end

  end

  context "rule objection" do
    it "can responds to can?" do
      transaction = My::Transaction.new
      expect(transaction.respond_to?(:can?)).to eq true
      transaction.class.ancestors.include?(Bali::Objector).should be_truthy 

      # class-level question too
      My::Transaction.respond_to?(:can?).should == true
    end

    it "can responds to cant?" do
      transaction = My::Transaction.new
      expect(transaction.respond_to?(:cant?)).to eq true
      transaction.class.ancestors.include?(Bali::Objector).should be_truthy

      # class-level question too
      My::Transaction.respond_to?(:can?).should == true
    end
  end
end # RuleObject

describe Bali::Rule do
  it "is creatable" do 
    rule = Bali::Rule.new(:can, :delete)
    rule.auth_val.should == :can
    rule.operation.should == :delete
    rule.decider.should be_nil

    rule = Bali::Rule.new(:cant, :delete)
    rule.auth_val.should == :cant
    rule.operation.should == :delete
    rule.decider.should be_nil
  end

  it "can have decider" do
    rule = Bali::Rule.new(:can, :delete)
    expect(rule.has_decider?).to be_falsey

    rule.decider = -> { true }
    expect(rule.has_decider?).to be_truthy
  end

  context "based on auth_val" do
    it "can only be either can or cant type" do
      expect {Bali::Rule.new(:xyz, :delete) }.to raise_error(Bali::DslError)
      expect {Bali::Rule.new(:can, :delete) }.to_not raise_error
      expect {Bali::Rule.new(:cant, :delete)}.to_not raise_error
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
  end

end

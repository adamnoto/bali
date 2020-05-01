describe Bali::Rules do
  describe ".ruler" do
    it "always have inherited rule block even when not explicitly defined" do
      expect { Module.const_get(:TestClassA) }.to raise_error NameError
      expect { Module.const_get(:TestClassARules) }.to raise_error NameError

      class TestClassA
      end

      class TestClassARules < Bali::Rules
        role :admin do
          can :save
        end
      end

      expect(TestClassARules.ruler[nil]).to be_a Bali::Role
    end
  end

  describe "DSL" do
    describe "scope block" do
      it "raises a DSL error if defined inside a role" do
        expect do
          class Bali::Rules::TestScopeDSLError; end
          class Bali::Rules::TestScopeDSLErrorRules < Bali::Rules
            role :admin do
              scope do |data, current_user|
                data.order("created_at DESC")
              end
            end
          end
        end.to raise_error(Bali::DslError, "Block can't be scoped inside a role")
      end

      it "does not raise a DSL error if defined in inheritable space" do
        expect do
          class Bali::Rules::TestScopeDSLFine; end
          class Bali::Rules::TestScopeDSLFineRules < Bali::Rules
            scope do |data, current_user|
              data.order("created_at DESC")
            end
          end
        end.not_to raise_error
      end
    end
  end
end

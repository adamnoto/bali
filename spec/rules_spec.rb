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
end

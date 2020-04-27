describe Bali::Statics::ActiveRecord do
  describe ".role_field_for_authorization" do
    describe "each models" do
      it "has their own role field" do
        class MockRecordBase
          extend Bali::Statics::ActiveRecord
        end

        record_class_1 = Class.new(MockRecordBase) do
          extract_roles_from :field1
        end

        record_class_2 = Class.new(MockRecordBase) do
          extract_roles_from :field2
        end

        expect(record_class_1.role_field_for_authorization).to eq :field1
        expect(record_class_2.role_field_for_authorization).to eq :field2
        expect(MockRecordBase.role_field_for_authorization).to be_blank
      end
    end
  end
end

describe Api::TransactionsController do
  let(:user) { User.create }
  let(:admin) { User.create(role: "admin") }

  let!(:user_data) { 5.times.map { Transaction.create(user_id: user.id) } }
  let!(:admin_data) { 5.times.map { Transaction.create(user_id: admin.id) } }

  describe "GET /" do
    context "when accessing as non-admin" do
      it "retrieves data belonging to the user only" do
        get :index, params: { user_id: user.id }

        expect(response.body).to include("1, 2, 3, 4, 5")
      end
    end

    context "when accessing as an admin" do
      it "retrieves all the data" do
        get :index, params: { user_id: admin.id }

        expect(response.body).to include("1, 2, 3, 4, 5, 6, 7, 8, 9, 10")
      end
    end
  end
end

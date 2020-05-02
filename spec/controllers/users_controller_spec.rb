describe UsersController do
  let(:user) { User.create }
  include Rails.application.routes.url_helpers

  describe "GET /" do
    it "can use can? in the view" do
      get :index
      expect(response.body).to include("Can send message? true")
      expect(response.body).to include("Can sign in? false")
      expect(response.body).to include("Can send message from helper? true")
      expect(response.body).to include("Cant see banner? true")
      expect(response.body).to include("Cant see banner from helper? true")
      expect(response.body).to include("Can update transaction? true")
    end

    context "as an accountant" do
      let(:user) { User.create(role: :accountant) }
      it "cannot update transaction" do
        get :index, params: { id: user.id }
        expect(response.body).to include("Can update transaction? false")
      end
    end
  end

  describe "GET /index_no_current_user" do
    it "raises an error when rendering the page" do
      expect {
        get :index_no_current_user
      }.to raise_error("Cannot perform checking when the actor is not known")
    end
  end

  describe "GET /:id" do
    context "when visiting a friend" do
      let(:friend) { User.create friends: [user] }

      it "is allowed to render" do
        get :show, params: { id: user.id, friend_id: friend.id }
        expect(response).to have_http_status :ok
      end
    end

    context "when visiting a stranger" do
      let(:stranger) { User.create }

      it "is not allowed to render" do
        get :show, params: { id: user.id, friend_id: stranger.id }
        expect(response).to have_http_status :unauthorized
      end
    end
  end
end

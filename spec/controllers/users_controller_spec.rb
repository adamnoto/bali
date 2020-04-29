describe UsersController do
  let(:user) { User.create }
  include Rails.application.routes.url_helpers

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

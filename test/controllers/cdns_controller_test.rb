require "test_helper"

describe CdnsController do
  let(:cdn) { cdns :one }

  it "gets index" do
    get :index
    value(response).must_be :success?
    value(assigns(:cdns)).wont_be :nil?
  end

  it "gets new" do
    get :new
    value(response).must_be :success?
  end

  it "creates cdn" do
    expect {
      post :create, cdn: {  }
    }.must_change "Cdn.count"

    must_redirect_to cdn_path(assigns(:cdn))
  end

  it "shows cdn" do
    get :show, id: cdn
    value(response).must_be :success?
  end

  it "gets edit" do
    get :edit, id: cdn
    value(response).must_be :success?
  end

  it "updates cdn" do
    put :update, id: cdn, cdn: {  }
    must_redirect_to cdn_path(assigns(:cdn))
  end

  it "destroys cdn" do
    expect {
      delete :destroy, id: cdn
    }.must_change "Cdn.count", -1

    must_redirect_to cdns_path
  end
end

require 'test_helper'

class SiteSealsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:site_seals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create site_seal" do
    assert_difference('SiteSeal.count') do
      post :create, :site_seal => { }
    end

    assert_redirected_to site_seal_path(assigns(:site_seal))
  end

  test "should show site_seal" do
    get :show, :id => site_seals(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => site_seals(:one).to_param
    assert_response :success
  end

  test "should update site_seal" do
    put :update, :id => site_seals(:one).to_param, :site_seal => { }
    assert_redirected_to site_seal_path(assigns(:site_seal))
  end

  test "should destroy site_seal" do
    assert_difference('SiteSeal.count', -1) do
      delete :destroy, :id => site_seals(:one).to_param
    end

    assert_redirected_to site_seals_path
  end
end

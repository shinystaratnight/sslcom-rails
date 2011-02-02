require 'test_helper'

class SslAccountsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:ssl_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ssl_account" do
    assert_difference('SslAccount.count') do
      post :create, :ssl_account => { }
    end

    assert_redirected_to ssl_account_path(assigns(:ssl_account))
  end

  test "should show ssl_account" do
    get :show, :id => ssl_accounts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => ssl_accounts(:one).to_param
    assert_response :success
  end

  test "should update ssl_account" do
    put :update, :id => ssl_accounts(:one).to_param, :ssl_account => { }
    assert_redirected_to ssl_account_path(assigns(:ssl_account))
  end

  test "should destroy ssl_account" do
    assert_difference('SslAccount.count', -1) do
      delete :destroy, :id => ssl_accounts(:one).to_param
    end

    assert_redirected_to ssl_accounts_path
  end
end

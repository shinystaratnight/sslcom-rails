require 'test_helper'

class CertificateOrdersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:certificate_orders)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create certificate_order" do
    assert_difference('CertificateOrder.count') do
      post :create, :certificate_order => { }
    end

    assert_redirected_to certificate_order_path(assigns(:certificate_order))
  end

  test "should show certificate_order" do
    get :show, :id => certificate_orders(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => certificate_orders(:one).to_param
    assert_response :success
  end

  test "should update certificate_order" do
    put :update, :id => certificate_orders(:one).to_param, :certificate_order => { }
    assert_redirected_to certificate_order_path(assigns(:certificate_order))
  end

  test "should destroy certificate_order" do
    assert_difference('CertificateOrder.count', -1) do
      delete :destroy, :id => certificate_orders(:one).to_param
    end

    assert_redirected_to certificate_orders_path
  end
end

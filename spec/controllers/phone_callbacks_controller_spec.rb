require 'rails_helper'

describe PhoneCallbacksController do

  before do
    @user = FactoryBot.create(:user, Role::SYS_ADMIN)
    activate_authlogic
    login_as(@user)
  end

  describe 'approvals' do
    before do
      PhoneCallBackLog.destroy_all
      CertificateOrder.destroy_all
    end

    it 'does not allow non super users to view' do
      get :approvals
      expect(response).to redirect_to(certificate_orders_path)
    end
  end

  describe 'verifications' do
    before do
      PhoneCallBackLog.destroy_all
      CertificateOrder.destroy_all
    end

    it 'displays pending certificate orders' do
      @user.elevate_role(Role::SYS_ADMIN)
      cert = create(:certificate, :codesigningssl)

      cert.product_variant_groups.first.product_variant_items.first.sub_order_item = create(:sub_order_item, product_variant_item_id: cert.product_variant_groups.first.product_variant_items.first.id)
      cert.product_variant_groups.first.product_variant_items.first.sub_order_item.update(sub_itemable_type: 'CertificateOrder', sub_itemable_id: create(:certificate_order).id)
      cert_order = CertificateOrder.joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }.first
      cert_order.certificate_order_tokens << create(:certificate_order_token, :manual)
      certificate_content = create(:certificate_content)
      certificate_content.update(certificate_order_id: cert_order.id, workflow_state: 'contacts_provided')
      registrant = build(:locked_registrant)
      registrant.update(contactable_id: cert_order.certificate_content.id, contactable_type: 'CertificateContent')

      get :verifications
      expect(response).to have_http_status(200)
      expect(response).to render_template('verifications')
      expect(assigns(:certificate_orders)).to eq [cert_order]
    end

    it 'allows for searching for particular orders' do
      @user.elevate_role(Role::SYS_ADMIN)
      cert = create(:certificate, :codesigningssl)

      cert.product_variant_groups.first.product_variant_items.first.sub_order_item = create(:sub_order_item, product_variant_item_id: cert.product_variant_groups.first.product_variant_items.first.id)
      cert.product_variant_groups.first.product_variant_items.first.sub_order_item.update(sub_itemable_type: 'CertificateOrder', sub_itemable_id: create(:certificate_order).id)
      cert_order = CertificateOrder.joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }.first
      cert_order.certificate_order_tokens << create(:certificate_order_token, :manual)
      certificate_content = create(:certificate_content)
      certificate_content.update(certificate_order_id: cert_order.id, workflow_state: 'contacts_provided')
      registrant = build(:locked_registrant)
      registrant.update(contactable_id: cert_order.certificate_content.id, contactable_type: 'CertificateContent')

      cert_two = create(:certificate, :codesigningssl)

      cert_two.product_variant_groups.first.product_variant_items.first.sub_order_item = create(:sub_order_item, product_variant_item_id: cert_two.product_variant_groups.first.product_variant_items.first.id)
      cert_two.product_variant_groups.first.product_variant_items.first.sub_order_item.update(sub_itemable_type: 'CertificateOrder', sub_itemable_id: create(:certificate_order).id)
      cert_order_two = CertificateOrder.joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }.first
      cert_order_two.certificate_order_tokens << create(:certificate_order_token, :manual)
      certificate_content_two = create(:certificate_content)
      certificate_content_two.update(certificate_order_id: cert_order_two.id)
      registrant_two = build(:locked_registrant)
      registrant_two.update(contactable_id: cert_order_two.certificate_content.id, contactable_type: 'CertificateContent')

      get :verifications, search: cert_order.ref
      expect(assigns(:certificate_orders)).to eq [cert_order]
      expect(assigns(:certificate_orders)).to_not include [cert_order_two]
    end

    it 'renders verifications if no match is found' do
      @user.elevate_role(Role::SYS_ADMIN)
      get :verifications, search: 'co-frghcd2e'
      expect(response).to render_template('verifications')
      expect(assigns(:certificate_orders)).to eq []
    end

    it 'does not allow regular users to view the page' do
      user = FactoryBot.create(:user)
      activate_authlogic
      login_as(user)

      get :verifications
      expect(response).to redirect_to(certificate_orders_path)
    end
  end

  describe 'create' do
    before do
      PhoneCallBackLog.destroy_all
    end

    it 'creates a new phone callback log' do
      cert_order = create(:certificate_order_token).certificate_order

      post :create, { phone_callback_log: { validated_by: @user.login, cert_order_ref: cert_order.ref, phone_number: '1 9568764324' } }
      expect(PhoneCallBackLog.count).to eq 1
      expect(PhoneCallBackLog.first).to be_valid
    end

    it 'updates a certifcate orders token when callback is complete' do
      cert_order = create(:certificate_order_token).certificate_order

      post :create, { phone_callback_log: { validated_by: @user.login, cert_order_ref: cert_order.ref, phone_number: '1 9568764324' } }
      token = cert_order.certificate_order_tokens.first
      expect(token.status).to eq 'done'
    end

    it 'renders the verifications if save fails' do
      cert = create(:certificate, :codesigningssl)

      cert.product_variant_groups.first.product_variant_items.first.sub_order_item = create(:sub_order_item, product_variant_item_id: cert.product_variant_groups.first.product_variant_items.first.id)
      cert.product_variant_groups.first.product_variant_items.first.sub_order_item.update(sub_itemable_type: 'CertificateOrder', sub_itemable_id: create(:certificate_order).id)
      cert_order = CertificateOrder.joins{ sub_order_items.product_variant_item.product_variant_group.variantable(Certificate) }.first

      post :create, { phone_callback_log: { validated_by: '', cert_order_ref: cert_order.ref, phone_number: '1 9568764324' } }
      expect(PhoneCallBackLog.count).to eq 0
      expect(response).to render_template('verifications')
    end
  end
end

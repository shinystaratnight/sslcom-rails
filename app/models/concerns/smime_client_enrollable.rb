module SmimeClientEnrollable
  extend ActiveSupport::Concern

  def smime_client_enroll_recipients(current_user_id)
    @sce_ssl = billable
    @sce_current_user = User.find current_user_id
    @sce_epki_registrant = @sce_ssl.epki_registrant

    certificate_orders.includes(:certificate_contents).uniq.each do |co|
      @sce_co = co
      @sce_email = @sce_co.certificate_content.domains.first
      @sce_iv_exists = @sce_ssl.individual_validations.find_by(email: @sce_email)

      if @sce_iv_exists && User.find_by(id: @sce_iv_exists.user_id)
        @sce_co.update_column(:assignee_id, @sce_iv_exists.user_id)
      else
        smime_client_enroll_invite_recipient
      end

      if @sce_iv_exists && @sce_iv_exists.persisted?
        LockedRecipient.create_for_co(@sce_co, @sce_iv_exists.user_id)
        smime_client_enroll_validate
      end
    end
  end

  def smime_client_enroll_invite_recipient
    user_exists = User.find_by(email: @sce_email)
    if user_exists
      user_exists_for_team = @sce_ssl.users.find_by(id: user_exists.id)

      if user_exists_for_team
        @sce_iv_exists = @sce_ssl.individual_validations.find_by(email: user_exists_for_team.email)
        smime_client_enroll_sync_user_iv(user_exists_for_team.id)
      end

      unless @sce_iv_exists
        # Add IV for user to team.
        @sce_iv_exists = @sce_ssl.individual_validations.create(
          first_name: (user_exists.first_name || ''),
          last_name: (user_exists.last_name || ''),
          email: user_exists.email,
          status: user_exists_for_team ? Contact::statuses[:validated] : Contact::statuses[:in_progress],
          user_id: user_exists.id
        )
      end

      # Add user to team w/role individual_certificate
      unless user_exists_for_team
        user_exists.ssl_accounts << @sce_ssl
        user_exists.set_roles_for_account(
          @sce_ssl, [Role::get_individual_certificate_id]
        )
      end

      @sce_co.update_column(:assignee_id, user_exists.id)
    else
      smime_client_enroll_invite_new_recipient
    end
  end

  def smime_client_enroll_invite_new_recipient
    new_user = @sce_current_user.invite_new_user(
      { user: {email: @sce_email, first_name: '', last_name: ''} }
    )
    if new_user.persisted?
      smime_client_enroll_invite_recipient
    end
  end

  def smime_client_enroll_sync_user_iv(user_id)
    unless user_id == @sce_iv_exists.user_id
      @sce_iv_exists.update_column(:user_id, user_id)
    end
  end

  def smime_client_enroll_validate
    require_ov_iv = @sce_co.certificate.requires_locked_registrant?
    ov = @sce_co.locked_registrant
    lr = @sce_co.locked_recipient
    cc = @sce_co.certificate_content

    if @sce_epki_registrant.applies_to_certificate_order?(@sce_co)
      ov.validated! if require_ov_iv && !ov.validated?
      lr.validated! unless lr.validated?
      @sce_iv_exists.validated! unless @sce_iv_exists.validated?
      cc.validate! unless cc.validated?
    else
      ov.pending_validation! if require_ov_iv && !ov.pending_validation?
      lr.pending_validation! unless lr.pending_validation?
      @sce_iv_exists.pending_validation! unless @sce_iv_exists.pending_validation?
      cc.pend_validation! unless cc.pending_validation?
    end
  end
end

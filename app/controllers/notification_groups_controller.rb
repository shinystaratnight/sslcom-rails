class NotificationGroupsController < ApplicationController
  before_action :require_user, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :find_ssl_account
  before_action :set_row_page, only: [:index]

  def index
    @notification_groups = @ssl_account.notification_groups.paginate(@p)
  end

  def remove_groups
    group_ids = params[:remove_groups]

    unless group_ids.blank?
      @ssl_account.notification_groups.where(id: group_ids).destroy_all
      Preference.where(owner_type: 'NotificationGroup', owner_id: group_ids).destroy_all
    end

    flash[:notice] = "Selected notification groups has been removed successfully."
    redirect_to notification_groups_path(ssl_slug: @ssl_slug)
  end

  def new
    @cos_list = @ssl_account.certificate_orders.pluck(:ref, :id).uniq!
    @title = 'New SSL Expiration Notification Group'

    render 'group'
  end

  def edit
    @notification_group = @ssl_account.notification_groups.where(id: params[:id]).first
    slt_cert_orders = @notification_group.certificate_orders.flatten.compact
    @cos_list = @ssl_account.certificate_orders.pluck(:ref, :id).uniq!
    @slt_cos_list = slt_cert_orders.map(&:id)

    domain_names = @notification_group.notification_groups_subjects.where.not(domain_name: [nil, ''])
    @subjects_list = slt_cert_orders.map(&:certificate_contents).flatten.compact.map(&:certificate_names)
                        .flatten.compact.map{ |cn| [cn.name, cn.id] }.uniq
                         .concat(domain_names.pluck(:domain_name, :domain_name))
    @slt_subjects_list = @notification_group.certificate_names.pluck(:id).concat(domain_names.pluck(:domain_name))

    email_addresses = @notification_group.notification_groups_contacts.where.not(email_address: [nil, ''])
    @contacts_list = slt_cert_orders.map(&:certificate_contents).flatten.compact.map(&:certificate_contacts)
                         .flatten.compact.map{ |cc| [cc.email, cc.id] }.uniq
                         .concat(email_addresses.pluck(:email_address, :email_address))
    @slt_contacts_list = @notification_group.contacts.pluck(:id).concat(email_addresses.pluck(:email_address))
    @title = 'Edit SSL Expiration Notification Group'

    render 'group'
  end

  def register_notification_group
    if params[:format]
      # Saving notification group info
      notification_group = @ssl_account.notification_groups.where(ref: params[:format]).first
      notification_group.friendly_name = params[:friendly_name]
    else
      # Saving notification group info
      notification_group = NotificationGroup.new(
          friendly_name: params[:friendly_name],
          ssl_account: @ssl_account
      )
    end

    # Saving notification group triggers
    if params[:notification_group_triggers]
      params[:notification_group_triggers].uniq.sort{|a,b|a.to_i <=> b.to_i}.reverse.each_with_index do |rt, i|
        notification_group.preferred_notification_group_triggers = rt.or_else(nil), ReminderTrigger.find(i+1)
      end
    end

    unless notification_group.save
      flash[:error] = "Some error occurs while saving notification group data. Please try again."
      redirect_to new_notification_group_path(ssl_slug: @ssl_slug) and return unless params[:format]
      redirect_to edit_notification_group_path(@ssl_slug, notification_group.id) and return
    end

    # Saving certificate order tags
    if params[:cos_list]
      current_tags = notification_group.certificate_orders.pluck(:id)
      remove_tags = current_tags - params[:cos_list]
      add_tags = params[:cos_list] - current_tags

      # Remove old tags
      notification_group.notification_groups_subjects.
          where(subjectable_type: 'CertificateOrder', subjectable_id: remove_tags).destroy_all

      # Add new tags
      add_tags.each do |id|
        notification_group.notification_groups_subjects.build(
            subjectable_type: 'CertificateOrder', subjectable_id: id
        ).save
      end
    else
      notification_group.notification_groups_subjects
          .where(subjectable_type: 'CertificateOrder').destroy_all
    end

    # Saving subject tags
    if params[:subjects_list]
      current_tags = notification_group.certificate_names.pluck(:id)
      domain_tags = notification_group.notification_groups_subjects.where.not(domain_name: [nil, '']).pluck(:domain_name)
      current_tags += domain_tags

      remove_tags = current_tags - params[:subjects_list]
      add_tags = params[:subjects_list] - current_tags

      # Remove old tags
      remove_tags.each do |id|
        if id !~ /\D/
          notification_group.notification_groups_subjects.
              where(subjectable_type: 'CertificateName', subjectable_id: id).destroy_all
        else
          notification_group.notification_groups_subjects.where(domain_name: id).destroy_all
        end
      end

      # Add new tags
      add_tags.each do |id|
        if id !~ /\D/
          notification_group.notification_groups_subjects.build(
              subjectable_type: 'CertificateName', subjectable_id: id
          ).save
        else
          notification_group.notification_groups_subjects.build(
              domain_name: id
          ).save
        end
      end
    else
      domain_tags = notification_group.notification_groups_subjects.where.not(domain_name: [nil, '']).pluck(:domain_name)
      domain_tags.each do |name|
        notification_group.notification_groups_subjects.where(domain_name: name).destroy_all
      end
      notification_group.notification_groups_subjects
          .where(subjectable_type: 'CertificateName').destroy_all
    end

    # Saving contact tags
    if params[:contacts_list]
      current_tags = notification_group.contacts.pluck(:id)
      email_tags = notification_group.notification_groups_contacts.where.not(email_address: [nil, '']).pluck(:email_address)
      current_tags += email_tags

      remove_tags = current_tags - params[:contacts_list]
      add_tags = params[:contacts_list] - current_tags

      # Remove old tags
      remove_tags.each do |id|
        if id !~ /\D/
          notification_group.notification_groups_contacts.
              where(contactable_type: 'Contact', contactable_id: id).destroy_all
        else
          notification_group.notification_groups_contacts.where(email_address: id).destroy_all
        end
      end

      # Add new tags
      add_tags.each do |id|
        if id !~ /\D/
          notification_group.notification_groups_contacts.build(
              contactable_type: 'Contact', contactable_id: id
          ).save
        else
          notification_group.notification_groups_contacts.build(
              email_address: id
          ).save
        end
      end
    else
      email_tags = notification_group.notification_groups_contacts.where.not(email_address: [nil, '']).pluck(:email_address)
      email_tags.each do |addr|
        notification_group.notification_groups_contacts.where(email_address: addr).destroy_all
      end
      notification_group.notification_groups_contacts
          .where(contactable_type: 'Contact').destroy_all
    end

    flash[:notice] = "Notification group has been updated successfully."
    flash[:notice] = "New notification group has been created successfully." unless params[:format]

    redirect_to notification_groups_path(ssl_slug: @ssl_slug) and return
  end

  def certificate_orders_domains_contacts
    domains = []
    contacts = []

    if params['cos'] && params['cos'].size > 0
      certificate_orders = @ssl_account.certificate_orders

      params['cos'].each do |id|
        co = certificate_orders.where(id: id).first

        unless co.blank?
          domains.concat co.certificate_content.certificate_names.pluck(:name, :id)
          contacts.concat co.certificate_content.certificate_contacts.pluck(:email, :id)
        end
      end
    end

    results = {}
    results['domains'] = domains
    results['contacts'] = contacts

    render :json => results
  end

  private
    def set_row_page
      preferred_row_count = current_user.preferred_note_group_row_count
      @per_page = params[:per_page] || preferred_row_count.or_else("10")
      NotificationGroup.per_page = @per_page if NotificationGroup.per_page != @per_page

      if @per_page != preferred_row_count
        current_user.preferred_note_group_row_count = @per_page
        current_user.save(validate: false)
      end

      @p = {page: (params[:page] || 1), per_page: @per_page}
    end
end
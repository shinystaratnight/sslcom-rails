class NotificationGroup < ActiveRecord::Base
  belongs_to :ssl_account

  has_many  :notification_groups_contacts, dependent: :destroy
  has_many  :contacts, through: :notification_groups_contacts,
            source: :contactable, source_type: 'Contact'

  has_many  :notification_groups_subjects, dependent: :destroy
  has_many  :certificate_orders, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateOrder'
  has_many  :certificate_contents, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateContent'
  has_many  :certificate_names, through: :notification_groups_subjects,
            source: :subjectable, source_type: 'CertificateName'

  preference  :notification_group_triggers, :string

  validates :friendly_name, allow_nil: false, allow_blank: false,
            length: { minimum: 1, maximum: 255 },
            uniqueness: {
                case_sensitive: true,
                scope: :ssl_account_id,
                message: 'Friendly name already exists for this user or team.'
            }

  before_create do |ng|
    ng.ref = 'ng-' + SecureRandom.hex(1) + Time.now.to_i.to_s(32)
  end

  # will_paginate
  cattr_accessor :per_page
  @@per_page = 10

  def to_param
    ref
  end
end
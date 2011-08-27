class ValidationHistory < ActiveRecord::Base
  has_many  :validation_ruling_validation_histories
  has_many  :validation_rulings, :through=>:validation_ruling_validation_histories, :as=>:validation_rulable
  has_many  :validation_rules, :through => :validation_rulings
  has_many  :validation_history_validations
  has_many  :validations, :through=>:validation_history_validations
  attr_protected :publish_to_site_seal_approval
  attr_protected :validation_rules
  serialize :satisfies_validation_methods
  has_attached_file :document, :url => "/:class/:id/:attachment/:style.:extension",
    # => Use this if we want to store to the file system instead of s3.
    # Comment out the remainder parameters
#    :path => ":Rails.root/attachments/:class/:id/:attachment/:style.:extension",
#    :styles=>{:thumb=>['100x100#', :png], :preview=>['400x400#', :png]}
    :styles=>{:thumb=>['100x100#', :png], :preview=>['400x400#', :png]},
    :storage => :s3,
    :s3_credentials => "#{Rails.root}/config/s3.yml",
    :s3_permissions => :private,
    :s3_protocol => 'http',
    :bucket => 'ssl-validation-docs',
    :path => lambda { |attachment| ":id_partition/#{attachment.instance.random_secret}/:style.:extension" }

  CONTENT_TYPES =   [['image/jpeg', 'jpg, jpeg, jpe'], ['image/png','png'],
    ['application/pdf', 'pdf'], ['image/tiff', 'tif, tiff'],
    ['image/gif', 'gif'], ['image/bmp', 'bmp'],
    ['application/zip', 'zip'], ['text/plain', 'txt'],
    ['application/msword', 'doc']]

#  validates_attachment_presence :document
#  validates_attachment_size :document, :less_than => 5.megabytes
#  validates_attachment_content_type :document, :content_type =>
#    ValidationHistory::CONTENT_TYPES.transpose[0]

  preference  :viewing_method, :string, :default=>"download" #or thumbnail

  def document_url(style=nil)
    if style.blank?
      %{/#{self.class.name.tableize}/#{id}/documents/#{document_file_name}}
    else
      %{/#{self.class.name.tableize}/#{id}/documents/#{document.styles[style].name}.#{document.styles[style].format}}
    end
  end

  def authenticated_s3_get_url(options={})
    options.reverse_merge! :expires_in => 10.minutes, :use_ssl => false
    AWS::S3::S3Object.url_for document.path(options[:style]), document.options[:bucket], options
  end

  def self.multi_upload_types
    ValidationHistory::CONTENT_TYPES.transpose[1].map{|ct|ct.split(',')}.
      flatten.join('|').gsub(' ', '')
  end

  def self.acceptable_file_types
    ValidationHistory::CONTENT_TYPES.transpose[1].map{|ct|ct.split(',')}.
      flatten.join(', ').gsub('  ', ' ')
  end

  def random_secret
    if @new_record
      set_random_secret
    end
    read_attribute(:random_secret)
  end

  def can_publish_to_site_seal?
    (publish_to_site_seal && publish_to_site_seal_approval)
  end

  def authenticated_s3_get_url(options={})
    options.reverse_merge! :expires_in => 10.minutes, :use_ssl => true
    AWS::S3::S3Object.url_for document.path(options[:style]),
      document.options[:bucket], options
  end

  private

  def set_random_secret
    self.random_secret = ActiveSupport::SecureRandom.hex(8)
  end
end
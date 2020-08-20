class ValidationHistory < ApplicationRecord
  has_many  :validation_ruling_validation_histories
  has_many  :validation_rulings, :through=>:validation_ruling_validation_histories, :as=>:validation_rulable
  has_many  :validation_rules, :through => :validation_rulings
  has_many  :validation_history_validations
  has_many  :validations, :through=>:validation_history_validations
  has_many  :certificate_orders, through: :validations
  attr_protected :publish_to_site_seal_approval
  attr_protected :validation_rules
  serialize :satisfies_validation_methods
  has_attached_file :document, :url => "/:class/:id/:attachment/:style.:extension",
    # => Use this if we want to store to the file system instead of s3.
    # Comment out the remainder parameters
#    :path => ":Rails.root/attachments/:class/:id/:attachment/:style.:extension",
#    :styles=>{:thumb=>['100x100#', :png], :preview=>['400x400#', :png]}
#     styles: {:thumb=>['100x100#', :png], :preview=>['400x400#', :png]},
    styles: lambda { |a|
      a.instance.is_image? ? {:thumb=>['100x100#', :png], :preview=>['400x400#', :png]} : {}
    },
    s3_permissions: :private,
    s3_protocol:    'http',
    path:           ":id_partition/:random_secret/:style.:extension"

  # has_attached_file :document, :url => "/public/images/validations/:class/:id/:attachment/:style.:extension",
  #                       styles: lambda { |a|
  #                         a.instance.is_image? ? {:thumb=>['100x100#', :png], :preview=>['400x400#', :png]} : {}
  #                       }

  CONTENT_TYPES =   [['image/jpeg', 'jpg, jpeg, jpe, jfif'], ['image/png','png'],
    ['application/pdf', 'pdf'], ['image/tiff', 'tif, tiff'],
    ['image/gif', 'gif'], ['image/bmp', 'bmp'],
    ['application/zip', 'zip'], ['application/vnd.oasis.opendocument.text', 'odt'],
    ['application/msword', 'doc'], ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'docx'],
    ['audio/mpeg', 'mp3'], ['audio/x-mpeg', 'mp3'], ['audio/mp3', 'mp3'], ['audio/x-mp3', 'mp3'], ['audio/mpeg3', 'mp3'],
    ['audio/x-mpeg3', 'mp3'], ['audio/mpg', 'mp3'], ['audio/x-mpg', 'mp3'], ['audio/x-mpegaudio', 'mp3'], ['video/mp4', 'm4a'], ['text/plain', 'txt, text']]

  validates_attachment_content_type :document, :content_type =>  ValidationHistory::CONTENT_TYPES.transpose[0]

  preference  :viewing_method, :string, :default=>"download" #or thumbnail

  default_scope{ where{id << [3126]}} # temporary https://secure.ssl.com/certificate_orders/co-141e6s5s9/validation/edit

  # interpolate in paperclip
  Paperclip.interpolates :random_secret  do |attachment, style|
    attachment.instance.random_secret
  end

  def is_image?
    document.content_type =~ %r(image)
  end

  def registrant_document_url(registrant, style=nil)
    if style.blank? || document_content_type =~ %r(audio)
      %{/#{self.class.name.tableize}/#{id}/documents/#{document_file_name}?registrant=#{registrant.id}}
    else
      %{/#{self.class.name.tableize}/#{id}/documents/#{document.styles[style].name}.#{document.styles[style].format}?registrant=#{registrant.id}}
    end
  end

  def document_url(style=nil)
    if style.blank? || document_content_type =~ %r(audio)
      %{/#{self.class.name.tableize}/#{id}/documents/#{document_file_name}}
    else
      %{/#{self.class.name.tableize}/#{id}/documents/#{document.styles[style].name}.#{document.styles[style].format}}
    end
  end

  #def authenticated_s3_get_url(options={})
  #  options.reverse_merge! :expires_in => 10.minutes, :use_ssl => false
  #  AWS::S3::S3Object.url_for document.path(options[:style]), document.options[:bucket], options
  #end

  def self.multi_upload_types
    ValidationHistory::CONTENT_TYPES.transpose[1].map{|ct|ct.split(',')}.
      flatten.join('|').gsub(' ', '')
  end

  def self.acceptable_file_types
    ValidationHistory::CONTENT_TYPES.transpose[1].map{|ct|ct.split(',')}.
      flatten.uniq.join(', ').gsub('  ', ' ')
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
    expires_in = 10.minutes
    options.reverse_merge! expires_in: expires_in, use_ssl: true
    document.s3_object(options[:style]).presigned_url(:get, secure: true, expires_in: expires_in).to_s
  end

  private

  def set_random_secret
    self.random_secret = SecureRandom.hex(8)
  end
end

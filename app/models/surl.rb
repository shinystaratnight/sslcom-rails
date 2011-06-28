class Surl < ActiveRecord::Base
  belongs_to :user

  validate :url_format

  after_create do |s|
    s.update_attribute :identifier, s.id.to_s(36)
  end

  def url_format
    errors.add :original,
      "is an invalid url. Please be sure it begins with http://, https://, ftp://, or mailto:" unless
      [URI::HTTP, URI::HTTPS, URI::FTP, URI::MailTo].find do |url_type|
        URI.parse(original).kind_of?(url_type)
      end
  rescue e
  end
end

require 'open-uri'
require 'digest/sha1'

class LocalFile < ::Tempfile
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  def initialize(path, file_name = File.basename(path), tmpdir = Dir::tmpdir)
    raise "#{path} file does not exist" unless File.exist?(path)
    #content_type ||= @@image_mime_types[File.extname(path)]
    #raise "Unrecognized MIME type for #{path}" unless content_type
    #@content_type = content_type
    @original_filename = file_name
    super Digest::SHA1.hexdigest(path), tmpdir
    #@tempfile = Tempfile.new(@original_filename)
    FileUtils.copy_file(path, self.path)
  end

  alias local_path path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.send(method_name, *args, &block)
  end

  def original_filename
    @original_filename
  end

  def content_type
    mime = `file --mime -br #{self.path}`.strip
    mime = mime.gsub(/^.*: */,"")
    mime = mime.gsub(/;.*$/,"")
    mime = mime.gsub(/,.*$/,"")
    mime
  end
end

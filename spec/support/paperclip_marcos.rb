module PaperclipMacros
  def stub_paperclip(model)
    model.any_instance.stubs(:save_attached_files).returns(true)
    model.any_instance.stubs(:delete_attached_files).returns(true)
    Paperclip::Attachment.any_instance.stubs(:post_process).returns(true)
  end
end

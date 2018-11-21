class MailboxController < ApplicationController
  before_action :find_ssl_account
  before_action :get_mailbox
  before_action :unread_messages_count

  filter_access_to :all

  def inbox
    @emails = @mailbox.inbox
    @email_type = :inbox
  end

  def sent
    @emails = @mailbox.sentbox
    @email_type = :sent
  end

  def trash
    @emails = @mailbox.trash
    @email_type = :trash
  end

  def compose
    @email_type = :compose
    if request.post?
      recipients = User.where(email: params[:mail_recipients])
      @conversation = current_user.send_message(recipients, params[:mail_body], params[:mail_subject]).conversation
      
      redirect_to mail_read_path(@ssl_slug, conversation_id: @conversation),
        success: "Your message was successfully sent!"
    end
  end

  def reply
    get_conversation
    if @conversation
      current_user.reply_to_conversation(@conversation, params[:body])
    end
    redirect_to mail_read_path(@ssl_slug, conversation_id: @conversation), 
      notice: "Your reply message was successfully sent!"
  end

  def read
    get_conversation
    if @conversation
      @receipts = @conversation.receipts_for(current_user)
      @conversation.mark_as_read(current_user)
    else
      redirect_to mail_inbox_path(@ssl_slug), 
        error: "Could not locate this email, please try again!"
    end  
    @email_type = :read
  end

  def move_to_trash
    get_conversation
    if @conversation
      @conversation.move_to_trash(current_user)
      flash[:notice] = "Successfully moved email to trash." 
    else
      flash[:error] = "Something went wrong, please try again."
    end
    redirect_to mail_inbox_path(@ssl_slug)
  end

  private

  def get_conversation
    if @mailbox && params[:conversation_id]
      @conversation = @mailbox.conversations.find(params[:conversation_id])
    end
  end

  def get_mailbox
    if current_user
      @mailbox ||= current_user.mailbox
    end
  end

  def unread_messages_count
    if @mailbox
      @unread_messages = @mailbox.inbox(unread: true).uniq.count
    end
  end
end

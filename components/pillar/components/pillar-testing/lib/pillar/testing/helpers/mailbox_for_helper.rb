# frozen_string_literal: true

module Pillar
  module Testing
    module Helpers
      module MailboxForHelper
        class Mailbox
          attr_reader :email

          delegate :count, :size, :last, to: :deliveries

          def initialize(email)
            @email = email
          end

          def deliveries
            ActionMailer::Base.deliveries.select do |mail|
              mail.destinations.include?(email)
            end
          end
        end

        def mails_for(user_or_email)
          if ActionMailer::Base.delivery_method != :test
            raise "You can only use `mailbox` helper when " \
                  "ActionMailer::Base.delivery_method is `:test`"
          end

          email = user_or_email.respond_to?(:email) ?
                                user_or_email.email :
                                user_or_email

          Mailbox.new(email)
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Pillar::Testing::Helpers::MailboxForHelper
end

# == Schema Information
#
# Table name: caa_checks
#
#  id             :integer          not null, primary key
#  checkable_type :string(255)
#  domain         :string(255)
#  request        :string(255)
#  result         :text(65535)
#  created_at     :datetime
#  updated_at     :datetime
#  checkable_id   :integer
#
# Indexes
#
#  index_caa_checks_on_checkable_id_and_checkable_type  (checkable_id,checkable_type)
#

class CaaCheck < ApplicationRecord
  belongs_to :checkable, :polymorphic => true

  CAA_COMMAND=->(name, authority){
    %x{echo `cd #{Rails.application.secrets.caa_check_path} && python checkcaa.py #{name} #{authority}`}
  }

  CaaCheckJob = Struct.new(:certificate_order_id, :certificate_name, :certificate_content) do
    def perform
      name = certificate_name.name
      is_comodoca = certificate_content.nil? ? false : (certificate_content.ca.nil? ? false : true)

      if is_comodoca
        result = caa_lookup(name, I18n.t('labels.comodo_ca'))
        if result == true # Timeout
          return_obj = true
        elsif result =~ /status/ # Returned CAA Check Result.
          arry = JSON.parse(result.gsub("}\n", "}").gsub("\n", "|||"))
          log_caa_check(certificate_order_id, name, I18n.t('labels.comodo_ca'), arry)

          if arry['status'].to_s == 'true'
            return_obj = true
          elsif arry['status'].to_s == 'false'
            if arry['caatestout'].include? 'Failed to send CAA query to'
              return_obj = true
            elsif arry['caatestout'].include? 'not present in issue tag'
              return_obj = false
            end
          end
        else
          return_obj = false
        end
      else
        result = caa_lookup(name, I18n.t('labels.ssl_ca'))
        if result == true # Timeout
          return_obj = true
        elsif result =~ /status/ # Returned CAA Check Result.
          arry = JSON.parse(result.gsub("}\n", "}").gsub("\n", "|||"))
          log_caa_check(certificate_order_id, name, I18n.t('labels.ssl_ca'), arry)

          if arry['status'].to_s == 'true'
            return_obj = true
          elsif arry['status'].to_s == 'false'
            if arry['caatestout'].include? 'Failed to send CAA query to'
              return_obj = true
            elsif arry['caatestout'].include? 'not present in issue tag'
              return_obj = false
            end
          end
        else
          return_obj = false
        end
      end

      certificate_name.update_attribute(:caa_passed, return_obj)
    end

    def caa_lookup(name, authority)
      begin
        @checkcaa=IO.popen("echo `cd #{Rails.application.secrets.caa_check_path} && python checkcaa.py #{name} #{authority}`")
        result = @checkcaa.read
        Process.wait @checkcaa.pid
        result
      rescue RuntimeError
        return false
      rescue Exception=>e
        return false
      end
    end

    def log_caa_check(cert_order_ref, name, authority, result)
      dir = Rails.application.secrets.caa_check_log_path
      Dir.mkdir(dir) unless Dir.exists?(dir)

      caatestout = result['caatestout'].gsub("|||", "\n")
      message = result['message'].gsub("|||", "\n")

      log_path = (dir + '/' + cert_order_ref + '.txt').gsub('//', '/')
      file = File.open(log_path, 'a')
      file.write "**************************************** " + authority + " **************************************** \n"
      file.write "CAA " + authority + " check results for domain \"" + name + "\" at " + Time.now.strftime("%d/%m/%Y %H:%M:%S") + "\n"
      file.write "CAA " + authority + " test out : \n"
      file.write (caatestout + "\n").gsub("\n\n", "\n")
      file.write "Message : \n"
      file.write (message + "\n").gsub("\n\n", "\n")
      file.write "\n"
      file.close
    end
  end

  def self.pass?(certificate_order_id, certificate_name, certificate_content)
    true # Delayed::Job.enqueue CaaCheckJob.new(certificate_order_id, certificate_name, certificate_content)
  end
end

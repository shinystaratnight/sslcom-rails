class CaaCheck < ActiveRecord::Base
  belongs_to :checkable, :polymorphic => true

  CAA_COMMAND=->(name, authority){
    %x{echo `cd #{Rails.application.secrets.caa_check_path} && python checkcaa.py #{name} #{authority}`}
  }

  # def self.caa_lookup(name, authority)
  #   begin
  #     Timeout.timeout(Surl::TIMEOUT_DURATION) do
  #       CAA_COMMAND.call name, authority
  #     end
  #   rescue Timeout::Error
  #     return true
  #   rescue RuntimeError
  #     return false
  #   end
  # end

  def self.caa_lookup(name, authority)
    begin
      # Timeout.timeout(Surl::TIMEOUT_CAA_CHECK_DURATION) do
        @checkcaa=IO.popen("echo `cd #{Rails.application.secrets.caa_check_path} && python checkcaa.py #{name} #{authority}`")
        result = @checkcaa.read
        Process.wait @checkcaa.pid
        result
      # end
    # rescue Timeout::Error
    #   Process.kill 9, @checkcaa.pid
    #   # we need to collect status so it doesn't
    #   # stick around as zombie process
    #   Process.wait @checkcaa.pid
    #   return true
    rescue RuntimeError
      return false
    rescue Exception=>e
      return false
    end
  end

  def self.pass?(certificate_order_id, name)
    result = caa_lookup(name, "comodoca.com")
    if result == true # Timeout
      return_obj = true
    elsif result =~ /status/ # Returned CAA Check Result.
      arry = JSON.parse(result.gsub("}\n", "}").gsub("\n", "|||"))
      log_caa_check(certificate_order_id, name, 'comodoca.com', arry)
      # return_obj = (arry['status'].to_s == 'true') ||
      #     (arry['status'].to_s == 'false' && arry['caatestout'].include?('Failed to send CAA query to'))

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

    result = caa_lookup(name, "ssl.com")
    if result == true # Timeout
      return_obj = true
    elsif result =~ /status/ # Returned CAA Check Result.
      arry = JSON.parse(result.gsub("}\n", "}").gsub("\n", "|||"))
      log_caa_check(certificate_order_id, name, 'ssl.com', arry)
      # return_obj = return_obj && (arry['status'].to_s == 'true')

      if arry['status'].to_s == 'true'
        return_obj &&= true
      elsif arry['status'].to_s == 'false'
        if arry['caatestout'].include? 'Failed to send CAA query to'
          return_obj &&= true
        elsif arry['caatestout'].include? 'not present in issue tag'
          return_obj = false
        end
      end
    else
      return_obj = false
    end

    return return_obj
  end

  private

  def self.log_caa_check(cert_order_ref, name, authority, result)
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
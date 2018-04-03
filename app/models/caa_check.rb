class CaaCheck < ActiveRecord::Base
  belongs_to :checkable, :polymorphic => true

  # CAA_COMMAND=->(name){%x"echo QUIT | caatest -issuer ssl.com #{name}"}
  # CAA_COMMAND=->(name){%x"echo QUIT | python checkcaa.py #{name}"}
  CAA_COMMAND=->(name){
    %x{echo `cd #{Rails.application.secrets.caa_check_path} && python checkcaa.py #{name}`}
  }

  def self.caa_lookup(name)
    CAA_COMMAND.call name
  end

  def self.pass?(certificate_order_id, name)
    result = caa_lookup(name)
    if result =~ /status/ #Returned CAA Check Result.
      arry = JSON.parse(result.gsub("}\n", "}").gsub("\n", "|||"))
      log_caa_check(certificate_order_id, name, arry)
      return arry['status'].to_s == 'true'
    else
      return false
    end

    # if result =~ /CAA set contains following records/ # CAA exists, let's dig deeper
    #   if name =~ /^\*\./ # if name is a wildcard
    #     name.gsub!(/^\*\./,'') # remove the leading *.
    #     if result =~ Regexp.new('^.*?'+name+'.*?issuewild\s*?"ssl.com"') # ok to issue for wildcard
    #       true
    #     elsif result =~ Regexp.new('^.*?'+name+'.*?issuewild\s*?"') # ssl.com is not listed
    #       false
    #     else
    #       true # all clear
    #     end
    #   else
    #     if result =~ Regexp.new('^.*?'+name+'.*?issue\s*?"ssl.com"')
    #       true
    #     elsif result =~ Regexp.new('^.*?'+name+'.*?issue\s*?"') # ssl.com is not listed
    #       false
    #     else
    #       true # all clear
    #     end
    #   end
    # else
    #   true
    # end
  end

  private

  def self.log_caa_check(cert_order_ref, name, result)
    dir = Rails.application.secrets.caa_check_log_path
    Dir.mkdir(dir) unless Dir.exists?(dir)

    caatestout = result['caatestout'].gsub("|||", "\n")
    message = result['message'].gsub("|||", "\n")

    log_path = (dir + '/' + cert_order_ref + '.txt').gsub('//', '/')
    file = File.open(log_path, 'a')
    file.write "******************************************************************************** \n"
    file.write "CAA Check Results for Domain \"" + name + "\" at " + Time.now.strftime("%d/%m/%Y %H:%M:%S") + "\n"
    file.write "CAA Test Out : \n"
    file.write (caatestout + "\n").gsub("\n\n", "\n")
    file.write "Message : \n"
    file.write (message + "\n").gsub("\n\n", "\n")
    file.write "\n"
    file.close
  end
end
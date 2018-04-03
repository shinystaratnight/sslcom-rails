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

  def self.pass?(name)
    result = caa_lookup(name)
    if result =~ /status/ #Returned CAA Check Result.
      arry = result.split(',')
      status = arry[0] if arry
      return status.split(':')[1].gsub(' ', '') == 'true'
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
end
module Kernel
 private
    def this_method_name
      caller[0] =~ /`([^']*)'/ and $1
    end
end

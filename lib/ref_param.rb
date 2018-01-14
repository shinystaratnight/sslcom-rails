module RefParam
  extend ActiveSupport::Concern

  included do
    before_create :assign_ref
  end

  # be sure `ref` attribute exists
  def assign_ref
    self.ref="#{initials}-#{SecureRandom.hex(6)}"
  end

  def initials
    self.class.to_s.tableize.split("_").map{|w|w[0]}.join
  end
end



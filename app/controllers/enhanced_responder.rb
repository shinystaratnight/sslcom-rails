class EnhancedResponder < ActionController::Responder
=begin
  include CachedResponder
  include FlashResponder
=end
  include PaginatedResponder
end
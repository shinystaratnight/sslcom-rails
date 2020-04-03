class ApplicationDecorator < Draper::Decorator
  include Draper::LazyHelpers

  def self.collection_decorator_class
    PaginatingDecorator
  end
end

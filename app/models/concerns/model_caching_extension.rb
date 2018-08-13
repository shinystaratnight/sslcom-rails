module ModelCachingExtension
  extend ActiveSupport::Concern

  included do
    class << self
      # The first time you call Model.all_cached it will cache the collection,
      # each consequent call will not fire the DB query
      def all_cached
        Rails.cache.fetch(["cached_#{name.underscore.to_s}s"]) { self.all.entries }
      end
    end

    after_commit :clear_cache

    private

    # Making sure, that data is in consistent state by removing the cache
    # everytime, the table is touched (eg some record is edited/created/destroyed etc).
    def clear_cache
      Rails.cache.delete(["cached_#{name.underscore.to_s}"])
    end
  end
end
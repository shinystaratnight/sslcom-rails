ActionMailer::Base.class_eval do

  DELIVERIES_CACHE_PATH =
    File.join(Rails.root,'tmp','cache','action_mailer_cache_deliveries.cache')

  def perform_delivery_cache(mail)
    deliveries = File.open(DELIVERIES_CACHE_PATH, 'r') do |f|
      Marshal.load(f)
    end
      
    deliveries << mail
    File.open(DELIVERIES_CACHE_PATH,'w') do |f|
      Marshal.dump(deliveries, f)
    end
  end

  def self.cached_deliveries
    File.open(DELIVERIES_CACHE_PATH,'r') do |f|
      Marshal.load(f)
    end
  end

  def self.clear_cache
    deliveries.clear
    File.open(DELIVERIES_CACHE_PATH,'w') do |f|
      Marshal.dump(deliveries, f)
    end
  end

end

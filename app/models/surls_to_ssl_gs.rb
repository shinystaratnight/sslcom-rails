module SurlsToSslGs
  def self.initialize
    tables=%w(Customer Order Certificate OrderNumber Merchant MerchantContact
      OrdersShoppingCart)
    tables.each do |t|
      tc = ('OldSite::'+t).constantize
      source_tables=V2MigrationProgress.all.select {|p|
        p.source_table_name==tc.table_name} || []
      #if the number of records on the source table has change, then migrate
      #those records again
      unless tc.count==source_tables.count
        source_tables.each {|sc|sc.delete}
        tc.find_each do |o|
        V2MigrationProgress.create(:source_table_name=>tc.table_name,
          :source_id=>o.source_obj_id)
        end
      end
    end
  end

  #this function is preferable to initialize because it does not delete existing
  #records and instead just adds new ones
  def self.dynamic_initialize
    tables=%w(Customer Order Certificate OrderNumber Merchant MerchantContact
      OrdersShoppingCart)
    V2MigrationProgress.remove_migratable_orphans
    tables.each do |t|
      OldSite.detect_abort
      ap "looking for new records for #{t}"
      tc = ('OldSite::'+t).constantize
      V2MigrationProgress.remove_legacy_orphans(tc)
      source_tables=V2MigrationProgress.select(:source_id).where(:source_table_name.eq => tc.table_name) || []
      #if the number of records on the source table has change, then add the new
      #records
      unless tc.count==source_tables.count
        legacy_ids=tc.source_ids
        ap ["legacy count: #{tc.count.to_s}", "migration progress count: #{source_tables.count.to_s}"].join(", ")
        missing = legacy_ids-source_tables.map(&:source_id)
        tc.where(tc.primary_key.to_sym + missing).each do |o|
          ap "creating V2MigrationProgress for #{tc.table_name+'_'+o.send(tc.primary_key).to_s}"
          V2MigrationProgress.create(:source_table_name=>tc.table_name,
            :source_id=>o.source_obj_id)
        end
      else
        ap "no new records found for #{t}"
      end
    end
  end

  # this is the main function to do the migration
  def self.migrate_all
    Authorization.ignore_access_control(true)
    ActiveRecord::Base.logger.level = 3 # at any time
    ap "Usage: type 'Q' and press Enter to exit this program"
    dynamic_initialize
    Customer.migrate_all
    Order.migrate_all
    Customer.sync_attributes_with_v2
    ::DuplicateV2User.make_latest_login_primary
    Certificate.sync_certs
    #verify all LineItems have a sellable or else delete them
    LineItem.all.each{|l|l.destroy if l.sellable.blank?}
    self.adjust_site_seals_workflow
    self.adjust_certificate_order_prepaid
    self.adjust_certificate_content_workflow
  end

  def self.certs_and_line_items_mismatch
    ActiveRecord::Base.logger.level = 3 # at any time
    i=0
    OldSite::Order.find_each(:include=>{:order_number=>
        [{:certificates=>{:certificate_product=>:product}},
        :orders_shopping_carts]}) do |o|
      ids=[]
      o.order_number.orders_shopping_carts.each do |osc|
        ids<<osc.order_number.certificates.map(&:product).map(&:ProductID)
      end
      if ids.uniq.count>1
        p 'Error! '+o.OrderNumber
        logger.error 'Certificate products mismatch for order: '+o.OrderNumber
      else
        p [ids, "count: #{i+=1}, OrderID: #{o.OrderNumber}"]
      end
    end
  end

  #just a one-time-use convenience method. The logic fix was incorporated into
  #the migration script
  def self.adjust_user_profile_info
    OldSite::Customer.find_each do |c|
      u=V2MigrationProgress.find_by_source(c).migratable
      (u.updated_at=c.updated_at
           u.first_name= c.FirstName
            u.last_name = c.LastName
          u.update_record_without_timestamping) unless u.blank?
    end
  end

  #just a one-time-use convenience method. The logic fix was incorporated into
  #the migration script
  def self.adjust_order_payment_method
    ActiveRecord::Base.logger.level = 3 # at any time
    ::Order.find_each do |o|
      old_o=V2MigrationProgress.find_by_migratable_and_source_table_name(o,
        "Orders", :first)
      unless old_o.blank?
        old_o.source_obj.copy_payment_method_to(o)
        o.save
      end
    end
  end

  #just a one-time-use convenience method. Just trying to import skipped
  #signed certificates
  def self.import_signed_certificates
    Authorization.ignore_access_control(true)
    ActiveRecord::Base.logger.level = 3 # at any time
    i=0
    count = ::Csr.count
    ::Csr.find_each do |c|
      cert = c.certificate_content.try(:migrated_from)
      cert = cert.last unless cert.blank?
      unless cert.blank?
        p ["#{i+=1} of #{count}, CertificateID: #{cert.CertificateID}"]
        if c.signed_certificate.blank? && !cert.SignedCert.blank?
            c.signed_certificate_by_text=cert.SignedCert
          if c.signed_certificate
            c.signed_certificate.update_attribute(:created_at,
              cert.ReadyNoticeSentToCustomer)
            c.certificate_content.workflow_state='issued'
          else
            c.certificate_content.workflow_state='csr_submitted'
            msg="Error: Could not import signed certificate
              from Old::Certificate#{cert.CertificateID}"
            logger.error msg
            p msg
          end
          c.save
        end
      end
    end
  end

  #just a one-time-use convenience method. The logic fix was incorporated into
  #the migration script
  def self.adjust_signed_certificate_created_at
    SignedCertificate.find_each do |sc|
      sc.update_attribute :created_at, sc.csr.certificate_content.created_at
    end
  end

  #just a one-time-use convenience method. The logic fix was incorporated into
  #the migration script
  def self.adjust_server_type
    ::CertificateContent.find_each do |cc|
      if cc.server_software.blank?
        unless V2MigrationProgress.find_by_migratable(cc).blank?
          c=V2MigrationProgress.find_by_migratable(cc).source_obj
          cc.created_at=c.SubmitDate
          cc.server_software=OldSite::ServerType.server_software(
            c.ServerType)
          cc.save(false)
        end
      end
    end
  end

  #just a one-time-use convenience method. The logic fix was incorporated into
  #the migration script
  def self.adjust_line_items
    Authorization.ignore_access_control(true)
    CertificateOrder.find_each do |co|
      if co.order
        oscs=V2MigrationProgress.find_by_migratable co.order, :all
        unless oscs.empty?
          o=oscs.find{|osc|osc.source_obj.is_a? OrdersShoppingCart}.source_obj
          if o
            items=o.orders_kit_carts.each_with_object([]) do |okc, arry|
              arry << okc.KitItemName
            end
            co.v2_line_items=items unless items.empty?
            co.line_item_qty=1
            co.save
          end
        end
      end
    end
  end

  #one time function to correct misplaced v2_migration_progress from users to duplicate_v2_users
  def self.update_v2_migrations_for_duplicate_users
    migs = DuplicateV2User.all
    created = migs.map(&:created_at)
    dups=[]
    dup_tmp=created.each{|c|dups<<c if created.count(c) > 1} #find duplicates
    dup_created_at=migs.select{|c|c.created_at==dup_tmp[0]}
    migs-=dup_created_at
    migs_h = Hash[migs.map{|m|[m.created_at.to_s, m]}] #hash migrated dups using created_at.to_s as key
    oc=OldSite::Customer.select("CustomerID, CreatedOn")
    oc_h=Hash[oc.map{|o|[o.CreatedOn.to_s, o]}] #hash legacy users using CreatedOn.to_s as key
    migs_h.merge!(oc_h){|key, old, new|[new, old]}
    non_matched=migs_h.select{|k,v|!v.is_a?(Array)}
    non_matched.each{|k,v|migs_h.delete(k)}
    migs_h.each do |k,v|
      mp=v[0].v2_migration_progress
      mp.migratable=v[1]
      mp.save
    end
  end

  #DEPRECATED - see OldSite::Customer.sync_attributes_with_v2
  #user changes such as passwords or emails (or even logins) are sync using this method
  def self.sync_changed_users
    d = DuplicateV2User.all
    v2_users = V2MigrationProgress.where(:migratable_type =~ "User").map(&:migratable).uniq
    #get all migrated users into array
    migs=d+v2_users
    created = migs.map(&:created_at)
    dups=[]
    dup_tmp=created.each{|c|dups<<c if created.count(c) > 1} #find duplicates
    dup_created_at=migs.select{|c|c.created_at==dup_tmp[0]}
    migs-=dup_created_at
    migs_h = Hash[migs.map{|m|[m.created_at.to_s, m]}] #hash migrated users/dups using created_at.to_s as key
    oc=OldSite::Customer.select("Email, UserName, Password, CreatedOn")
    oc_h=Hash[oc.map{|o|[o.CreatedOn.to_s, o]}] #hash legacy users using CreatedOn.to_s as key
    migs_h.merge!(oc_h){|key, old, new|[new, old]}
    non_matched=migs_h.select{|k,v|!v.is_a?(Array)}
    non_matched.each{|k,v|migs_h.delete(k)}
    changed=migs_h.select do |k,v|
      v[1].email!=v[0].Email || (v[1].is_a?(User) ? v[1].crypted_password : v[1].password)!=v[0].Password ||
          v[1].login!=v[0].UserName
    end
    msgs=[]
    changed.each do |k,v|
      msgs<< "changes detected for #{v[1].model_and_id}"
      if v[1].email!=v[0].Email
        msgs<< "email changed from #{v[1].email} to #{v[0].Email}"
        v[1].update_attribute :email, v[0].Email
      end
      if (v[1].is_a?(User) ? v[1].crypted_password : v[1].password)!=v[0].Password
        msgs<< "password changed from #{v[1].is_a?(User) ? v[1].crypted_password : v[1].password} to #{v[0].Password}"
        v[1].update_attribute (v[1].is_a?(User) ? :crypted_password : :password), v[0].Password
      end
      if v[1].login!=v[0].UserName
        msgs<< "login changed from #{v[1].login} to #{v[0].UserName}"
        v[1].update_attribute :login, v[0].UserName
      end
    end
    ap msgs
    #oc_created_at=oc.map(&:CreatedOn)
    #oc_s=oc_created_at.sort.map(&:to_s)
    #ca_s=created.sort.map(&:to_s)
    #diff_s=oc_s-ca_s
  end

  def self.sync_duplicate_v2_user_attributes
    DuplicateV2User.sync_mismatched_attributes if DuplicateV2User.mismatched_attributes.blank?
    if DuplicateV2User.mismatched_attributes.blank?
      "successfully synced DuplicateV2User attributes"
    else
      "failed syncing DuplicateV2User attributes"
    end
  end

  def self.adjust_certificate_content_workflow
    CertificateContent.find_each(:include=>
      [:registrant,:certificate_contacts, {:csr=>:signed_certificates}]) do |cc|
      if V2MigrationProgress.find_by_migratable_id_and_migratable_type cc.id,
          'CertificateContent'
        csr = cc.csr
        cert = csr.try(:signed_certificate)
        registrant = cc.registrant
        contacts = cc.certificate_contacts
        if cert
          cc.update_attribute :workflow_state, 'issued'
        elsif !contacts.empty?
          cc.update_attribute :workflow_state, 'contacts_provided'
        elsif registrant
          cc.update_attribute :workflow_state, 'info_provided'
        elsif csr
          cc.update_attribute :workflow_state, 'csr_submitted'
        else
          cc.update_attribute :workflow_state, 'new'
        end
      end
    end
  end

  def self.adjust_certificate_order_prepaid
    CertificateOrder.find_each(:include=>[:orders, :certificate_contents]) do |co|
      if co.order.try("preferred_migrated_from_v2?")
        if co.workflow_state=='paid' && co.certificate_content.blank?
          co.preferred_payment_order = 'prepaid'
          co.save
        end
      end
    end
  end

  def self.adjust_site_seals_workflow
    SiteSeal.find_each(:include=>
        {:certificate_orders=>[:certificate_contents, :orders]}) do |ss|
      unless ss.certificate_order.blank? || ss.certificate_order.order.blank?
        state =  ss.certificate_order.certificate_content.workflow_state if
          ss.certificate_order && ss.certificate_order.certificate_content
        case state
        when 'issued'
          ss.update_attribute :workflow_state,
            SiteSeal::FULLY_ACTIVATED.to_s
        when 'new'
          ss.update_attribute :workflow_state, 'new'
        else
          ss.update_attribute :workflow_state,
            SiteSeal::CONDITIONALLY_ACTIVATED.to_s
        end
        ss.update_seal_type
      end
    end
  end

  # we need to verify at the data level that migration integrity has been maintained
  # compare non-duplicate user accounts and their orders and certificates
  # then compare duplicates
  def self.verify_migration_integrity
    # for each v1 user, find the corresponding v2 user
    # compare orders quantity and prices
    # compare csrs and signed certificates (quantity and contents)
    # we'll start off with non dupllicates and verify 1-to-1 mappings to orders
    [].tap do |order_count_mismatch|
      i=0
      nd=OldSite::Customer.non_duplicates
      p "total  #{nd.count.to_s} legacy users to process"
      nd.find_each do |c|
        # need to get v2 user
        p "processed #{i.to_s} legacy users" if i%100==0
        user = c.migratable
        if user.is_a?(User) && user.ssl_account
          if user.cached_ssl_account.orders.count == c.orders.count
            #user.ssl_account.orders.each do |o|
            #  o
            #end
          else
            order_count_mismatch << user
            p "#{user.login} (#{user.mode_and_id}) doesn't have the same number of orders as the legacy user"
          end
        end
        i+=1
      end
    end
    #OldSite::Customer.duplicates.find_each do |c|
    #  # need to get v2 user
    #  user = c.migratable.class == User ? c.migratable : c.migratable.user
    #  user.ssl_account.orders.count >= c.orders.count
    #end
  end

  class Base < ActiveRecord::Base
    establish_connection :ssl_gs
    self.abstract_class=true

    def self.source_ids
      key = self.primary_key.to_sym
      select(key).map(&key)
    end

    def source_obj_id
      send(self.class.primary_key)
    end

  end

  class X3User < Base
    set_table_name 'x3_users'
    set_primary_key 'id'
    def self.pk_sym
      primary_key.to_sym
    end
  end

  class X3Link < Base
    set_table_name 'x3_links'
    set_primary_key 'id'
    def self.pk_sym
      primary_key.to_sym
    end

    def self.migrate
      Surl.where{(id > 7) & (original != nil)}.find_each{|s|
        X3Link.create(short_url: "http://ssl.gs/"+s.identifier,
                      long_url: s.original, adtype: "Interstitial",
                      post_date: s.created_at,
                      title: "Get paid to shorten and share links at ssl.gs",
                      views: 0,
                      earned: BigDecimal(0),
                      user: 0
        )
      }
    end
  end
end if Rails.env=='development' && MIGRATING_SURLS_TO_SSL_GS


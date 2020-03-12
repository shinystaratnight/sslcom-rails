module OldSite
  def self.quit?
    begin
      # See if a 'Q' has been typed yet
      while c = STDIN.read_nonblock(1)
        puts "Q pressed"
        return true if c == 'Q'
      end
      # No 'Q' found
      false
    rescue Errno::EINTR
      false
    rescue Errno::EAGAIN
      # nothing was ready to be read
      false
    rescue EOFError
      # quit on the end of the input stream
      # (user hit CTRL-D)
      true
    end
  end

  def self.detect_abort
    abort('Exit: user terminated') if quit?
  end

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
    ApplicationRecord.logger.level = 3 # at any time
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
    ApplicationRecord.logger.level = 3 # at any time
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
    ApplicationRecord.logger.level = 3 # at any time
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
    ApplicationRecord.logger.level = 3 # at any time
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
          if user.ssl_account.cached_orders.count == c.orders.count
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

  class Base < ApplicationRecord
    establish_connection :ssl_store_mssql
    self.abstract_class=true

    def self.source_ids
      key = self.primary_key.to_sym
      select(key).map(&key)
    end

    def source_obj_id
      send(self.class.primary_key)
    end

    def v2_migration_progress
      V2MigrationProgress.find_by_source self
    end

    def migratable
      v2_migration_progress.migratable
    end

    def self.v2_migration_progresses
      V2MigrationProgress.find_all_by_source_table_name(table_name)
    end

    def self.unmigrated_records
      ids = source_ids
      vids=V2MigrationProgress.select(:source_id).
          where((:source_table_name =~ table_name) & ((:migrated_at ^ nil) |
          (:migratable_type ^ nil))).map(&:source_id)
      unmigrated = ids-vids
      ap ["all #{self.class.to_s} objs: "+ids.count.to_s, "migrated: "+vids.count.to_s,
          "remaining: "+unmigrated.count.to_s].join(', ')
      [where(primary_key.to_sym + unmigrated), unmigrated.count]
    end

    def migratable_exists?
      vmp=V2MigrationProgress.includes(:migratable).find_by_source(self)
      vmp && vmp.migrated_at && vmp.migratable
    end

    def record_migration_progress(p=nil)
      mp = V2MigrationProgress.includes(:migratable).find_by_old_object(self)
      if mp.blank?
        msg="Error: V2MigrationProgress record is blank for #{self.model_and_id}"
        logger.error(msg)
        ap msg
      elsif mp.migrated_at.blank? || mp.migratable.blank?
        begin
          migratable=p ? migrate(p) : migrate
        rescue Exception=>e
          msg="Error in #{self.model_and_id}#{' for '+p.model_and_id if p && !p.is_a?(Hash)} : #{e.message}"
          logger.error(msg)
          ap msg
          ap e.backtrace.inspect
          raise e
        end
        mp.update_attributes :migrated_at=>Time.new,
          :migratable=>(migratable)
        migratable
      else
        logger.error "Error!: Already migrated #{self.id}"
        mp.migratable
      end
    end

    def copy_attributes(corresponding)
      self.class::ATTR_MAP.each do |k,v|
        corresponding.send(k.to_s+"=", (k!=:country ? self.send(v) : OldSite::MerchantContact.convert_country(self.send(v))))
      end
    end

    def unmatched_attributes(corresponding)
      attrs=self.class::ATTR_MAP.select do |k,v|
        corresponding.send(k) != (k!=:country ? self.send(v) : OldSite::MerchantContact.convert_country(self.send(v)))
      end
    end

    def sync_unmatched_attributes(corresponding)
      attrs=self.class::ATTR_MAP.each do |k,v|
        val=(k!=:country ? self.send(v) : OldSite::MerchantContact.convert_country(self.send(v)))
        if corresponding.send(k) != val
          corresponding.update_attribute k, val
        end
      end
    end

    def sync_unmatched_attributes_for_migratable
      migratable_tmp=V2MigrationProgress.find_by_old_object(self).migratable
      sync_unmatched_attributes(migratable_tmp) if migratable_tmp
    end

    def unmatched_attributes_for_migratable
      migratable_tmp=V2MigrationProgress.find_by_old_object(self).migratable
      unmatched_attributes(migratable_tmp) if migratable_tmp
    end

    def self.verification_report
      unmatched, no_migratable = [], []
      find_each do |r|
        attrs=r.unmatched_attributes_for_migratable
        if attrs
          unless attrs.empty?
            unmatched << r.id
            #ap "unmatched attributes #{attrs.to_s} found for #{r.model_and_id}"
          end
        else
          no_migratable<<r.id
          #ap "migratable no found for #{r.model_and_id}"
        end
      end
      ap "unmatched attributes found for the following #{base_class.to_s}: #{unmatched}"
      ap "no migratables found for the following #{base_class.to_s}: #{no_migratable}"
      [unmatched, no_migratable]
    end
  end

  class Customer < Base
    set_table_name 'Customer'
    set_primary_key 'CustomerID'
    has_many  :orders, :class_name=>'OldSite::Order', :foreign_key=>'CustomerID'
    has_many  :certificates, :through=>:orders
    has_many :merchants, :class_name=>'OldSite::Merchant',
      :foreign_key=>'CustomerID'
    has_many :billing_addresses, :class_name=>'OldSite::Address',
      :foreign_key=>'CustomerID'
    has_many  :orders_kit_carts, :class_name=>'OldSite::OrdersKitCart',
      :foreign_key=>'CustomerID'
    has_many  :kit_carts, :class_name=>'OldSite::KitCart',
      :foreign_key=>'CustomerID'
    has_many  :addresses, :class_name=>'OldSite::Address',
      :foreign_key=>'CustomerID'
    belongs_to :company, :class_name=>'OldSite::Company',
      :foreign_key=>'CompanyID'
    alias_attribute :id, :CustomerID
    alias_attribute :login, :UserName
    alias_attribute :email, :Email
    alias_attribute :crypted_password, :Password
    alias_attribute :created_at, :CreatedOn
    alias_attribute :updated_at, :LastUpdated
    attr_accessor   :status

    after_initialize do
      if new_record?
        self.status ||= "enabled"
      end
    end

    def self.invalid_accounts
      [].tap do |ia|
        unscoped.select([primary_key, "Email", "UserName"]).find_each do |c|
          ia << c if (c.Email.length < 6) || (c.UserName.length < 3) ||
              (c.Email !~ Authlogic::Regex.email) || (c.UserName !~ Authlogic::Regex.login)
        end
      end
    end

    INVALID_ACCOUNTS ||= OldSite::Customer.invalid_accounts

    default_scope{ where(primary_key.to_sym - OldSite::Customer::INVALID_ACCOUNTS.map(&:CustomerID))}

    def self.pk_sym
      primary_key.to_sym
    end

    def migrate
      lu = LegacyV2UserMapping.create(:old_user_id=>self.id)
      u = User.find_by_login(self.login) || User.find_by_email(self.email)
      if u
        du=DuplicateV2User.create(:user=>u, :login=>self.login,
          :email=>self.email, :password=>self.crypted_password, :created_at=>
          self.created_at, :updated_at=>self.updated_at)
        du.legacy_v2_user_mappings << lu
        ap "created DuplicateV2User #{du.model_and_id}"
      else
        u = User.new
        props = %w(id login email crypted_password created_at
          updated_at status)
        props.each do |p|
          u.send(p+'=', self.send(p))
        end
        u.first_name = self.FirstName
        u.last_name = self.LastName
        u.active=true
        u.roles << Role.find_by_name(Role::CUSTOMER)
        u.create_ssl_account
        u.legacy_v2_user_mappings << lu
        if u.save
          ap "created #{u.model_and_id}"
        else
          ap "failed! #{u.model_and_id} not saved: #{u.errors.full_messages.join(", ")}"
        end
      end
      du || u
    end

#    def migrate_from_old
#      lu = LegacyV2UserMapping.create(:old_user_id=>self.id)
#      u = User.find_by_login(self.login) || User.find_by_email(self.email)
#      if u
#        sa=u.ssl_account
#        du=DuplicateV2User.create(:user=>u, :login=>self.login,
#          :email=>self.email, :password=>self.crypted_password, :created_at=>
#          self.created_at)
#        du.legacy_v2_user_mappings << lu
#      else
#        u = User.new
#        props = %w(id login email crypted_password created_at status)
#        props.each do |p|
#          u.send(p+'=', self.send(p))
#        end
#        u.active=true
#        u.roles << Role.find_by_name(Role::CUSTOMER)
#        sa=u.create_ssl_account
#        u.legacy_v2_user_mappings << lu
#        u.save
#      end
#      self.orders.each do |order|
#        #create order
#        o = ::Order.create(:created_at=>order.OrderDate)
#        o.billable=sa
#        o.preferred_migrated_from_v2 = true
#        o.cents=(order.OrderTotal*100).to_i
#        o.currency="USD"
#        order_num = order.order_number
#        case order.PaymentMethod
#        when "Request Quote"
#          o.state="quote"
#        when "Check", "Purchase Order", "Credit Card"
#          o.state="paid"
#        end
#        #create order transaction
#        ot=o.transactions.create(:created_at=>order.OrderDate)
#        ot.amount=o.cents
#        ot.success=true
#        ot.message=order.AuthorizationResult
#        ot.action="purchase"
#        #create line_items
#        order_num.orders_shopping_carts.each do |c|
#          o.description=[o.description, c.OrderedProductDescription].join(': ')
#          saved_qty = false
#          c.Quantity.times do |i|
#            co=CertificateOrder.new(:created_at=>order.OrderDate)
#            co.sub_order_items << SubOrderItem.create(:product_variant_item=>
#                ProductVariantItem.find_by_serial('mssl'))
#            co.amount=(c.OrderedProductPrice*100).to_i/c.Quantity
#            co.preferred_payment_order='prepaid' if c.certificates[i].blank? ||
#              c.certificates[i].UnsignedCert.blank?
#            #co.pay! true
#            co.ssl_account=sa
#            co.save
#            li=o.line_items.create
#            li.cents=(c.OrderedProductPrice*100).to_i
#            li.sellable=co
#            li.save
#            #saving processed certs for paid only orders
#            if o.state=="paid"
#              unless c.certificates[i].blank?
#                cert = c.certificates[i]
#                cc=co.certificate_contents.create
#                unless cert.UnsignedCert.blank?
#                  cc.signing_request=cert.UnsignedCert
#                  cc.created_at=cert.SubmitDate
#                  cc.server_software=OldSite::ServerType.server_software(
#                    cert.ServerType)
#                  cc.csr.signed_certificate_by_text=cert.SignedCert unless
#                    cert.SignedCert.blank?
#                  cc.save
#                  if m = cert.merchant
#                    r = m.copy_attributes_to cc.create_registrant
#                    r.save
#                    m.merchant_contacts.each do |mc|
#                      unless mc.MerchantID==0
#                        c_contact=cc.certificate_contacts.create
#                        mc.copy_attributes_to c_contact
#                        c_contact.save if c_contact.valid?
#                      end
#                    end
#                  end
#                  #36 certificates with unsignedcerts have no merchant
#                end
#                unless saved_qty
#                  #only one CertificateOrder needs to store qty info
#                  co.line_item_qty=c.Quantity
#                  saved_qty=true
#                end
#              end
#            end
#          end
#          #disregard billing profiles
#          #sa.billing_profiles << BillingProfile.new(order.billing_fields)
#        end
#        unless sa.orders<<o
#          p order.OrderNumber
#          raise ActiveRecord::Rollback, "Failed at OrderNumber #{order.
#          OrderNumber}"
#        end
#      end
#    end

    def self.migrate_all
      migrate_these = unmigrated_records
      i=migrate_these[1]
      unmigrated_records[0].find_each do |c|
      #unmigrated_records[0].where(primary_key.to_sym - INVALID_ACCOUNTS.map(&pk_sym)).find_each do |c|
        OldSite.detect_abort
        i-=1
        c.record_migration_progress unless c.migratable_exists?
        ap "#{i} #{table_name} records remaining for migration"
      end
      V2MigrationProgress.status(self)
    end

    # find email addresses of v1 accounts that are duplicates
    def self.duplicate_emails
      all(:group=>'Email', :select=>'Email', :having=>'count(Email)>1')
    end

    # find logins of v1 accounts that are duplicates
    def self.duplicate_logins
      all(:group=>'UserName', :select=>'UserName',
        :having=>'count(UserName)>1')
    end

    # find duplicate usernames based on v1 users with duplicate email addresses
    def self.find_dup_email_and_username
      names=duplicate_emails.map(&:email).map {|e|
        OldSite::Customer.find_all_by_Email(e)}.map{|e| e.map(&:UserName)}
      global_dup = []
      names.each do |n|
        g = names.pop
        g.each do |m|
          global_dup << m if names.flatten.include?(m)
        end
      end
      global_dup
    end

    #these customers are not 'corrupted' with duplicate usernames or emails
    def self.non_duplicates
      de = duplicate_emails.map(&:Email)
      dl = duplicate_logins.map(&:UserName)
      where((:Email - de) & (:UserName - dl))
    end

    #these customers are 'corrupted' with either duplicate usernames or emails
    def self.duplicates
      de = duplicate_emails.map(&:Email)
      dl = duplicate_logins.map(&:UserName)
      where((:Email + de) | (:UserName + dl))
    end

    def self.unmigrate_all
      Authorization.ignore_access_control(true)
      OldSite::Customer.all.each {|c|
        if User.exists?(c.id)
          u=User.find(c.id)
          u.ssl_account.destroy
        end}
    end

    def self.sync_attributes_with_v2
      count=0
      select([:CustomerID, :UserName, :Email, :Password,
              :CreatedOn, :LastUpdated]).find_in_batches do |customers|
        l, e, p, c, u = 0,0,0,0,0
        V2MigrationProgress.includes(:migratable).
            where({:source_table_name=>"Customer"} & :source_id + customers.map(&:CustomerID)).each do |v|
          o=customers.find{|c|c.CustomerID==v.source_id}
          n=v.migratable
          if n.login != o.UserName
            p "changing username from #{n.login} to #{o.UserName}"
            n.update_attribute(:login, o.UserName)
            l+=1
          end
          if n.email != o.Email
            p "changing email from #{n.email} to #{o.Email}"
            n.update_attribute(:email, o.Email)
            e+=1
          end
          if n.created_at.to_date != o.CreatedOn.to_date
            p "changing created_at from #{n.created_at} to #{o.CreatedOn}"
            n.update_attribute(:created_at, o.CreatedOn)
            c+=1
          end
          if n.updated_at.to_date != o.LastUpdated.to_date
            p "changing updated_at from #{n.updated_at} to #{o.LastUpdated}"
            n.update_attribute(:updated_at, o.LastUpdated)
            u+=1
          end
          if n.is_a? DuplicateV2User
            if n.password != o.Password
              p "changing password for duplicate user from #{n.password} to #{o.Password}"
              n.update_attribute(:password, o.Password)
              p+=1
            end
          else #assume User
            if n.crypted_password != o.Password
              p "changing password for user from #{n.crypted_password} to #{o.Password}"
              n.update_attribute(:crypted_password, o.Password)
              p+=1
            end
          end
        end
        count+=1
        p "processed batch #{count} of 1000 records: \n
          #{l} logins, #{e} emails, #{p} passwords, #{c} created_at, and #{u} updated_at synced"
      end
    end
  end

  class Certificate < OldSite::Base
    set_table_name 'Certificate'
    set_primary_key 'CertificateID'
    belongs_to  :order, :class_name=>'OldSite::Order', :foreign_key=>'OrderID'
    belongs_to  :certificate_product, :class_name=>
      'OldSite::CertificateProduct', :foreign_key=>'CertificateProductID'
    belongs_to  :merchant, :class_name=>'OldSite::Merchant',
      :foreign_key=>'MerchantID'
    has_one     :product, :through=>:certificate_product
    alias_attribute :unsigned_cert, :UnsignedCert

    HAS_SIGNED_BUT_NO_CSR=[13778, 17295]

    default_scope{ where(:CertificateID - HAS_SIGNED_BUT_NO_CSR)}

    def migrate(co)
      co.certificate_contents.create.tap do |cc|
        cc.created_at=self.SubmitDate
        cc.server_software=OldSite::ServerType.server_software(
          self.ServerType)
        unless self.UnsignedCert.blank?
          cc.signing_request=self.UnsignedCert
          unless (self.SignedCert.blank? || cc.csr.blank?)
            cc.csr.update_attribute(:created_at, self.SubmitDate)
            cc.csr.signed_certificate_by_text=self.SignedCert
            if cc.csr.signed_certificate
              cc.csr.signed_certificate.update_attribute(:created_at,
                self.ReadyNoticeSentToCustomer)
              cc.workflow_state='issued'
            else
              cc.workflow_state='csr_submitted'
              logger.error "Error: Could not import signed certificate
                from Old::Certificate#{self.CertificateID}"
            end
          else
            cc.workflow_state='csr_submitted'
          end
          cc.save
        else
          logger.error "Error! could not find csr for #{self.model_and_id}"
        end
      end
    end

    def migrate_cert_and_merchants(co)
      cc=record_migration_progress(co) if V2MigrationProgress.
        find_by_source(self).try(:migrated_at).blank?
      if cc && !cc.new_record? && merchant
        merchant.record_migration_progress(cc) if V2MigrationProgress.
          find_by_source(merchant).try(:migrated_at).blank?
        merchant.merchant_contacts.each do |mc|
          mc.record_migration_progress(cc) if V2MigrationProgress.
            find_by_source(mc).try(:migrated_at).blank?
        end
      end
      #36 certificates with unsignedcerts have no merchant
    end

    # these signed certificates have not been migrated to v2
    def self.unmigrated_signed_certificates
      ncm=::SignedCertificate.select(:common_name).map(&:common_name).uniq
      ocm=select(:CommonName).map(&:CommonName).uniq
      diff=ocm-ncm
      where(:CommonName + diff.compact.reject{|b|b==""})
    end

    def self.signed_certs_to_be_created
      um=OldSite::Certificate.unmigrated_signed_certificates
      umm=um.map{|u|V2MigrationProgress.find_by_source(u)}
      nc=umm.map(&:migratable)
      csrs=nc.csrs
      csr_ids=csrs.compact.map(&:id)
      bsc=SignedCertificate.where(:csr_id + csr_ids)
      existing=bsc.map(&:csr_id)
      csrs_without_signed_cert=csr_ids-existing
      ap bsc.map(&:common_name)
    end

    def self.sync_certs
      count=0
      t_cc, t_cs, t_rc, t_csc, t_rsc = 0,[],[],[],[]
      failed_cs, failed_rc, failed_csc, failed_rsc=[],[],[],[]
      select([:CertificateID, :SubmitDate, :UnsignedCert, :CommonName,
              :SignedCert, :ReadyNoticeSentToCustomer]).find_in_batches do |certs|
        cc, cs, rc, csc, rsc = 0,[],[],[],[]
        process_signed_cert=lambda do |n, o, counter, failed|
          csr=n.csr
          sc=csr.send "signed_certificate_by_text=", o.SignedCert
          unless sc.blank? || sc.new_record?
            p "successfully created #{sc.model_and_id} (#{sc.common_name})"
            sc.update_attribute(:created_at, o.ReadyNoticeSentToCustomer)
            n.workflow_state='issued'
            counter<<sc.id
          else
            p "failed creating signed_certificate for #{csr.model_and_id} (#{csr.common_name})"
            failed << csr.id
          end
        end
        process_csr=lambda do |n, o, counter, failed|
          n.reload.signing_request=o.UnsignedCert
          csr=n.csr(true)
          unless csr.blank? || csr.new_record?
            p "successfully created #{csr.model_and_id} (#{csr.common_name})"
            csr.update_attribute(:created_at, o.SubmitDate)
            n.workflow_state='csr_submitted'
            counter<<csr.id
            if !o.SignedCert.blank?
              if !csr.blank? && csr.signed_certificates.empty?
                # need to create a signed_certificate
                p "creating a signed_certificate for #{o.model_and_id}"
                process_signed_cert.(n,o,csc,failed_csc)
              elsif csr.signed_certificates.last.common_name.try(:downcase)!=o.CommonName.try(:downcase)
                p "recreating #{csr.signed_certificates.last.model_and_id} for #{o.model_and_id}"
                csr.signed_certificates.destroy_all
                process_signed_cert.(n,o,rsc,failed_rsc)
              end
            end
          else
            p "failed creating csr for #{n.model_and_id}"
            failed << n.id
          end
          n.save
        end
        V2MigrationProgress.includes(:migratable).
            where({:source_table_name=>"Certificate"} & :source_id + certs.map(&:CertificateID)).each do |v|
          o=certs.find{|c|c.CertificateID==v.source_id}
          n=v.migratable
          # verify a corresponding csr
          if n.blank?
            #need to refer to Order, maybe call OldSite::Order.migrate
            p "certificate_content for #{o.model_and_id} doesn't exist, maybe had data integrity issues?"
            cc+=1
          else
            if !o.UnsignedCert.blank?
              if n.csr.blank?
                # need to create a csr
                p "creating a csr for #{n.model_and_id}"
                process_csr.(n,o,cs,failed_cs)
              elsif n.csr.common_name.try(:downcase)!=o.CommonName.try(:downcase)
                p "recreating #{n.csr.model_and_id} for #{o.model_and_id}"
                n.csr.destroy
                process_csr.(n,o,rc,failed_rc)
              elsif !o.SignedCert.blank?
                if n.csr.signed_certificates.empty?
                  # need to create a signed_certificate
                  p "creating a signed_certificate for #{o.model_and_id}"
                  process_signed_cert.(n,o,csc,failed_csc)
                elsif n.csr.signed_certificates.last.common_name.try(:downcase)!=o.CommonName.try(:downcase)
                  p "recreating #{n.csr.signed_certificates.last.model_and_id} for #{o.model_and_id}"
                  n.csr.signed_certificates.destroy_all
                  process_signed_cert.(n,o,rsc,failed_rsc)
                end
              end
            end
          end
        end
        count+=1
        t_cc, t_cs, t_rc, t_csc, t_rsc = t_cc+cc, t_cs+cs, t_rc+rc, t_csc+csc, t_rsc+rsc
        p "processed batch #{count} of 1000 records: \n
          #{cc} certificate_contents missing, #{cs.count} csrs created, #{rc.count} csrs recreated, #{csc.count} signed_certificates created,
          #{rsc.count} signed_certificates recreated"
        p "created csrs: #{cs.to_s}"
        p "recreated csrs: #{rc.to_s}"
        p "created signed_certificates: #{csc.to_s}"
        p "recreated signed_certificates: #{rsc.to_s}"
        p "failed creating csr for certificate_contents: #{failed_cs.to_s}"
        p "failed recreating csr for certificate_contents: #{failed_rc.to_s}"
        p "failed creating signed_certificates for csrs: #{failed_csc.to_s}"
        p "failed recreating signed_certificates for csrs: #{failed_rsc.to_s}"
      end
      p "total: #{t_cc} certificate_contents missing, #{t_cs.count} csrs created, #{t_rc.count} csrs recreated,
        #{t_csc.count} signed_certificates created, #{t_rsc.count} signed_certificates recreated"
      p "failed creating csr for certificate_contents: #{failed_cs.to_s}"
      p "failed recreating csr for certificate_contents: #{failed_rc.to_s}"
      p "failed creating signed_certificates for csrs: #{failed_csc.to_s}"
      p "failed recreating signed_certificates for csrs: #{failed_rsc.to_s}"
    end

    #somehow a few purchased credits appeared that do not belong a corresponding v2_migration_source
    #we need to remove these to avoid paying for non existing credit on the old system
    def self.orphaned_credits
      CertificateOrder.unused_purchased_credits.
        select{|co|co.certificate_content.v2_migration_sources.blank?}.
        select{|b|b.ssl_account.primary_user.v2_migration_sources}
    end

    def self.unmigrated_old_certificates
      ids=V2MigrationProgress.includes(:migratable).
          where({:source_table_name=>"Certificate"}).select do |v|
        v.migratable.blank?
      end.map(&:source_id)
      where(:CertificateID + ids)
    end

    def self.unmigrated_old_certificate_ids
      ids=V2MigrationProgress.includes(:migratable).
          where({:source_table_name=>"Certificate"}).select do |v|
        v.migratable.blank?
      end.map(&:source_id)
      select(:CertificateID).where(:CertificateID + ids).map(&:CertificateID)
    end
  end

  class Order < OldSite::Base
    set_table_name 'Orders'
    set_primary_key 'OrderNumber'
    belongs_to :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
    belongs_to :order_number, :class_name=>'OldSite::OrderNumber',
      :foreign_key=>'OrderNumber'
    has_many :certificates, :class_name=>'OldSite::Certificate',
      :foreign_key=>'OrderID'

    def user
      V2MigrationProgress.find_by_old_object(customer).migratable unless
        customer.blank?
    end

    def sa
      user.instance_of?(User) ? user.ssl_account : user.user.ssl_account
    end

    def copy_payment_method_to(o)
      case self.PaymentMethod
      when /Request Quote/
        o.state="quote"
        o.quote_number=self.quoted_id
      when /Check/, /Purchase Order/, /Credit Card/
        o.state="paid"
        o.po_number=self.PONumber if $&=="Purchase Order"
      end
    end

    def migrate
      unless user.blank?
        #create order
        msg="Creating Order for #{user.model_and_id} (#{sa.model_and_id})"
        logger.error msg
        ap msg
        ::Order.create(:created_at=>self.OrderDate).tap do |o|
          o.billable=sa
          o.preferred_migrated_from_v2 = true
          o.cents=(self.OrderTotal*100).to_i
          o.currency="USD"
          self.copy_payment_method_to(o)
          #create order transaction
          ot=o.transactions.create(:created_at=>self.OrderDate)
          ot.amount=o.cents
          ot.success=true
          ot.message=self.AuthorizationResult
          ot.action="purchase"
          unless ot.save
            msg="Error! Could not save transaction #{ot.model_and_id} to #{o.model_and_id}"
            logger.error msg
            ap msg
          else
            msg="Saved transaction #{ot.model_and_id} to #{o.model_and_id}"
            logger.error msg
            ap msg
          end
          unless sa.orders<<o
            msg="Error! Could not save order #{o.model_and_id} to #{sa.model_and_id}"
            logger.error msg
            ap msg
          else
            msg="Saved order #{o.model_and_id} to #{sa.model_and_id}"
            logger.error msg
            ap msg
          end
        end
      else
        msg="Skipping create Order for #{sa.model_and_id} since no user is found"
        logger.error msg
        ap msg
      end
    end

    def migrate_orders_shopping_cart
      order = V2MigrationProgress.find_by_old_object(self).migratable
      unless order.blank?
        ap "migrating legacy OrdersShoppingCart for Order.OrderNumber: #{self.OrderNumber}"
        certs_created=false
        order_number.orders_shopping_carts.each do |osc|
          unless osc.migratable_exists?
            ap "migrating #{osc.model_and_id}"
            osc.record_migration_progress(:new_order=>order,
              :certs_created=>certs_created)
            certs_created=true
          else
            ap "skipping #{osc.model_and_id}, already exists"
          end
        end
      else
        msg = "Error! V2MigrationProgress#migratable for #{self.class.to_s}: #{self.id} not found"
        logger.error msg
        ap msg
      end
    end

    def self.migrate_all
      migrate_these = unmigrated_records
      i=migrate_these[1]
      ap "migrating #{i.to_s} #{table_name} records"
      migrate_these[0].find_each(:include=>[{:order_number=>[:certificates,
          {:orders_shopping_carts=>:orders_kit_carts}]}, :customer]) do |o|
        OldSite.detect_abort
        i-=1
        unless o.migratable_exists?
          #o.customer.blank? doesn't seem to use the default_scope{ of OldSite::Customer'}
          if OldSite::Customer.exists? o.CustomerID
            ap "migrating #{o.model_and_id}"
            o.record_migration_progress
          else
            ap "skipping migration for #{o.model_and_id} because Customer not found or invalid"
            ap "#{i} #{table_name} records remaining for migration"
            next
          end
        else
          ap "found and skipping migration for: #{o.model_and_id}"
        end
        o.migrate_orders_shopping_cart
        ap "#{i} #{table_name} records remaining for migration"
      end
      V2MigrationProgress.status(self)
    end

    def self.extra_unpaid_certificate_orders
      ::Order.with_too_many_line_items.map(&:line_items).
          flatten.uniq.map(&:sellable).uniq.map(&:certificate_contents).
          flatten.uniq.select{|cc|cc.v2_migration_sources.blank?}
    end

    def map_card_type
      case self.CardType
        when "", nil
          ""
        when "MasterCard"
          "Master Card"
        when "AMEX"
          "American Express"
        when "DISCOVER"
          "Discover"
        when "VISA"
          "Visa"
      end
    end

    #resuming migration that has been tested
    def self.migrate_billing_profiles
      ::BillingProfile.password = "kama1jama1"
      #find migrated orders that do not have a billing profile
      oids=V2MigrationProgress.select("migratable_id").
          where(:source_table_name >> "Orders", :migratable_type >> "Order").map(&:migratable_id)
      queue = ::Order.select("id").where(:id + oids, :billing_profile_id >> nil,
                                       :quote_number >> nil, :po_number >> nil)
      queue_ids = queue.map(&:id)
      v2=V2MigrationProgress.select("source_id, migratable_id").where(:source_table_name >> "Orders",
        :migratable_type >> "Order", :migratable_id + queue_ids)
      old_ids=v2.map(&:source_id)
      select("OrderNumber, BillingLastName, BillingFirstName, BillingCompany, BillingAddress1, BillingAddress2,
              BillingSuite, BillingCity, BillingState, BillingZip, BillingCountry, BillingPhone,
              CardType,CardName,CardNumber,CardExtraCode,CardExpirationMonth,CardExpirationYear").
          where(:OrderNumber + old_ids, :CardExpirationYear !~ "").order("OrderDate desc").each do |o|
        #OldSite.detect_abort
        cc_num=o.cc_num
        newer=::Order.find_by_id(v2.find_by_source_id(o.OrderNumber).migratable_id)
        unless cc_num.blank? || newer.billable.blank? || !newer.billing_profile.blank?
          p "new==#{newer.id}, older==#{o.id}"
          cvv=o.CardExtraCode.blank? ?
              (ot=select("TransactionCommand").where(:OrderNumber >> o.OrderNumber).last
              cvv_t=ot.cvv_code
              cvv_t.blank? ? "na" : cvv_t) : o.CardExtraCode
          attrs={
          :ssl_account_id => newer.billable_id,
              :description => o.CardName,
               :first_name => o.BillingFirstName,
                :last_name => o.BillingLastName,
                :address_1 => [o.BillingAddress1,o.BillingSuite].join(", "),
                :address_2 => o.BillingAddress2,
                  :country => o.BillingCountry,
                     :city => o.BillingCity,
                    :state => o.BillingState,
              :postal_code => o.BillingZip.blank? ? "n/a" : o.BillingZip,
                    :phone => o.BillingPhone,
                  :company => o.BillingCompany,
              :credit_card => o.map_card_type,
              :card_number => cc_num,
          :expiration_month => o.CardExpirationMonth,
          :expiration_year => o.CardExpirationYear,
            :security_code => cvv
          }
          Order.transaction do
            p "migrating old Order billing profile #{o.OrderNumber}"
            bp = BillingProfile.find_by_card_number_and_expiration_year(cc_num, o.CardExpirationYear.to_i) ||
                BillingProfile.create(attrs)
            if bp.valid?
              p "billing_profile.id == "+bp.id.to_s
              newer.billing_profile=bp
              newer.save
            else
              p bp.errors
            end
          end
        else
          p "skipping old Order billing profile #{o.OrderNumber}"
        end
      end
    end

    #the only PaymentMethods are "Purchase Order", "Credit Card", "Request Quote", "", and "Check"
    #cc_num only applies to "Credit Card"
    def cc_num
      plain_key="8773732869"
      message = Base64.decode64 self.CardNumber
      sha = Digest::SHA1.digest plain_key
      key = sha[0..7]
      iv = sha[8..15]

      cipher = OpenSSL::Cipher::DES.new
      cipher.decrypt # Call this before setting key or iv
      cipher.key = key
      cipher.iv = iv
      ciphertext = cipher.update(message)
      ciphertext << cipher.final

      length=ciphertext[0..4].to_i
      cc_number=ciphertext[5,length]
    rescue
      ""
    end

    def cvv_code
      self.TransactionCommand=~/x_card_code=(.+?)&/
      $1
    end

  end

  class OrdersShoppingCart < Base
    set_table_name 'Orders_ShoppingCart'
    set_primary_key 'Orders_ShoppingCartID'
#    belongs_to  :shopping_cart, :class_name=>'OldSite::ShoppingCart',
#      :foreign_key=>'ShoppingCartRecID'
    has_many    :orders_kit_carts, :class_name=>'OldSite::OrdersKitCart',
      :foreign_key=>'ShoppingCartRecID', :primary_key=>'ShoppingCartRecID'
    belongs_to  :order_number, :class_name=>'OldSite::OrderNumber',
      :foreign_key=>'OrderNumber'
    has_one     :order, :through=>:order_number
    belongs_to  :product, :class_name=>'OldSite::Product',
      :foreign_key=>'ProductID'
    belongs_to  :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
    belongs_to  :product_variant, :class_name=>'OldSite::ProductVariant',
      :foreign_key=>'VariantID'

    def certificates
      order_number.certificates #.select{|c|c.product==product}
    end

    def order
      order_number.order
    end

    def migrate(options)
      new_order = options[:new_order]
      new_order.description=[new_order.description,
        self.OrderedProductDescription].join(': ')
      unless options[:certs_created]
        self.certificates.count.times do |i|
          co=CertificateOrder.new(:created_at=>self.order.OrderDate)
          co.sub_order_items << SubOrderItem.create(:product_variant_item=>
              ProductVariantItem.find_by_serial('mssl'))
          co.amount=(self.OrderedProductPrice*100).to_i/self.Quantity
          co.preferred_payment_order='prepaid' if self.certificates[i].blank? ||
            self.certificates[i].UnsignedCert.blank?
          co.preferred_v2_product_description = product.Name
          #co.pay! true
          co.workflow_state='paid'
          co.ssl_account=order.sa
          items=orders_kit_carts.each_with_object([]) do |okc, arry|
            arry << okc.KitItemName
          end
          co.v2_line_items=items unless items.empty?
          co.line_item_qty=1
          if co.save
            ap "new ::CertificateOrder saved #{co.model_and_id}"
          else
            ap "failed save operation of ::CertificateOrder for #{new_order.model_and_id}"
          end
          li=new_order.line_items.create
          li.cents=(self.OrderedProductPrice*100).to_i
          li.sellable=co
          if li.save
            ap "new ::LineItem saved #{li.model_and_id}"
          else
            ap "failed save operation of ::LineItem for #{new_order.model_and_id}"
          end
          #saving processed certs for paid only orders
          unless self.certificates[i].blank?
            if co.valid?
              self.certificates[i].migrate_cert_and_merchants(co)
            else
              msg="CertificateOrder is not valid for #{co}.
                CertificateContents not created"
              logger.error msg
              ap msg
            end
          end
        end
      end
      new_order
    end
  end

  class Company < Base
    set_table_name 'Company'
    set_primary_key 'CompanyID'
    has_many :customers, :class_name=>'OldSite::Customer',
      :foreign_key=>'CompanyID'
  end

  class Merchant < Base
    set_table_name 'Merchant'
    set_primary_key 'MerchantID'
    belongs_to  :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
    has_one     :certificate, :class_name=>'OldSite::Certificate',
      :foreign_key=>'MerchantID'
    has_many    :merchant_contacts, :class_name=>'OldSite::MerchantContact',
      :foreign_key=>'MerchantID'
    
    ATTR_MAP={        
      company_name: :MerchantName,
      department: :MerchantDept,
      address1: :MerchantStreet1,
      address2: :MerchantStreet2,
      city: :MerchantCity,
      state: :MerchantState,
      country: :MerchantCountry,
      postal_code: :MerchantPostalCode
    }

    def migrate(cc)
      self.copy_attributes_to(cc.create_registrant).tap do |r|
        if r.save && cc.workflow_state!='issued'
          cc.update_attribute :workflow_state, 'info_provided'
        end
      end
    end

    def copy_attributes_to(registrant)
      registrant.tap do |r|
        copy_attributes(r)
      end
    end
  end

  class MerchantContact < Base
    set_table_name 'MerchantContacts'
    set_primary_key 'MerchantContactID'
    belongs_to  :merchant, :class_name=>'OldSite::Merchant',
      :foreign_key=>'MerchantID'
    belongs_to  :contact_type, :class_name=>'OldSite::ContactType',
      :foreign_key=>'ContactType'
      
    ATTR_MAP={title: :MCTitle,
      first_name: :MCFirstName,
      last_name: :MCLastName,
      company_name: :MCCompanyName,
      department: :MCDepartment,
      address1: :MCStreet1,
      address2: :MCStreet2,
      city: :MCCity,
      state: :MCState,
      country: :MCCountry,
      postal_code: :MCPostalCode,
      email: :MCEmailAddress,
      phone: :MCPhoneNumber,
      ext: :MCExtension,
      fax: :MCFaxNumber,
      notes: :MCNotes}
    
    def self.convert_country(old_country)
      country=Country.find_by_iso3_code(old_country) ||
        Country.find_by_iso1_code(old_country) ||
        Country.find_by_name_caps(old_country.upcase)
      country.blank? ? nil : country.iso1_code
    end

    def migrate(cc)
      unless self.MerchantID==0
        cc.certificate_contacts.build.tap do |c_contact|
          self.copy_attributes_to c_contact
          if c_contact.save
            cc.update_attribute :workflow_state, 'contacts_provided' unless
              cc.workflow_state=='issued'
          end
        end
      end
    end

    def copy_attributes_to(certificate_contact)
      certificate_contact.tap do |cc|
        type=self.contact_type.ContactTypeDesc.downcase
        cc.roles = type=='business' ? %w(validation) : [type]
        copy_attributes(cc)
      end
    end
  end

  class ServerType < Base
    set_table_name 'ServerType'
    set_primary_key 'ServerTypeID'
    @@st = OldSite::ServerType.all

    #new-old array
    MAPPING=[[*(1..5)], [*(1..5)]].transpose + [[8,6], [9,7]] +
      [[*(12..19)], [*(8..15)]].transpose + [[*(21..24)],
      [*(16..19)]].transpose + [[*(26..34)], [*(20..28)]].transpose +
      [[36,29]]

    def self.server_software(id)
      server_software_by_id(id) || server_software_by_desc(id) ||
        server_software_by_code(id) || server_software_by_code('OTH')
    end

    def self.server_software_by_id(id)
      st=@@st.find{|ss|ss.ServerTypeID==id.to_i}
      ServerSoftware.find(MAPPING.find{|m|m[1]==st.ServerTypeID}[0]) if st
    end

    def self.server_software_by_desc(desc)
      st=@@st.find{|ss|ss.ServerTypeDesc==desc}
      ServerSoftware.find(MAPPING.find{|m|m[1]==st.ServerTypeID}[0]) if st
    end

    def self.server_software_by_code(code)
      st=@@st.find{|ss|ss.ServerTypeSymbol==code}
      ServerSoftware.find(MAPPING.find{|m|m[1]==st.ServerTypeID}[0]) if st
    end

  end

  class ContactType < Base
    set_table_name 'ContactType'
    set_primary_key 'ContactTypeID'
    has_many    :merchant_contacts, :class_name=>'OldSite::MerchantContact',
      :foreign_key=>'ContactType'
  end

  class Product < Base
    set_table_name 'Product'
    set_primary_key 'ProductID'
    belongs_to  :manufacturer, :class_name=>'OldSite::Manufacturer',
      :foreign_key=>'ManufacturerID'
    has_one     :certificate_product, :class_name=>
      'OldSite::CertificateProduct', :foreign_key=>'ProductID'
    has_many    :kit_carts, :class_name=>'OldSite::KitCart',
      :foreign_key=>'CustomerID'
    has_many    :product_variants, :class_name=>
      'OldSite::ProductVariant', :foreign_key=>'ProductID'
    has_many  :kit_groups, :class_name=>'OldSite::KitGroup',
      :foreign_key=>'ProductID'
  end

  class ProductVariant < Base
    set_table_name 'ProductVariant'
    set_primary_key 'VariantID'
    belongs_to :product, :class_name=>'OldSite::Product',
      :foreign_key=>'ProductID'
    has_one     :certificate_product, :class_name=>
      'OldSite::CertificateProduct', :foreign_key=>'ProductID'
    has_many    :orders_kit_carts, :class_name=>'OldSite::OrdersKitCart',
      :foreign_key=>'VariantID'
  end

  class CertificateProduct < Base
    set_table_name 'CertificateProduct'
    set_primary_key 'CPID'
    belongs_to :product, :class_name=>'OldSite::Product',
      :foreign_key=>'ProductID'
    has_many :certificates, :class_name=>'OldSite::Certificate',
      :foreign_key=>'CertificateProductID'
  end

  class Manufacturer < Base
    set_table_name 'Manufacturer'
    set_primary_key 'ManufacturerID'
    has_many :products, :class_name=>'OldSite::Product',
      :foreign_key=>'ManufacturerID'
  end

  class OrderNumber < Base
    set_table_name 'OrderNumbers'
    set_primary_key 'OrderNumber'
    has_many      :orders_shopping_carts, :class_name=>
      'OldSite::OrdersShoppingCart', :foreign_key=>'OrderNumber'
    has_one       :order, :class_name=>
      'OldSite::Order', :foreign_key=>'OrderNumber'
    has_many      :certificates, :through=>:order
    has_many      :orders_kit_carts, :class_name=>'OldSite::OrdersKitCart',
      :foreign_key=>'OrderNumber'
    has_many      :kit_carts, :through=>:orders_kit_carts,
      :class_name=>'OldSite::KitCart', :foreign_key=>'KitCartRecID'

  end

  #basically a lineitem
  class OrdersKitCart < Base
    set_table_name 'Orders_KitCart'
    set_primary_key 'OrderNumber, KitCartRecID'
#    belongs_to :shopping_cart, :class_name=>'OldSite::ShoppingCart',
#      :foreign_key=>'ShoppingCartRecID'
    belongs_to  :orders_shopping_cart, :class_name=>
      'OldSite::OrdersShoppingCart', :foreign_key=>'ShoppingCartRecID',
      :primary_key=>'ShoppingCartRecID'
    belongs_to :kit_cart, :class_name=>'OldSite::KitCart',
      :foreign_key=>'KitCartRecID'
    belongs_to :order_number, :class_name=>'OldSite::OrderNumber',
      :foreign_key=>'OrderNumber'
    belongs_to :product, :class_name=>'OldSite::Product',
      :foreign_key=>'ProductID'
    belongs_to :product_variant, :class_name=>'OldSite::ProductVariant',
      :foreign_key=>'VariantID'
    belongs_to :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
    belongs_to    :kit_item, :class_name=>'OldSite::KitItem',
      :foreign_key=>'KitItemID'
    belongs_to    :kit_group, :class_name=>'OldSite::KitGroup',
      :foreign_key=>'KitGroupID'
  end

  class KitItem < Base
    set_table_name 'KitItem'
    set_primary_key 'KitItemID'
    belongs_to :kit_group, :class_name=>'OldSite::KitGroup',
      :foreign_key=>'KitGroupID'
  end

  class KitGroup < Base
    set_table_name 'KitGroup'
    set_primary_key 'KitGroupID'
    belongs_to  :product, :class_name=>'OldSite::Product',
      :foreign_key=>'ProductID'
    belongs_to  :kit_group_type, :class_name=>'OldSite::KitGroupType',
      :foreign_key=>'KitGroupTypeID'
    has_many    :kit_items, :class_name=>'OldSite::KitItem',
      :foreign_key=>'KitGroupID'
  end

  class KitGroupType < Base
    set_table_name 'KitGroupType'
    set_primary_key 'KitGroupTypeID'
    has_many  :kit_groups, :class_name=>'OldSite::KitGroup',
      :foreign_key=>'KitGroupTypeID'
  end

  class ShoppingCart < Base
    set_table_name 'ShoppingCart'
    set_primary_key 'ShoppingCartRecID'
    has_one     :orders_shopping_cart, :class_name=>
      'OldSite::OrdersShoppingCart', :foreign_key=>'ShoppingCartRecID'
    has_many    :kit_carts, :class_name=>'OldSite::KitCart',
      :foreign_key=>'ShoppingCartRecID'
    belongs_to  :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
  end

  #basically a lineitem
  class KitCart < Base
    set_table_name 'KitCart'
    set_primary_key 'KitCartRecID'
    belongs_to  :customer, :class_name=>'OldSite::Customer',
      :foreign_key=>'CustomerID'
    belongs_to  :shopping_cart, :class_name=>'OldSite::ShoppingCart',
      :foreign_key=>'ShoppingCartRecID'
    has_many      :orders_kit_carts, :class_name=>'OldSite::OrdersKitCart',
      :foreign_key=>'KitCartRecID'
    has_many      :order_numbers, :through=>:orders_kit_carts

    def to_param
      KitCartRecID
    end
  end
end if Rails.env=='development' && MIGRATING_FROM_LEGACY


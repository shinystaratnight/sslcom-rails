if Rails.env=='development'
  module OldSite

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
            :source_id=>o.send(tc.primary_key))
          end
        end
      end
    end

    def self.dynamic_initialize
      tables=%w(Customer Order Certificate OrderNumber Merchant MerchantContact
        OrdersShoppingCart)
      tables.each do |t|
        tc = ('OldSite::'+t).constantize
        source_tables=V2MigrationProgress.all.select {|p|
          p.source_table_name==tc.table_name} || []
        #if the number of records on the source table has change, then add the new
        #records
        unless tc.count==source_tables.count
          tc.find_each do |o|
          V2MigrationProgress.create(:source_table_name=>tc.table_name,
            :source_id=>o.send(tc.primary_key)) unless source_tables.find{|st|
              st.source_id==o.send(tc.primary_key)}
          end
        end
      end
    end

    def self.migrate_all
      Authorization.ignore_access_control(true)
      ActiveRecord::Base.logger.level = 3 # at any time
#      dynamic_initialize
#      Customer.migrate_all
#      Order.migrate_all
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
          logger.error 'Certficate products mismatch for order: '+o.OrderNumber
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

    class Base < ActiveRecord::Base
      establish_connection :ssl_store_mssql
      self.abstract_class=true

      def record_migration_progress(p=nil)
        mp = V2MigrationProgress.find_by_old_object(self)
        if mp.migrated_at.blank?
          migratable=p ? migrate(p) : migrate
          mp.update_attributes :migrated_at=>Time.new,
            :migratable=>(migratable)
          migratable
        else
          logger.error "Error!: Already migrated #{self}"
          mp.migratable
        end
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
      attr_accessor_with_default :status, 'enabled'

      def migrate
        lu = LegacyV2UserMapping.create(:old_user_id=>self.id)
        u = User.find_by_login(self.login) || User.find_by_email(self.email)
        if u
          du=DuplicateV2User.create(:user=>u, :login=>self.login,
            :email=>self.email, :password=>self.crypted_password, :created_at=>
            self.created_at, :updated_at=>self.updated_at)
          du.legacy_v2_user_mappings << lu
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
          u.save
        end
        u || du
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
        self.find_each do |c|
          c.record_migration_progress if V2MigrationProgress.find_by_source(c).
            try(:migrated_at).blank?
        end
        migrated = V2MigrationProgress.all.select{|mp|
          mp.source_table_name==self.table_name && !mp.migrated_at.blank?}
        p migrated.blank? ? "successfully migrated all Customers" :
          "the following #{migrated.count} Customers failed migration:
          #{migrated.map{|m|m.send(m.class.primary_key)}.join(', ')}"
      end

      def self.duplicate_emails
        all(:group=>'Email', :select=>'Email', :having=>'count(Email)>1')
      end

      def self.duplicate_logins
        all(:group=>'UserName', :select=>'UserName',
          :having=>'count(UserName)>1')
      end

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

      def self.unmigrate_all
        Authorization.ignore_access_control(true)
        OldSite::Customer.all.each {|c|
          if User.exists?(c.id)
            u=User.find(c.id)
            u.ssl_account.destroy
          end}
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

      def migrate(co)
        returning co.certificate_contents.create do |cc|
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
            logger.error "Error! could not find csr for #{self.CertificateID}"
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
          returning ::Order.create(:created_at=>self.OrderDate) do |o|
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
            logger.error "Error! Could not save order #{o}" unless sa.orders<<o
          end
        end
      end

      def migrate_orders_shopping_cart
        order = V2MigrationProgress.find_by_old_object(self).migratable
        unless order.blank?
          certs_created=false
          order_number.orders_shopping_carts.each do |osc|
            if V2MigrationProgress.find_by_source(osc).
                try(:migrated_at).blank?
              osc.record_migration_progress(:new_order=>order,
                :certs_created=>certs_created)
              certs_created=true
            end
          end
        else
          logger.error "Error! V2MigrationProgress for #{self} not found"
        end
      end

      def self.migrate_all
        self.find_each(:include=>{:order_number=>[:certificates,
            {:orders_shopping_carts=>:orders_kit_carts}]}) do |o|
          o.record_migration_progress if
            V2MigrationProgress.find_by_source(o).try(:migrated_at).blank?
          o.migrate_orders_shopping_cart
        end
        migrated = V2MigrationProgress.all.select{|mp|
          mp.source_table_name==self.table_name && !mp.migrated_at.blank?}
        p migrated.empty? ? "successfully migrated all Orders" :
          "the following #{migrated.count} Orders failed migration:
          #{migrated.map{|m|m.send(m.class.primary_key)}.join(', ')}"
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
            co.save
            li=new_order.line_items.create
            li.cents=(self.OrderedProductPrice*100).to_i
            li.sellable=co
            li.save
            #saving processed certs for paid only orders
            unless self.certificates[i].blank?
              if co.valid?
                self.certificates[i].migrate_cert_and_merchants(co)
              else
                logger.error "CertificateOrder is not valid for #{co}.
                  CertificateContents not created"
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

      def migrate(cc)
        returning self.copy_attributes_to(cc.create_registrant) do |r|
          if r.save && cc.workflow_state!='issued'
            cc.update_attribute :workflow_state, 'info_provided'
          end
        end
      end

      def copy_attributes_to(registrant)
        returning registrant do |r|
          r.company_name=self.MerchantName
          r.department=self.MerchantDept
          r.address1=self.MerchantStreet1
          r.address2=self.MerchantStreet2
          r.city=self.MerchantCity
          r.state=self.MerchantState
          country=Country.find_by_iso3_code(self.MerchantCountry) ||
            Country.find_by_iso1_code(self.MerchantCountry) ||
            Country.find_by_name_caps(self.MerchantCountry.upcase)
          r.country=country.blank? ? nil : country.iso1_code
          r.postal_code=self.MerchantPostalCode
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

      def migrate(cc)
        unless self.MerchantID==0
          returning cc.certificate_contacts.build do |c_contact|
            self.copy_attributes_to c_contact
            if c_contact.save
              cc.update_attribute :workflow_state, 'contacts_provided' unless
                cc.workflow_state=='issued'
            end
          end
        end
      end

      def copy_attributes_to(certificate_contact)
        returning certificate_contact do |cc|
          type=self.contact_type.ContactTypeDesc.downcase
          cc.roles = type=='business' ? %w(validation) : [type]
          cc.title=self.MCTitle
          cc.first_name=self.MCFirstName
          cc.last_name=self.MCLastName
          cc.company_name=self.MCCompanyName
          cc.department=self.MCDepartment
          cc.address1=self.MCStreet1
          cc.address2=self.MCStreet2
          cc.city=self.MCCity
          cc.state=self.MCState
          country=Country.find_by_iso3_code(self.MCCountry) ||
            Country.find_by_iso1_code(self.MCCountry) ||
            Country.find_by_name_caps(self.MCCountry.upcase)
          cc.country=country.blank? ? nil : country.iso1_code
          cc.postal_code=self.MCPostalCode
          cc.email=self.MCEmailAddress
          cc.phone=self.MCPhoneNumber
          cc.ext=self.MCExtension
          cc.fax=self.MCFaxNumber
          cc.notes=self.MCNotes
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

  end
end
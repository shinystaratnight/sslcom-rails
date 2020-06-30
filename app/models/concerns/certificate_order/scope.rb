module Concerns
  module CertificateOrder
    module Scope
      extend ActiveSupport::Concern
      include Concerns::CertificateOrder::Constants

      included do
        default_scope{ where{ (workflow_state << %w[canceled refunded charged_back]) & (is_expired != true) }.order(created_at: :desc)}

        scope :with_counts, lambda {
          select <<~SQL
            certificate_orders.*,
            (
              SELECT COUNT(certificate_contents.id) FROM certificate_contents
              WHERE certificate_order_id = certificate_orders.id
            ) AS certificate_contents_count
          SQL
        }

        scope :not_test, ->{ where(is_test: [nil, false]) }
        scope :is_test, ->{ where(is_test: true) }
        scope :search, ->(term, options = {}) { where{ ref =~ '%' + term + '%' }.merge(options) }
        scope :with_includes, -> { includes(%i[ssl_account orders validation site_seal]) }
        scope :search_physical_tokens, ->(state = 'new') { joins{ physical_tokens }.where{ physical_tokens.workflow_state >> [state.split(',')] } if state.present? }
        scope :search_signed_certificates, lambda { |term|
          joins{ certificate_contents.csr.signed_certificates }
            .where{ certificate_contents.csr.signed_certificates.common_name =~ "%#{term}%" }
        }
        scope :search_csr, lambda { |term|
          joins{ certificate_contents.csr }.where{ certificate_contents.csr.common_name =~ "%#{term}%" }
        }
        scope :search_assigned, ->(term) { joins{ assignee }.where{ assignee.id == term } }
        scope :search_validated_not_assigned, lambda { |term|
          joins{ certificate_contents }
            .joins{ certificate_contents.locked_registrant }
            .where do
            (assignee_id == nil) &
              (certificate_contents.workflow_state == 'validated') &
              (certificate_contents.locked_registrant.email == term)
          end
        }

        scope :search_with_csr, lambda { |term, options={}|
          term ||= ''
          term = term.strip.split(/\s(?=(?:[^']|'[^']*')*$)/)
          filters = {common_name: nil, organization: nil, organization_unit: nil, address: nil, state: nil, postal_code: nil,
                     subject_alternative_names: nil, locality: nil, country:nil, signature: nil, fingerprint: nil, strength: nil,
                     expires_at: nil, created_at: nil, login: nil, email: nil, account_number: nil, product: nil,
                     decoded: nil, is_test: nil, order_by_csr: nil, physical_tokens: nil, issued_at: nil, notes: nil,
                     ref: nil, external_order_number: nil, status: nil, duration: nil, co_tags: nil, cc_tags: nil,
                     folder_ids: nil}
          filters.each{ |fn, fv|
            term.delete_if { |s|s =~ Regexp.new(fn.to_s + "\\:\\'?([^']*)\\'?"); filters[fn] ||= $1; $1 }
          }
          term = term.empty? ? nil : term.join(' ')
          return nil if [term,*(filters.values)].compact.empty?
          result = not_new
          cc_query = CertificateContent
          keys = filters.map{ |f|f[0] if !f[1].blank? }.compact
          unless term.blank?
            # if 'is_test' and 'order_by_csr' are the only search terms, keep it simple
            result = case term
                     when /co-\w/i
                       result.where{
                         (ref =~ "%#{term}%") |
                             (notes =~ "%#{term}%")
                       }
                     when /\d{7,8}/
                       result.where{
                         (external_order_number =~ "%#{term}%") |
                             (notes =~ "%#{term}%")
                       }
                     else
                       sql = %(MATCH (csrs.common_name, csrs.body, csrs.decoded) AGAINST ('#{term}') OR
                        MATCH (signed_certificates.common_name, signed_certificates.url, signed_certificates.body,
                        signed_certificates.decoded, signed_certificates.ext_customer_ref, signed_certificates.ejbca_username)
                        AGAINST ('#{term}') OR
                        MATCH (ssl_accounts.acct_number, ssl_accounts.company_name, ssl_accounts.ssl_slug) AGAINST ('#{term}') OR
                        MATCH (certificate_orders.ref, certificate_orders.external_order_number, certificate_orders.notes) AGAINST ('#{term}') OR
                        MATCH (users.login, users.email) AGAINST ('#{term}')).squish
                       result.joins{ csrs.outer }.joins{ csrs.outer.signed_certificates.outer }.joins{ ssl_account.outer }.
                           joins{ ssl_account.users.outer }.where(sql)
                     end
          end
          result = result.joins{ ssl_account.outer } unless (keys & [:account_number]).empty?
          result = result.joins{ ssl_account.users.outer } unless (keys & [:login, :email]).empty?
          cc_query = (cc_query || CertificateContent).joins{ csrs } unless
              (keys & [:country, :strength, :common_name, :organization, :organization_unit, :state,
                       :subject_alternative_names, :locality, :decoded]).empty?
          cc_query = (cc_query || CertificateContent).joins{ csr.signed_certificates.outer } unless
              (keys & [:country, :strength, :postal_code, :signature, :fingerprint, :expires_at, :created_at, :issued_at,
                       :common_name, :organization, :organization_unit, :state, :subject_alternative_names, :locality,
                       :decoded, :address]).empty?
          %w(is_test).each do |field|
            query = filters[field.to_sym]
            if query.try('true?')
              result = result.send(field)
            elsif query.try('false?')
              result = result.not_test
            end
          end
          %w(order_by_csr).each do |field|
            query = filters[field.to_sym]
            result = result.send(field) if query.try('true?')
          end
          %w(physical_tokens).each do |field|
            query = filters[field.to_sym]
            result = result.search_physical_tokens(query) if query
          end
          %w(postal_code signature fingerprint).each do |field|
            query = filters[field.to_sym]
            cc_query = cc_query.where{
              (csr.signed_certificates.send(field.to_sym) =~ "%#{query}%")} if query
          end
          %w(product).each do |field|
            query = filters[field.to_sym]
            result = result.filter_by(query) if query
          end
          %w(duration).each do |field|
            query = filters[field.to_sym]
            result = result.filter_by_duration(query) if query
          end
          %w(ref).each do |field|
            query = filters[field.to_sym]
            if query
              result = result.where{ ref >> query.split(',') }
              cc_query = cc_query.where{ ref >> query.split(',') }
            end
          end
          %w(country strength).each do |field|
            query = filters[field.to_sym]
            cc_query = cc_query.where{
              (csr.signed_certificates.send(field.to_sym) >> query.split(',')) |
                  (csrs.send(field.to_sym) >> query.split(','))} if query
          end
          %w(status).each do |field|
            query = filters[field.to_sym]
            if query
              cc_query = cc_query.where{ workflow_state >> query.split(',') }
            end
          end
          %w(common_name organization organization_unit state subject_alternative_names locality decoded).each do |field|
            query = filters[field.to_sym]
            cc_query = cc_query.where{
              (csr.signed_certificates.send(field.to_sym) =~ "%#{query}%") |
                  (csrs.send(field.to_sym) =~ "%#{query}%") } if query
          end
          %w(address).each do |field|
            query = filters[field.to_sym]
            cc_query = cc_query.where{
              (csr.signed_certificates.address1 =~ "%#{query}%") |
                  (csr.signed_certificates.address2 =~ "%#{query}%")} if query
          end
          %w(login email).each do |field|
            query = filters[field.to_sym]
            result = result.where{
              (ssl_account.users.send(field.to_sym) =~ "%#{query}%")} if query
          end
          %w[account_number].each do |_field|
            query = filters[:acct_number]
            result = result.where{ (ssl_account.send(:acct_number) =~ "%#{query}%") } if query
          end
          %w(expires_at created_at issued_at).each do |field|
            query = filters[field.to_sym]
            if query
              query = query.split('-')
              start = Date.strptime query[0], '%m/%d/%Y'
              finish = query[1] ? Date.strptime(query[1], '%m/%d/%Y') : start + 1.day
              if(field == 'expires_at')
                cc_query = cc_query.where{ (csr.signed_certificates.expiration_date >> (start..finish)) }
              elsif(field == 'issued_at')
                cc_query = cc_query.where{ (csr.signed_certificates.created_at >> (start..finish)) }
              else
                result = result.where{ created_at >> (start..finish) }
              end
            end
          end
          %w(co_tags).each do |field|
            query = filters[field.to_sym]
            if query
              @result_prior_co_tags = result
              result = result.joins(:tags).where(tags: {name: query.split(',')})
            end
          end
          %w(cc_tags).each do |field|
            query = filters[field.to_sym]
            if query
              cc_results = (@result_prior_co_tags || result)
                               .joins(certificate_contents: [:tags]).where(tags: {name: query.split(',')})

              result = if @result_prior_co_tags.nil?
                         cc_results
                       else
                         # includes tags in BOTH certificate orders and certificate contents tags, not a union
                         CertificateOrder.where(id: (result + cc_results).map(&:id).uniq)
                       end
            end
          end
          %w(folder_ids).each do |field|
            query = filters[field.to_sym]
            result = result.where(folder_id: query.split(',')) if query
          end
          if cc_query != CertificateContent
            ids = cc_query.pluck(:id).uniq
            unless ids.empty?
              result.joins{ certificate_contents }.where{ certificate_contents.id >> ids }
            else
              result.uniq
            end
          else
            result.uniq
          end
        }

        scope :order_by_csr, lambda {
          joins{ certificate_contents.csr.outer }.order('csrs.created_at desc') # .uniq #- breaks order by csr
        }

        scope :filter_by, lambda { |term|
          terms = term.split(',').map{ |t| t + '%' }
          joins{ sub_order_items.product_variant_item.product_variant_group.variantable(::Certificate)}.where(('certificates.product like ?@' * terms.count).split('@').join(' OR '), *terms)
        }

        scope :filter_by_duration, lambda { |term|
          joins{ certificate_contents }.where{ certificate_contents.duration >> term.split(',') }
        }

        scope :unvalidated, lambda {
          joins(:certificate_contents).where do
            (is_expired == false) &
              (certificate_contents.workflow_state >> %w[pending_validation contacts_provided])
          end
                                      .order('certificate_contents.updated_at asc')
        }

        scope :not_csr_blank, ->{ joins{ certificate_contents.csr }.where{ certificate_contents.csr.id != nil } }

        scope :incomplete, lambda {
                             not_test.joins(:certificate_contents).where do
                               (is_expired == false) &
                                 (certificate_contents.workflow_state >> %w[csr_submitted info_provided contacts_provided])
                             end
                                     .order('certificate_contents.updated_at asc')
                           }

        scope :pending, ->{ not_test.joins(:certificate_contents).where{ certificate_contents.workflow_state >> %w[pending_validation validated]}.order('certificate_contents.updated_at asc')}

        scope :has_csr, ->{ not_test.joins(:certificate_contents).where{ (workflow_state == 'paid') & (certificate_contents.signing_request != '')}.order('certificate_contents.updated_at asc')}

        scope :credits, ->{ not_test.joins(:certificate_contents).where({ workflow_state: 'paid' } & { is_expired: false } & { certificate_contents: { workflow_state: 'new' } })} # and not new

        # new certificate orders are the ones still in the shopping cart
        scope :not_new, lambda { |options = nil|
          includes = method(:includes).call(options[:includes]) if options&.key?(:includes)
          (includes || self).where{ workflow_state << ['new'] }.uniq
        }

        scope :is_new, ->{ where{ workflow_state >> ['new'] }.uniq }
        scope :unrenewed, ->{ not_new.where(renewal_id: nil) }
        scope :renewed, ->{ not_new.where{ :renewal_id != nil } }
        scope :nonfree, ->{ not_new.where(:amount.gt => 0) }
        scope :free, ->{ not_new.where(amount: 0) }
        scope :unused_credits, lambda {
          unused = joins{}
          where{ (workflow_state == 'paid') & (is_expired == false) & (id << unused.joins{ certificate_contents.csr.signed_certificates.outer }.pluck(id).uniq) }
        }

        scope :used_credits, lambda {
          unused = where{ (workflow_state == 'paid') & (is_expired == false) }
          where{ id >> unused.joins{ certificate_contents.csr.signed_certificates.outer }.pluck(id) }
        }

        scope :unflagged_expired_credits, ->{ unused_credits.where{ created_at < Settings.cert_expiration_threshold_days.to_i.days.ago }}
        scope :unused_purchased_credits, ->{ unused_credits.where{ amount > 0 } }
        scope :unused_free_credits, ->{ unused_credits.where{ amount == 0 } }
        scope :falsely_expired, -> { unscoped.where{ (workflow_state == 'paid') & (is_expired == true) & (external_order_number != nil)}}

        scope :range, lambda{ |start, finish|
          if start.is_a?(String)
            (s = %r{/}.match?(start) ? '%m/%d/%Y' : '%m-%d-%Y')
            start = Date.strptime(start, s)
          end
          if finish.is_a?(String)
            (f = %r{/}.match?(finish) ? '%m/%d/%Y' : '%m-%d-%Y')
            finish = Date.strptime(finish, f)
          end
          where{ created_at >> (start..finish) }
        } do
          def amount
            nonfree.sum(:amount) * 0.01
          end
        end
      end
    end
  end
end

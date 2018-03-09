module Sortable
  extend ActiveSupport::Concern

  module ClassMethods
    def sort_with(params)
      column_name = params[:column]
      direction   = params[:direction]

      scope = order(created_at: :desc) if column_name.blank? || direction.blank?
      if (column_name && direction) &&
         (valid_request?(column_name, direction) || valid_association?(column_name))
        scope = scope_by_column_name(column_name.to_sym, direction.to_sym)
      end
      scope
    end

    private

    def scope_by_column_name(column_name, direction)
      case column_name
      when :end_date
        order("invoices.end_date #{direction.upcase}")
      when :reference_number
        order("invoices.reference_number #{direction.upcase}")
      when :status
        order("invoices.status #{direction.upcase}")
      when :orders
        group("orders.invoice_id").order!("count(orders.invoice_id) #{direction.upcase}")
      else
        order(Hash[column_name, direction])
      end
    end

    def valid_association?(column_name)
      method_defined?(column_name.to_sym)
    end

    def valid_request?(column_name, direction)
      column_valid?(column_name) && direction_valid?(direction)
    end

    def column_valid?(column_name)
      column_names.include?(column_name)
    end

    def direction_valid?(direction)
      %i[desc asc].include?(direction.to_sym)
    end
  end
end

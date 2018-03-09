module Filterable
  extend ActiveSupport::Concern

  COMPARISON = {
    less_than: '<',
    greater_than: '>',
    equal: '=',
    less_or_equal: '<=',
    greater_or_equal: '>='
  }

  class_methods do
    def filter(filters = nil, scope = nil, relationship = nil)
      self.filter_scope = scope || where(nil)
      return filter_scope if filters.blank?

      filters.each_pair do |filter_attr, operation_hash|
        if is_relationship?(filter_attr)
          # TODO: Check if this is performant. Possible n + 1
          self.filter_scope = filter_scope.references(filter_attr)
          # TODO: Have a recursion check to make sure that this method in not
          # infinite looping
          filter(operation_hash, filter_scope, filter_attr)
        else
          operation(filter_attr, operation_hash, relationship)
        end
      end

      filter_scope
    end

    def operation(filter_attr, operation_hash, relationship)
      operation_hash.each_pair do |operator, value|
        raise "NOPE!" unless valid_operator? operator

        self.filter_scope = filter_scope.where(
          where_sql(filter_attr, operator, value, relationship)
        )
      end
    end

    def where_sql(filter_attr, operator, value, relationship)
      if relationship
        "#{relationship.to_s.pluralize}.#{filter_attr} #{operator} #{format_sql_value(value)}"
      elsif filter_attr == :created_at
        "DATE(#{table_name}.#{filter_attr}) #{operator} #{format_sql_value(value)}"
      elsif operator == 'LIKE'
        ["lower(#{table_name}.#{filter_attr}) #{operator} (?)", "%#{value.downcase}%"]
      else
        "#{table_name}.#{filter_attr} #{operator} #{format_sql_value(value)}"
      end
    end

    def format_sql_value(value)
      if value.is_a? Array
        value.to_s.gsub("[", "(").gsub("]", ")").gsub('"', "'")
      else
        "'#{value}'"
      end
    end

    def valid_operator?(operator)
      ['<', '>', '<=', '>=', '=', '!=', 'in', 'not in', 'LIKE'].include?(operator)
    end

    def is_relationship?(filter_attr)
      reflections.keys.include? filter_attr.to_s
    end

    def filter_scope
      instance_variable_get(:@filter_scope)
    end

    def filter_scope=(scope)
      instance_variable_set(:@filter_scope, scope)
    end
  end
end

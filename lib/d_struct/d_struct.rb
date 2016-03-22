require 'dry-validation'

module DStruct
  class DStruct

    attr_reader :to_h

    def self.attributes(attributes_hash)
      @attributes_readers   = attributes_hash.values.flatten
      @string_attributes    = attributes_hash[:strings]   || []
      @integer_attributes   = attributes_hash[:integers]  || []
      @boolean_attributes  = attributes_hash[:booleans]   || []
      @array_attributes     = attributes_hash[:arrays]    || []
      @date_attributes      = attributes_hash[:dates]     || []

      # generate readers
      attr_reader *@attributes_readers

      # generate writers
      @string_attributes.each do |string_attr|
        define_method "#{string_attr}=" do |str_arg|
          value = str_arg.to_s
          instance_variable_set("@#{string_attr}", value)
          @to_h[string_attr] = value
        end
      end

      @integer_attributes.each do |int_attr|
        define_method "#{int_attr}=" do |int_arg|
          value = (Integer(int_arg) rescue nil)
          instance_variable_set("@#{int_attr}", value)
          @to_h[int_attr] = value
        end
      end

      @boolean_attributes.each do |boolean_attr|
        define_method "#{boolean_attr}=" do |boolean_arg|
          value = !!boolean_arg
          value = nil if boolean_arg.nil?
          instance_variable_set("@#{boolean_attr}", value)
          @to_h[boolean_attr] = value
        end
      end

      @array_attributes.each do |arr_attr|
        define_method "#{arr_attr}=" do |arr_arg|
          value = (Array(arr_arg) rescue nil)
          instance_variable_set("@#{arr_attr}", value)
          @to_h[arr_attr] = value
        end
      end

      @date_attributes.each do |date_attr|
        define_method "#{date_attr}=" do |date_arg|
          value = (Date.parse(date_arg.to_s) rescue nil)
          instance_variable_set("@#{date_attr}", value)
          @to_h[date_attr] = value
        end
      end
    end

    def add_validation_schema(*schema)
      @validation_schemas << schema
    end

    def initialize(attributes_hash)
      @to_h = {}
      @validation_schemas = []
      attributes_hash.each do |k,v|
        begin
          send("#{k}=", v)
        rescue # unknown key
          @errors = {k => 'unknown key'}
          break
        end
      end
    end

    def errors
      return @errors if @errors               # unknown key
      return {} if @validation_schemas == []  # no schemas
      @errors ||= @validation_schemas.flatten.reduce({}){|errors, schema| errors.update(schema.call(to_h).messages)}
    end

    # call once, it is cached in @errors
    def valid?
      errors.empty?
    end

  end
end
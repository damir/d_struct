require 'test_helper'

class DStructTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::DStruct::VERSION
  end

  class MyStruct < DStruct::DStruct
    attributes strings: [:string], integers: [:int], booleans: [:bool], arrays: [:arr], dates: [:date], times: [:time]
  end

  MyValidationSchema = Dry::Validation.Schema do
    key(:string).required(:str?)
    key(:int).required(:int?)
    key(:bool).required(:bool?)
    key(:arr).required(:array?)
    key(:date).required(:date?)
    key(:time).required(:time?)
  end

  class MyStructWithContext < DStruct::DStruct
    attributes strings: [:context_key]
  end

  MyContextValidationSchema = Dry::Validation.Schema do

    configure do
      config.messages_file = Pathname(__dir__).join('errors.yml')

      option :context, 'context value'

      def same_as_context_value?(value)
        context == value
      end
    end

    key(:context_key).required(:same_as_context_value?)
  end

  def setup
    @time = Time.now
    @valid_input_hash = {string: '123', int: 123, bool: true, arr: [1], date: Date.today, time: @time}
  end

  def test_valid_input_without_casting_and_without_validator_schema
    struct = MyStruct.new(@valid_input_hash)
    assert struct.valid?
    assert_equal({}, struct.errors)

    # time objects are not the same, only their to_s values
    # assert @valid_input_hash == struct.to_h

    assert_equal '123', struct.string
    assert_equal 123, struct.int
    assert_equal true, struct.bool
    assert_equal [1], struct.arr
    assert_equal Date.today, struct.date
    assert_equal @time.to_s, struct.time.to_s

    assert_equal String, struct.string.class
    assert_equal Fixnum, struct.int.class
    assert_equal TrueClass, struct.bool.class
    assert_equal Array, struct.arr.class
    assert_equal Date, struct.date.class
    assert_equal Time, struct.time.class
  end

  def test_valid_input_with_casting_and_without_validator_schema
    struct = MyStruct.new(string: 123, int: '123', bool: 'true', arr: 1, date: Date.today.to_s)

    assert struct.valid?
    assert_equal({}, struct.errors)

    assert_equal '123', struct.string
    assert_equal 123, struct.int
    assert_equal true, struct.bool
    assert_equal [1], struct.arr
    assert_equal Date.today, struct.date

    assert_equal String, struct.string.class
    assert_equal Fixnum, struct.int.class
    assert_equal TrueClass, struct.bool.class
    assert_equal Array, struct.arr.class
    assert_equal Date, struct.date.class
  end

  def test_not_defined_key
    struct = MyStruct.new({unknown_key: '123'}.merge(@valid_input_hash))
    assert !struct.valid?
    assert_equal({}, struct.to_h)
    assert_equal({unknown_key: 'unknown key'}, struct.errors)
  end

  def test_valid_input_with_validator_schema
    struct = MyStruct.new(@valid_input_hash)
    struct.add_validation_schema MyValidationSchema
    assert struct.valid?
    assert_equal({}, struct.errors)
    # time objects are not the same, only their to_s values
    # assert @valid_input_hash == struct.to_h
  end

  def test_invalid_input_with_validator_schema
    struct = MyStruct.new({string: nil, int: nil, bool: nil, arr: nil, date: nil})
    struct.add_validation_schema MyValidationSchema
    assert !struct.valid?
    assert_equal 6, struct.errors.keys.size
  end

  def test_missing_keys_with_validator_schema
    struct = MyStruct.new({})
    struct.add_validation_schema MyValidationSchema
    assert !struct.valid?
    assert_equal 6, struct.errors.keys.size
  end

  def test_context
    struct = MyStructWithContext.new({context_key: 'invalid value'})
    struct.add_validation_schema MyContextValidationSchema
    assert_equal ({context_key: ["not the same"]}), struct.errors
    assert !struct.valid?
  end

  def test_multiple_schemas
    schema1 = Dry::Validation.Schema do
      key(:string).required(:str?)
      key(:int).required(:int?)
    end

    schema2 = Dry::Validation.Schema do
      key(:bool).required(:bool?)
      key(:arr).required(:array?)
    end

    invalid_struct = MyStruct.new({})
    invalid_struct.add_validation_schema schema1, schema2
    assert 4, invalid_struct.errors.keys.size
    assert !invalid_struct.valid?

    valid_struct = MyStruct.new(@valid_input_hash)
    valid_struct.add_validation_schema schema1
    valid_struct.add_validation_schema schema2
    assert valid_struct.valid?
  end

end

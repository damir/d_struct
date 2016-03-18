# DStruct

## Usage

```ruby
  # configure attribute types
  class MyStruct < DStruct::DStruct
    attributes strings: [:string], integers: [:int], booleans: [:bool], arrays: [:arr]
  end
  
  # define dry-validation schema - http://dry-rb.org/gems/dry-validation/
  MyValidationSchema = Dry::Validation.Schema do
    key(:string).required(:str?)
    key(:int).required(:int?)
    key(:bool).required(:bool?)
    key(:arr).required(:array?)
  end
  
  # initialize with hash
  struct = MyStruct.new({string: 'abc', int: 123, bool: true, arr: [1]})
  struct.add_validation_schema MyValidationSchema
  puts struct.to_h   # => {string: 'abc', int: 123, bool: true, arr: [1]}
  puts struct.valid? # => true
  puts struct.errors # => {}
  
  # unknown key
  struct = MyStruct.new({unknown_key: '123'})
  puts struct.valid? # => false
  puts struct.errors # => {unknown_key: 'unknown key'}
  
  # missing keys
  struct = MyStruct.new({})
  puts struct.valid? # => false
  puts struct.errors # => {:string=>["is missing"], :int=>["is missing"], :bool=>["is missing"], :arr=>["is missing"]}
  
  # invalid values
  struct = MyStruct.new({string: nil, int: nil, bool: nil, arr: nil})
  puts struct.valid? # => false
  puts struct.errors # => {:string=>["must be filled"], :int=>["must be filled"], :bool=>["must be filled"], :arr=>["must be filled"]}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'd_struct'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install d_struct

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/damir/d_struct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

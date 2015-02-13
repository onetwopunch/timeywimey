# Timeywimey

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'timeywimey'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timeywimey

## Usage

    require 'timeywimey'

    from_time = Time.now - 3.days - 4.hours
    Tw.time_ago_in_words from_time
    #=> "3 days"

## Contributing

1. Fork it ( https://github.com/onetwopunch/timeywimey/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

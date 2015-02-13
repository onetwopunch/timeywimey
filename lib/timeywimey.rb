require "timeywimey/version"
require 'active_support/dependencies/autoload'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/date'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/date/conversions'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/with_options'

module Tw
  MINUTES_IN_YEAR = 525600
  MINUTES_IN_QUARTER_YEAR = 131400
  MINUTES_IN_THREE_QUARTERS_YEAR = 394200

  def self.root
    File.absolute_path File.join(__FILE__, '../..')
  end

  def self.distance_of_time_in_words(from_time, to_time = 0, options = {})
    options = {
      scope: :'datetime.distance_in_words'
    }.merge!(options)

    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    from_time, to_time = to_time, from_time if from_time > to_time
    distance_in_minutes = ((to_time - from_time)/60.0).round
    distance_in_seconds = (to_time - from_time).round
    I18n.load_path << File.join(Tw.root, "lib/timeywimey/locale/en.yml")
    puts I18n.load_path
    I18n.with_options :locale => options[:locale], :scope => options[:scope] do |locale|
      case distance_in_minutes
        when 0..1
          return distance_in_minutes == 0 ?
                 locale.t(:less_than_x_minutes, :count => 1) :
                 locale.t(:x_minutes, :count => distance_in_minutes) unless options[:include_seconds]

          case distance_in_seconds
            when 0..4   then locale.t :less_than_x_seconds, :count => 5
            when 5..9   then locale.t :less_than_x_seconds, :count => 10
            when 10..19 then locale.t :less_than_x_seconds, :count => 20
            when 20..39 then locale.t :half_a_minute
            when 40..59 then locale.t :less_than_x_minutes, :count => 1
            else             locale.t :x_minutes,           :count => 1
          end

        when 2...45           then locale.t :x_minutes,      :count => distance_in_minutes
        when 45...90          then locale.t :about_x_hours,  :count => 1
        # 90 mins up to 24 hours
        when 90...1440        then locale.t :about_x_hours,  :count => (distance_in_minutes.to_f / 60.0).round
        # 24 hours up to 42 hours
        when 1440...2520      then locale.t :x_days,         :count => 1
        # 42 hours up to 30 days
        when 2520...43200     then locale.t :x_days,         :count => (distance_in_minutes.to_f / 1440.0).round
        # 30 days up to 60 days
        when 43200...86400    then locale.t :about_x_months, :count => (distance_in_minutes.to_f / 43200.0).round
        # 60 days up to 365 days
        when 86400...525600   then locale.t :x_months,       :count => (distance_in_minutes.to_f / 43200.0).round
        else
          if from_time.acts_like?(:time) && to_time.acts_like?(:time)
            fyear = from_time.year
            fyear += 1 if from_time.month >= 3
            tyear = to_time.year
            tyear -= 1 if to_time.month < 3
            leap_years = (fyear > tyear) ? 0 : (fyear..tyear).count{|x| Date.leap?(x)}
            minute_offset_for_leap_year = leap_years * 1440
            # Discount the leap year days when calculating year distance.
            # e.g. if there are 20 leap year days between 2 dates having the same day
            # and month then the based on 365 days calculation
            # the distance in years will come out to over 80 years when in written
            # English it would read better as about 80 years.
            minutes_with_offset = distance_in_minutes - minute_offset_for_leap_year
          else
            minutes_with_offset = distance_in_minutes
          end
          remainder                   = (minutes_with_offset % MINUTES_IN_YEAR)
          distance_in_years           = (minutes_with_offset.div MINUTES_IN_YEAR)
          if remainder < MINUTES_IN_QUARTER_YEAR
            locale.t(:about_x_years,  :count => distance_in_years)
          elsif remainder < MINUTES_IN_THREE_QUARTERS_YEAR
            locale.t(:over_x_years,   :count => distance_in_years)
          else
            locale.t(:almost_x_years, :count => distance_in_years + 1)
          end
      end
    end
  end

  # Like <tt>distance_of_time_in_words</tt>, but where <tt>to_time</tt> is fixed to <tt>Time.now</tt>.
  #
  #   time_ago_in_words(3.minutes.from_now)                 # => 3 minutes
  #   time_ago_in_words(3.minutes.ago)                      # => 3 minutes
  #   time_ago_in_words(Time.now - 15.hours)                # => about 15 hours
  #   time_ago_in_words(Time.now)                           # => less than a minute
  #   time_ago_in_words(Time.now, include_seconds: true) # => less than 5 seconds
  #
  #   from_time = Time.now - 3.days - 14.minutes - 25.seconds
  #   time_ago_in_words(from_time)      # => 3 days
  #
  #   from_time = (3.days + 14.minutes + 25.seconds).ago
  #   time_ago_in_words(from_time)      # => 3 days
  #
  # Note that you cannot pass a <tt>Numeric</tt> value to <tt>time_ago_in_words</tt>.
  #
  def self.time_ago_in_words(from_time, options = {})
    Tw.distance_of_time_in_words(from_time, Time.now, options)
  end

  private
    %w( sec min hour day month year ).each do |method|
      define_method(method) do
        @datetime.kind_of?(Numeric) ? @datetime : @datetime.send(method) if @datetime
      end
    end

    # If the day is hidden, the day should be set to the 1st so all month and year choices are
    # valid. Otherwise, February 31st or February 29th, 2011 can be selected, which are invalid.
    def set_day_if_discarded
      if @datetime && @options[:discard_day]
        @datetime = @datetime.change(:day => 1)
      end
    end

    # Returns translated month names, but also ensures that a custom month
    # name array has a leading nil element.
    def month_names
      @month_names ||= begin
        month_names = @options[:use_month_names] || translated_month_names
        month_names.unshift(nil) if month_names.size < 13
        month_names
      end
    end

    # Returns translated month names.
    #  => [nil, "January", "February", "March",
    #           "April", "May", "June", "July",
    #           "August", "September", "October",
    #           "November", "December"]
    #
    # If <tt>:use_short_month</tt> option is set
    #  => [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    #           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    def translated_month_names
      key = @options[:use_short_month] ? :'date.abbr_month_names' : :'date.month_names'
      I18n.translate(key, :locale => @options[:locale])
    end

    # Looks up month names by number (1-based):
    #
    #   month_name(1) # => "January"
    #
    # If the <tt>:use_month_numbers</tt> option is passed:
    #
    #   month_name(1) # => 1
    #
    # If the <tt>:use_two_month_numbers</tt> option is passed:
    #
    #   month_name(1) # => '01'
    #
    # If the <tt>:add_month_numbers</tt> option is passed:
    #
    #   month_name(1) # => "1 - January"
    #
    # If the <tt>:month_format_string</tt> option is passed:
    #
    #   month_name(1) # => "January (01)"
    #
    # depending on the format string.
    def month_name(number)
      if @options[:use_month_numbers]
        number
      elsif @options[:use_two_digit_numbers]
        '%02d' % number
      elsif @options[:add_month_numbers]
        "#{number} - #{month_names[number]}"
      elsif format_string = @options[:month_format_string]
        format_string % {number: number, name: month_names[number]}
      else
        month_names[number]
      end
    end

    def date_order
      @date_order ||= @options[:order] || translated_date_order
    end

end

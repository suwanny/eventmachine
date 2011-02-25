module EventMachine
  # Creates a one-time timer
  #
  #  timer = EventMachine::Timer.new(5) do
  #    # this will never fire because we cancel it
  #  end
  #  timer.cancel
  #
  class Timer
    # Create a new timer that fires after a given number of seconds
    def initialize interval, callback=nil, &block
      @signature = EventMachine::add_timer(interval, callback || block)
    end

    # Cancel the timer
    def cancel
      EventMachine.send :cancel_timer, @signature
    end
  end

  # Creates a periodic timer
  #
  #  n = 0
  #  timer = EventMachine::PeriodicTimer.new(5) do
  #    puts "the time is #{Time.now}"
  #    timer.cancel if (n+=1) > 5
  #  end
  #
  class PeriodicTimer
    # Create a new periodic timer that executes every interval seconds
    def initialize interval, callback=nil, &block
      @interval = interval
      @code = callback || block
      @cancelled = false
      @work = method(:fire)
      schedule
    end

    # Cancel the periodic timer
    def cancel
      @cancelled = true
    end

    # Fire the timer every interval seconds
    attr_accessor :interval

    def schedule # :nodoc:
      EventMachine::add_timer @interval, @work
    end
    def fire # :nodoc:
      unless @cancelled
        @code.call
        schedule
      end
    end
  end
  
  # Creates a compensation periodic timer which compensates time drifts. 
  #
  #  n = 0
  #  timer = EventMachine::CompensationPeriodicTimer.new(5) do
  #    puts "the time is #{Time.now.to_f.round(1)}"
  #    timer.cancel if (n+=1) > 5
  #  end
  #
  class CompensationPeriodicTimer < PeriodicTimer
    attr_accessor :resolution

    # Create a new periodic timer that executes every interval seconds
    def initialize interval, callback=nil, &block
      # Remember the start-time to adjust intervals
      @start = Time.now
      
      # Don't schedule if the next_interval is less than Resolution.
      @resolution = 0.001
      
      # do the same things in PeriodicTimer.
      @interval = interval
      @code = callback || block
      @cancelled = false
      @work = method(:fire)
      schedule
    end

    def schedule # :nodoc:
      # Calculate the compensation and the next interval.
      # Note that if the job is bigger than the interval,
      # This scheduling will skip the slot. 
      compensation = (Time.now - @start) % @interval  
      next_interval = @interval - compensation
      next_interval += @interval if next_interval < @resolution
      
      EventMachine::add_timer next_interval, @work
    end
  end
end

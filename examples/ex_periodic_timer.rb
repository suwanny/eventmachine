require File.dirname(__FILE__) + '/helper'

EM.run do
  EM::add_compensation_periodic_timer(1.0) do
    now = Time.new
    printf "%s compensation timer: %.3f, ", now.to_s, now.to_f
  end
  
  EM::add_periodic_timer(1.0) do
    printf "    periodic timer: %.3f\n", Time.new.to_f
  end
end
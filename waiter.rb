require 'selenium-webdriver'
require 'rspec/expectations'
include RSpec::Matchers

# globals
$instance = 1
$domain   = "pubcloudnews.tech" # default
$debug    = 0

def log(str)
  ts=Time.now
  puts "#{ts} waiter.rb(#{$instance}): #{str}"
  STDOUT.flush
end

def dbg(str)
  if ($debug.to_i > 0) 
     ts=Time.now
     puts "#{ts} DEBUG: waiter.rb(#{$instance}): #{str}"
     STDOUT.flush
  end
end

# delay traffic to avoid google anonamly reports, avoid spikes, instead, slowly increasing over time
def sleep_current_min_max_delay
  dbg "sleep_current_min_max_delay..."
  delay = IO.readlines("#{$domain}/delay")
  min=delay[0].to_i
  max=delay[1].to_i
  sleep = Random.rand(min...max)
  dbg "sleep_current_min_max_delay: current min=#{min} current max=#{max}"
  log "sleep_current_min_max_delay: #{sleep} seconds"
  sleep sleep
  log "sleep_current_min_max_delay: done."
end

# delay decrease in % of a single run, only for a single instance:
# see domains to see for what instance per domain we check 1,7,11 now
#
def reduce_current_min_max_delay
  dbg "reduce_current_min_max_delay for instance #{$instance}"
  rand = Random.rand(1...1000)
  # configurable start min and max for downcount waiter
  minmax = IO.readlines("#{$domain}/minmax")
  start_min=minmax[0].to_i
  start_max=minmax[1].to_i
  step=minmax[2].to_i
  pct=minmax[3].to_i # 0 .. 1000
  dbg "read #{$domain}/minmax: start_min=#{start_min} start_max=#{start_max} step=#{step} chance=#{pct}/1000"
  if (rand < pct) # 70% - period to decrease sleeps faster, with larger random steps
     dbg "reduce_current_min_max_delay: actual reducing"
     reduce=Random.rand(1..step)
     delay = IO.readlines("#{$domain}/delay")
     min=delay[0].to_i
     max=delay[1].to_i
     dbg "current min=#{min} new max=#{max} reduce=#{reduce}"
     min=min-reduce
     max=max-reduce
     if (min < step)
        min = start_min
     end
     if (max <= start_min)
        max = start_max
     end
     dbg "new min=#{min} new max=#{max}"
     File.open("#{$domain}/delay", "w") { |f| f.write "#{min}\n#{max}\n" }
  end
end

def run
  $instance=ARGV[0]||"1"
  $domain=ARGV[1]||"#{$domain}"
  log "waiter run instance=#{$instance} domain=#{$domain}..."
  if ($instance != "30")
     reduce_current_min_max_delay
     sleep_current_min_max_delay
  else
    log "waiter: analyser run - not waiting"
  end
     log "waiter run: done."
end

run()

require 'selenium-webdriver'
require 'rspec/expectations'
include RSpec::Matchers

# globals
$instance = 1
$domain   = "pubcloudnews.tech" # default

def log(str)
  ts=Time.now
  puts "#{ts} waiter.rb(#{$instance}): #{str}"
  STDOUT.flush
end

def randomsleep(func, min, max)
   sleep = Random.rand(min...max)
   log "#{func}: sleep #{sleep} seconds"
   sleep sleep
   log "#{func}: sleep done."
end

# delay traffic to avoid google anonamly reports, avoid spikes, instead, slowly increasing over time
def sleep_current_min_max_delay
  log "sleep_current_min_max_delay..."
  delay = IO.readlines("#{$domain}/delay")
  min=delay[0].to_i
  max=delay[1].to_i
  sleep = Random.rand(min...max)
  log "sleep_current_min_max_delay: current min=#{min} current max=#{max}"
  log "sleep_current_min_max_delay: #{sleep} seconds"
  sleep sleep
  log "sleep_current_min_max_delay: done."
end

# delay decrease in % of a single run, only for a single instance:
# see domains to see for what instance per domain we check 1,7,11 now
#
def reduce_current_min_max_delay
  log "reduce_current_min_max_delay for instance #{$instance}"
  rand = Random.rand(1...1000)
  if (rand < 500) # 50% - period to decrease sleeps faster, with larger random steps
     log "reduce_current_min_max_delay: actual reducing"
     reduce= Random.rand(5)
     delay = IO.readlines("#{$domain}/delay")
     min=delay[0].to_i
     max=delay[1].to_i
     min=min-reduce
     max=max-reduce
     if (min < 2)
        min = 100
     end
     if (max < 11)
        max = 200
     end
     log "reduce_current_min_max_delay new min #{min} new max #{max}"
     File.open("#{$domain}/delay", "w") { |f| f.write "#{min}\n#{max}\n" }
  end
end

def run
  $instance=ARGV[0]||"1"
  $domain=ARGV[1]||"#{$domain}"
  log "waiter run instance=#{$instance} domain=#{$domain}..."
  if ($instance != "20")
     reduce_current_min_max_delay
     sleep_current_min_max_delay
  else
    log "waiter: analyser run - not waiting"
  end
     log "waiter run: done."
end

run()

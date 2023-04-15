require 'selenium-webdriver'
require 'rspec/expectations'
include RSpec::Matchers

# globals
$timeouts = 0
$instance = 1

def log(str)
  ts=Time.now
  puts "#{ts} runner.rb(#{$instance}): #{str}"
  STDOUT.flush
end

def randomsleep(func, min, max)
   sleep = Random.rand(min...max)
   if ($instance.to_i == 20) 
      sleep=10
   end
   log "#{func}: sleep #{sleep} seconds"
   sleep sleep
   log "#{func}: sleep done."
end

def setup(agent,port)
  log "setup..."
  mobile_emulation = { "userAgent" => agent }
  # selenuim is started in docker with a port mapping and listens to port 5000, 5001 etc.
  url = "http://0.0.0.0:" + port + "/wd/hub"
  options = Selenium::WebDriver::Chrome::Options.new
  #options.add_argument '--proxy-server=' + proxy
  options.add_argument '--disable-gpu'
  options.add_argument('--disable-infobars')
  options.add_argument('--disable-translate') 
  options.add_argument('--headless') 
  options.add_option(:detach, true)
  options.add_option(:accept_insecure_certs, true)
  options.add_option(:mobileEmulation, mobile_emulation )
  @driver = Selenium::WebDriver.for(:remote, url: url, capabilities: options)
  log "setup_with_socks_proxy: done."
end

def teardown
  log "teardown driver.quit"
  begin
    @driver.quit
  rescue => e
     log "teardown: exception rescue teardown"
     log "teardown: an error of type #{e.class} happened, message is #{e.message}"
   ensure
      log "teardown: ensure"
  end
  log "teardown done."
end


def login(url)
     log "login: url=" + url
     begin
        @driver.get url
        log "get url done sleep 15 to let cloudflare do its things"
        sleep 15

        html = @driver.find_element(:tag_name, 'html')
        log "login: html retrived size = " + html.attribute("innerHTML").length.to_s
        log html.attribute("innerHTML")

        button = @driver.find_element(:tag_name, 'button')
        button.click() # log in
        log "login button.click done, sleep 15..."
        sleep 15

        @driver.find_element(:name, "username").send_keys("aprutgers@hotmail.com")
        button = @driver.find_element(:tag_name, 'button')
        button.click() # log in
        log "username button.click done, sleep 15..."
        sleep 15

        @driver.find_element(:name, "password").send_keys("4izNnFnUT8WB3hp")
        button = @driver.find_element(:xpath => '/html/body/main/section/div/div/div/form/div[2]/button')
        print button
        print button.text
        button.click() # log in
        log "password button.click done, sleep 15..."
        sleep 15

        title=@driver.title
        log "login title=" + title

        html = @driver.find_element(:tag_name, 'html')
        log html.attribute("innerHTML")

        log "printing all cookies..."
        @driver.manage.all_cookies.each do |cookie|
           puts cookie[:name]
           puts cookie[:value]
        end
        STDOUT.flush
     rescue => e
        log "login: An error of type #{e.class} happened, message is #{e.message}"
        log "login: error at driver.get url, ignored"
     ensure
        log "login: exception ensure"
     end
     log "login: done."
end

def run
  log "run ..."
  port=ARGV[0]
  $instance=ARGV[1]||"20"
  agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
  log "run: port="  + port
  log "run: agent=" + agent
  setup(agent,port)
  start='https://chat.openai.com/auth/login'
  login(start)
  log "run: done."
end

run()

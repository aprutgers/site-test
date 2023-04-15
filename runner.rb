require 'selenium-webdriver'
require 'rspec/expectations'
include RSpec::Matchers

# globals
$timeouts = 0
$instance = 1
$domain   = "pubcloudnews.tech" # default
$country  = ""
$vrecurse = 0
$ctr      = 16 # safe default

def log(str)
  ts=Time.now
  puts "#{ts} runner.rb(#{$instance}): #{str}"
  STDOUT.flush
end

def randomsleep(func, min, max)
   sleep = Random.rand(min...max)
   if ($instance.to_i == 20) 
      sleep=8
   end
   log "#{func}: sleep #{sleep} seconds"
   sleep sleep
   log "#{func}: sleep done."
end

def setup_with_socks_proxy(agent,port)
  log "setup_with_socks_proxy..."
  # proxy is implemented by running instance of psiphon-tunnel-core-x86_64, listening to port 8081, 8082,.. (instance counts up)
  proxyport = 8080 + $instance.to_i
  proxy="http://host.docker.internal:" + proxyport.to_s
  log "setup_with_socks_proxy: proxy=" + proxy
  mobile_emulation = { "userAgent" => agent }
  # selenuim is started in docker with a port mapping and listens to port 5000, 5001 etc.
  url = "http://0.0.0.0:" + port + "/wd/hub"
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument '--proxy-server=' + proxy
  options.add_argument 'user-data-dir=/mnt/tmp/chrome' + $instance
  #options.add_argument '-disk-cache-size=4096'
  #DO NOT USE HEADLESS OPTION
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

def get_random_agent
  random_line = nil
  File.open("#{$domain}/agents") do |file|
    file_lines = file.readlines()
    random_line = file_lines[Random.rand(0...file_lines.size())]
  end 
  random_line
end 

def get_random_search
  log "get_random_search..."
  random_line = nil
  File.open("#{$domain}/search") do |file|
    file_lines = file.readlines()
    random_line = file_lines[Random.rand(0...file_lines.size())]
  end 
  random_line
end 

def get_random_article
  random_line = nil
  File.open("#{$domain}/articles") do |file|
    file_lines = file.readlines()
    random_line = file_lines[Random.rand(0...file_lines.size())]
  end 
  random_line
end 

def get_ctr
  line = nil
  File.open("#{$domain}/ctr") do |file|
    file_lines = file.readlines()
    line=file_lines[0]
  end 
  line.to_i
end

def get_random_site_url
  random_line = nil
  File.open("#{$domain}/sites") do |file|
    file_lines = file.readlines()
    random_line = file_lines[Random.rand(0...file_lines.size())]
  end 
  random_line
end 

def get_push_method
   rand =  Random.rand(1...8)
   if rand == 1
     push_method="route-email-deliver"
   end
   if rand == 2
     push_method="route-soc-app-point"
   end
   if rand == 3
     push_method="route-web-setbookmark"
   end
   if rand == 4
     push_method="route--sms-rsc-message"
   end
   if rand == 5
     push_method="route-sms-txt-message"
   end
   if rand == 6
     push_method="route-injected-http-flow"
   end
   if rand == 7
     push_method="route-chatbot-generic"
   end
   if rand == 8
     push_method="route-chatbot-chatbot"
   end
   push_method
end

def get_random_page
   rand =  Random.rand(1...6)
   if rand == 1
      random_page="gcp"
   end
   if rand == 2
      random_page="aws"
   end
   if rand == 3
      random_page="azure"
   end
   if rand == 4
      random_page="blog-post-index-page"
   end
   if rand == 5
      random_page="azure"
   end
   if rand == 6
      random_page=""
   end
   random_page
end

def is_ca_pub
    html = @driver.find_element(:tag_name, 'html')
    page = html.attribute("innerHTML")
    return page.match("ca-pub-2815999156088974")
end

def safe_get_url(url)
     log "safe_get_url: url=" + url
     begin
        @driver.get url
        html = @driver.find_element(:tag_name, 'html')
        log "safe_get_url: html retrived size = " + html.attribute("innerHTML").length.to_s
        title=@driver.title
        log "safe_get_url title=" + title
   
        #debug for analyser run in case needed
        #if ($instance.to_i == 20) 
           #log "DEBUG HTML" + html.attribute("innerHTML")
        #end

        # console log disabled, enable for debug 
        #console_log = @driver.manage.logs.get :browser
        #log "safe_get_url: console log="
        #puts console_log
        STDOUT.flush
     rescue => e
        log "safe_get_url: An error of type #{e.class} happened, message is #{e.message}"
        log "safe_get_url: error at driver.get url, ignored"
        if (e.class == Net::ReadTimeout)
           log "safe_get_url timeout count = " + $timeouts.to_s
           $timeouts = $timeouts + 1
           if ($timeouts > 3)
              log "safe_get_url: error exit on too many timeouts"
              teardown
              exit
           end
        end 
     ensure
        log "safe_get_url: exception ensure"
     end
     log "safe_get_url: done."
end

def get_random_site
     log "get_random_site ..."
     url = 'https://' + get_random_site_url()
     log "get_random_site: log get random site url=" + url
     safe_get_url(url)
     log "get_random_site done."
end

def get_location_infonu
     log "get_location_infonu..."
     url=get_random_article
     safe_get_url(url)
     log "get_location_infonu done."
end

def get_location_pubcloudnews
     log "get_location_pubcloudnews..."
     rand = Random.rand(1...1000)
     if (rand <= 100)
        url="https://#{$domain}?src=" + get_push_method
     end
     if (rand > 100 and rand <= 500)
        url="https://#{$domain}/" + get_random_page
     end
     if (rand > 500)
        url="https://#{$domain}/" + get_random_article
     end
     safe_get_url(url)
     log "get_location_pubcloudnews: done."
end

def get_location
   if ($domain == "infonu.nl") 
      location=get_location_infonu
   else
      location=get_location_pubcloudnews
   end
   location
end

def search
  log "search..."
  url = get_random_search
  log "search: doing a get url " + url
  safe_get_url(url)
  randomsleep('search',5,11) # wait for search results to render...
  target=nil
  links = @driver.find_elements(:tag_name, "a")
  links.each {
        |link|
        match_target=link.attribute("href")
        if match_target != nil
           if (match_target.length > 0) && (match_target.match(/^https:\/\/#{$domain}/))
              target=link
	      log "search: match target" + link.to_s
              break
           end
       end

  }
  if target != nil
     #log "search: found:" + target.to_s
     log "search: target found..."
     #log target.attribute("innerHTML")
     log target.attribute("href")
     new_url = target.attribute("href")
     log "search: click on url:" + new_url
     begin
        log "search: click on target.."
        res = @driver.execute_script("return arguments[0].click()" , target) # using JavaScript to workaround intercept errror on target.click()
        log "search: click result=" + res.to_s
        title = @driver.title
        log "search: SEARCH_CLICK_TITLE=" + title
        #disabled to reduce logging, debug only
        #html = @driver.find_element(:tag_name, 'html')
        #log html.attribute("innerHTML")
        rescue => e
           log "search: exception rescue search on target link"
           log "search: an error of type #{e.class} happened, message is #{e.message}"
        ensure
           log "search: click ensure"
        end
  else
     log "search: info could not locate a target link to click on in result, doing a get_location instead"
     get_location
  end
end

# 
# country_ok is false some countries with less optimal outcome / too high latency
# 
def country_ok
  result=true
  result
end

def get_target_links
   log "get_target_links..."
   target_links=[] 
   element_names = [ '//*[@id="aswift_1"]', 
                     '//*[@id="aswift_2"]', 
                     '//*[@id="aswift_3"]', 
                     '//*[@id="aswift_4"]', 
                     '//*[@id="aswift_5"]', 
                     '//*[@id="aswift_6"]', 
                     '//*[@id="aswift_7"]', 
                     '//*[@id="aswift_8"]', 
                     '//*[@id="aswift_9"]', 
                     '//*[@id="aswift_0"]' 
                   ]
   element_names.length.times do |i|
      begin
           element_name = element_names[i]
           log "get_target_links for " + element_name
           iframe = @driver.find_element(:xpath => element_name)
           log "get_target_links: swith to iframe=" + iframe.attribute("id")
           @driver.switch_to.frame iframe
           links = @driver.find_elements(:tag_name, "a") 
           links.length.times do |i|
              l1=links.at(i)
              d1=l1.attribute("data-asoch-targets")
              # TDB added , to filter out ad0 itself seems to error a lot
              if (d1 =~ /ad0,/)
                 log "click ad target found:"  + d1
                 target_links << l1
              end
           end
      rescue => e
           log "get_target_links: exception rescue checker"
           log "get_target_links: an error of type #{e.class} happened, message is #{e.message}"
      ensure
          log "get_target_links: ensure"
      end
   end
   len = target_links.length()
   log "get_target_links: found #{len} targets"
   log "get_target_links done."
   shuffed_target_links=[] 
   shuffed_target_links=target_links.shuffle()
   shuffed_target_links
end

def checker
  log "checker..."
  log "checker ctr="+$ctr.to_s
  randomsleep('checker',7,13) # to render and load page/javascript
  target_links=get_target_links()
  len = target_links.length()
  log "checker: collected #{len} links domain:#{$domain} country:#{$country}"
  rand=Random.rand(1...1000)
  if ((rand < $ctr) or ($instance.to_i == 20)) #CTR minus errors
     log "checker: rand=#{rand} < ctr=#{$ctr} instance=#{$instance}"
     # Multiple attempts to click, stops when it succeeds as it navigates away...
     log "checker: going to click #{len} found targets"
     target_links.each {
        |target_link|
        begin
           d1=target_link.attribute("data-asoch-targets")
           log "checker: target_link.click #{d1}"
           click_result = target_link.click()
           #click_result = @driver.execute_script("return arguments[0].click()" , target_link) # using JavaScript to workaround intercept errror on target.click()
           log "checker: click result:"
           if (click_result)
              log "checker: click result="
              log click_result.to_s
           end
           title = @driver.title
           log "checker: ADVERT_CONVERSION_TITLE=" + title
           if ($instance.to_i == 20)
              html = @driver.find_element(:tag_name, 'html')
              log html.attribute("innerHTML")
           end
           log "checker: click done"
        rescue => e
           log "checker: exception rescue on target link"
           log "checker: an error of type #{e.class} happened, message is #{e.message}"
           # TBD check if bailing works
           if (e.message =~ /stale element reference: element is not attached to the page document/)
              log "checker: bailing loop on StaleElementReferenceError"
              return
           end
        ensure
           log "checker: ensure"
        end
     }
  else
    log "checker: no click conversion for rand=#{rand}."
  end
  log "checker: done."
end

def visitor
  log "visitor..."
  if (Random.rand(1...10)< 6) # 60% direct, 40% trough google search
     if (Random.rand(1...10)< 4) # 40% history
        log "visitor: get a random site to build history/state"
        get_random_site
     end
     log "visitor: get a target site location"
     get_location
  else
     log "visitor: do a search and click on one of the search results, or get_location on no results"
     search
  end
  if ($domain == "infonu.nl")
     if (is_ca_pub())
         log "visitor: publisher ca-pub-2815999156088974 continue..."
     else
        if ($vrecurse < 12) # recursion depth protection
           $vrecurse = $vrecurse + 1
           log "visitor: not publisher ca-pub-2815999156088974 - recurse - #{$vrecurse}"
           visitor
        end
     end
  end
  $vrecurse=0
  log "visitor: done."
end

def runloop
   loopcount = Random.rand(1..6) # increase later to increase session time
   if ($instance.to_i == 20) 
      loopcount=1 
      log "runloop: analyser run"
   end
   log "runloop: with loopcount=" + loopcount.to_s
   loopcount.times do |count|
      log "runloop: run iteration #{count}"
      visitor
      randomsleep('runloop',5,27) # min-max define the session lenght= min-max x loopcount
      if (country_ok())
        log "runloop: country #{$country} ok, checking..."
        checker
     else
        log "runloop: skip checker for #{$country}"
     end
   end
end

def run
  log "run ..."
  port=ARGV[0]
  $instance=ARGV[1]||"1"
  $domain=ARGV[2]||"#{$domain}"
  $country=ARGV[3]||""
  $ctr=get_ctr()
  agent=get_random_agent
  log "run: port="  + port
  log "run: agent=" + agent
  log "run: domain=" + $domain
  log "run: country=" + $country
  log "run: ctr=" + $ctr.to_s
  setup_with_socks_proxy(agent,port)
  runloop
  teardown
  log "run: done."
end

run()

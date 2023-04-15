# Site Test

Site Test is a APR only project for running traffic to a configurable set of domains and traffic.
Site Test is built in Ruby and uses Docker based Selenium headless browser to visit domain sites.
domain sites are mainly worpress based blogs.

config details:
- traffic is randomized per domain based on the [domain]/articles
- agents are randomized per domain based on the [domain]/agents
- traffic volume is managed by number of instances in the domain file and domain/delay
- part of traffic is generated via google search configured in [domain]/search
- ctr is configired in [domain]/ctr (as fraction of 100)
- partial surf history configured in [domain]/sites


## Design and Process Flow

![higl-level-design](https://github.com/aprutgers/site-test/blob/main/site-test-1.jpg?raw=true)

![comm-flow-design](https://github.com/aprutgers/site-test/blob/main/site-test2.jpg?raw=true)

### start / stop
- start with start.sh (has counter for number of runners, relates do domains, max=19)
- stop with stop.sh
- restart with restart.sh

Logging in [/mnt]/tmp - see ramdisk below

### stats
./collect_stats.sh

### crontab 
Crontab has entries for logging and docker prune maintenance as well as emailing daily stats

### analyser runs
Analyser runs make a ctr for a instance==20
```
./ana-runner.sh
```

### domain file

Example:

```
hyperscalercloud.online:,1,
hyperscalercloud.nl:,2,
hypercloudzone.com:,3,
infonu.nl:,4,
pubcloudnews.tech:,5,
pubcloudnews.tech:,20,
hypercloudhub.nl:

```
line must start and end on , for grep to work to distinct 1 and 10, 2 20 and so on
analyser run is integrated in runner.rb with if-then code on $instance, currently instance==20

### using ramdisk /mnt/tmp with service

systemctl enable tmp-ramdisk.service
systemctl start tmp-ramdisk.service
systemctl status tmp-ramdisk.service


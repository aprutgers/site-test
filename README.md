# Site Test

Site Test is a APR private project for running web traffic to a configurable set of domains and traffic.
Site Test is mainly built in Ruby and uses Docker based Selenium headless browser to visit domain sites.
Domain sites are mainly worpress based blogs and have mostly ChatGPT written content.

Config details:
- traffic is randomized per domain based on the [domain]/articles
- agents are randomized per domain based on the [domain]/agents
- traffic volume is managed by number of instances in the domain file and domain/delay
- A part of the traffic is generated via google search configured in [domain]/search
- The ctr% is configured in [domain]/ctr (as fraction of 100 so 18 implies 1.8%)
- browser surf history configured in [domain]/sites

## Design and Process Flow

![higl-level-design](https://github.com/aprutgers/site-test/blob/main/site-test-1.jpg?raw=true)

![comm-flow-design](https://github.com/aprutgers/site-test/blob/main/site-test2.jpg?raw=true)

### Docker Networking

The headless browser selenium is running in a docker contained process and must route its traffic via the 
started psiphon tunnel. In order to achieve this the psiphon tunnel is started with a specific listen interface as follows:

```
psiphon-tunnel-core-x86_64 -listenInterface docker0
```

Additional the address host.docker.internal is used as the proxy address for the headless selenium browser session.

### install
The code is build to get deployed in a fixed /home/ec2-user/site-test directory.

After git clone run:
```
./install.sh
```

### required cache / operational directories

```
mkdir countrycache
mkdir psi
sudo mkdir -p /mnt/tmp
```
- countrycache - stores proxy IP country
- psi - stores state of running psi tunnels
- /mnt/tmp - ram disk, see below

### start / stop
- start with start.sh (start.sh has counter for number of runners, relates do domains, max=19)
- stop with stop.sh
- restart with restart.sh

Logging is sent and rotated to [/mnt]/tmp - see ramdisk below

### statistics
You can collect statistics on the site-test processes using the CLI `./collect_stats.sh`

Also a web verstion is also available as http://192.168.178.91/sitetest.html
The web version is calling sitetest.php, then sitetest.sh and finally sitetest.py.
For this purpose the `collect_stats.sh` script is run in cron and output is saved in `collect_stats.txt` 
which is read by the sitetest.py script to provide data to the statistics web page.

### crontab 
The Linux crontab has entries for logging and docker prune maintenance as well as emailing daily stats.
Also the crontab has an entry to collect the statistics each 15 minutes for the web version.

### analyser runs
Analyser runs make a ctr for a instance==20
```
./ana-runner.sh
```

### domains configuration file

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
A line must start with the domain, then a : and then a , and also end on , for grep to work to distinct 1 and 10, 2 20 and so on
The analyser run is integrated in runner.rb with if-then code on instance number, currently instance==20 is the analyser run.

### analyser run

```
./ana_runner.sh
```

This will run a seperate process and uses instance=20 to seperate it from the running processes.
The runner.rb code has if-then-else code on instane=20 to run in analyse mode which is always triggering a click.
Analyser runs can fail, like no working psiphon tunnel, just re-run.

### using ramdisk /mnt/tmp with service

To reduce SSD disk war, current logging is done in ramdisk mounted as /mnt/tmp

A service has been created to manage ramddisk (doesn't work on boot):
- systemctl enable tmp-ramdisk.service
- systemctl start tmp-ramdisk.service
- systemctl status tmp-ramdisk.service

Alternative just run:
```
mount -t tmpfs -o size=$cap tmpfs /mnt/tmp
```

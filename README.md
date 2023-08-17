# Site Test

Site Test is a APR private project for running web traffic to a configurable set of domains and traffic.
Site Test is mainly built in Ruby and uses Docker based Selenium headless browser to visit domain sites.
Domain sites are mainly worpress based blogs and have mostly ChatGPT written content.

Config details:
- traffic is randomized per domain based on the [domain]/articles
- agents are randomized per domain based on the [domain]/agents
- traffic volume is managed by number of instances in the domain file and domain/delay
- traffic volume is randomized by the waiter.rb and its config in domain/minmax
- A part of the traffic is generated via google search configured in [domain]/search
- The ctr% is configured in [domain]/ctr (as fraction of 100 so 18 implies 1.8%)
- browser history configured in [domain]/sites (20% of hits build history)

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

### required domain config / cache / operational directories

```
tar xvf domainsconfig.tar
mkdir countrycache
mkdir psi
sudo mkdir -p /mnt/tmp
```
- domainsconfig.tar -  ctr, agents, articles, delay, minmax, search, sites config files per domain
- countrycache - stores proxy IP -> country
- psi - stores state of running psi tunnels
- /mnt/tmp - ram disk, see below
- sudo cp sitetest.service /etc/systemd/system
- sudo systemctl enable sitetest.service

### start / stop

- sudo systemctl start | stop sitetest

Alternative without systemd

- start with start.sh (start.sh has counter for number of runners, relates do domains, current max=29)
- stop with stop.sh
- restart with restart.sh

### Traffic volume randomisation

The traffic volume is managed by a randomized traffic volume in a reversed saw-tooth pattern, starting with low traffic, slow increasing to a peak,
and dropping again to the basis. This pattern can be configured per domain. To achieve this for each domain a file called minmax exists which 
configures the initial minimal wait time, maximal wait time, decrease step and chance%.
The config file is a basic ascii file containing each value per line for example:

```
$ cat pubcloudnews.tech/minmax
20
200
5
800
```
This configuration means:
- minimal wait time of 20 seconds assigned when the delay counter drops below step size (5)
- maximal wait time of 200 seconds assinged when the delay counter drops below the mininal wait time (20)
- step size of 5 seconds of decreasing minimal and maximal wait time when chance occurs
- 800/1000 (80%) chance of a decrease between runs

The current counting min-max values are stored in the {domain}/delay and are used to determine the actual delay with a Rand(min..max) ruby function.
The ruby module that implements this algorithem is implemented in `waiter.rb` which is started between `runner.rb` executions.

### logging

Logging is sent and rotated to [/mnt]/tmp - see ramdisk below.
Each runner instance has a seperate log file called `test-runner-instanceN.log` where N is the instance number.
An alias is available in the deployment account called `vlog` that does a tail -f for all thise log files at once:

```
alias vlog='tail -f /mnt/tmp/test-runner-instance*.log'
```

### statistics
You can collect statistics on the site-test processes using the CLI `./collect_stats.sh`

A web verstion is also available as http://192.168.2.15/sitetest.html
The web version is calling sitetest.php, then sitetest.sh and finally sitetest.py.
For this purpose the `collect_stats.sh` script is run in cron and output is saved in `collect_stats.txt` 
which is read by the sitetest.py script to provide data to the statistics web page.

The web version allows changing the ctr per domain as a first start to build a web config front-end.

For history tracking purposes a cron scheduled script called `store-stats-update.sh` stores an end-of-day snapshot
of the collected statistics as ./stats/stats.YYYYMMD, this directory isn't cleaned.

### crontab 
The Linux crontab has entries for logging and docker prune maintenance as well as emailing daily stats.
Also the crontab has an entry to collect the statistics each 15 minutes for the web version.

### domains configuration file

Example:

```
hyperscalercloud.nl:,1,2,3,12,16,
hypercloudzone.com:,4,5,6,13,17,
infonu.nl:,7,11,14,22,
pubcloudnews.tech:,8,9,10,15,18,
hyperscalercloud.online:,19,20,21,
hypercloudhub.nl:,99,
hypercloudzone.com:,30,
hyperscalercloud.nl:,99,
```

A line must start with the domain, then a : and then a , and also end on , for grep to work to distinct 1 and 10, 2 30 and so on
The analyser run is integrated in runner.rb with if-then code on instance number, currently instance==30 is the analyser run.

### analyser run
Analyser runs make a ctr for a instance==30

```
./ana_runner.sh
```

This will run a seperate process and uses instance=30 to seperate it from the running processes.
The runner.rb code has if-then-else code on instane=30 to run in analyse mode which is always triggering a click.
Analyser runs can fail, like no working psiphon tunnel, just re-run.

### debug 
You can increase logging by changing the value of debug=0 to `debug=1` in the `test.sh` file.
debug=1 causes the ruby dbg function to log.

### detect
This is a folder a bit of code to create a detection page which can detect (via javascript) if a page is browsed by a 'headless' browser.
Sitetest does not trigger this detection.

## Storage | Ramdisk | Serial HDD

### using ramdisk /mnt/tmp with service

To reduce internal SSD disk ware(degradation), active logging and /var/lib/docker storage is done in a ramdisk of 3GB (3072MB) mounted as /mnt/tmp

A service has been created to manage ramddisk and works after the se linux was disabled (getenforce shows Disabled)
- systemctl enable tmp-ramdisk.service
- systemctl start tmp-ramdisk.service
- systemctl status tmp-ramdisk.service

Alternative just run:
```
mount -t tmpfs -o size=3072M tmpfs /mnt/tmp
mkdir /mnt/tmp/docker
```

To further reduce SSD disk degradation, the /var/lib/docker directory is symlinked to /mnt/tmp/docker which is a ramdisk
```
cd /var/lib
mv docker docker-
ln -s /mnt/tmp/docker .
```

#### swappiness

As a 3GB ramdisk causes more ram usage, swapping increases in the SSD, hence the swappiness config value is tuned down:

```
sudo sysctl vm.swappiness=5
```

See also https://www.howtogeek.com/449691/what-is-swapiness-on-linux-and-how-to-change-it/

### ALT: using external serial disk for docker - how to (not active for now)

To further reduce SSD disk degradation, the /var/lib/docker directory is symlinked to /docker which is a mountpoint to a external (serial) connected HDD
This HDD has a partition with an ext4 file system and is mounted to /docker from /dev/sdb6 (current serial device name)

#### Add to /etc/fstab

```
# added external platter spinning disk from old laptop to serial bus to host intensive i/o from docker
/dev/sdd6              /docker                 ext4    defaults        0 0
```

Notice: sdb, sdc seem to get mapped to another usb driver due to auto power control, sdd seems one with control=on so always on
seems timing issue what driver (1-13 is the one with control=on for power) is selected when serial device is mapped, see below TODO

READ: https://www.kernel.org/doc/html/v4.13/driver-api/usb/power-management.html

How to check what usb driver was used:

```
# dmesg | grep usb

[182424.754786] usb 1-13: new high-speed USB device number 3 using xhci_hcd
[182424.883381] usb 1-13: New USB device found, idVendor=174c, idProduct=1153, bcdDevice= 1.00
[182424.883393] usb 1-13: New USB device strings: Mfr=2, Product=3, SerialNumber=1
[182424.883398] usb 1-13: Product: USB3.0 to SATA adapter
[182424.883402] usb 1-13: Manufacturer: GODO
[182424.883406] usb 1-13: SerialNumber: 201510000058
```

the usb 1-13 prefix indicates the driver being used and corresponds with the subdir in the `/sys/bus/usb/devices` dir.

```
# cd /sys/bus/usb/devices
# ls

..
1-13  
1-13:1.0 
..

cd 1-13
ls /sys/bus/usb/devices/1-13/power

/sys/bus/usb/devices/1-13/power/control -> on
```

the value on means the usb port won't power down.

for more read: https://www.kernel.org/doc/html/v4.13/driver-api/usb/power-management.html

```
# lsusb -vv
```

shows more details on each usb device

##### Formatting
only small recovery partion6 was used (20GB) for now
```
# mkfs -t ext4 /dev/sdd6
```

##### Symlink (/var/lib/docker -> /docker)
````
systemctl stop docker
cd /var/lib
mv docker docker-
ln -s /docker .
````

##### Mounting
````
mount /dev/sdb6 /docker
````

# Site Test

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


###   domain map
see file domains, line must end on , for grep to work to distinct 1 and 10, 2 20 and so on
analyser run is integrated in runner.rb with if-then code on $instance, currently instance==20

### using ramdisk /mnt/tmp with service

systemctl enable tmp-ramdisk.service
systemctl start tmp-ramdisk.service
systemctl status tmp-ramdisk.service


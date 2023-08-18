#!/bin/sh

# required software Ruby, Docker, bc, and gem selenium-webdriver + rspec
sudo yum -y install ruby
sudo yum -y install docker
sudo yum -y install bc
gem install selenium-webdriver -v 4.1.0
gem install rspec

# systemd 
sudo cp /home/ec2-user/site-test/tmp-ramdisk.service /usr/lib/systemd/system
sudo systemctl enable tmp-ramdisk.service
sudo systemctl start tmp-ramdisk.service

sudo cp /home/ec2-user/site-test/sitetest.service /etc/systemd/system
sudo systemctl enable sitetest.service
#sudo systemctl sitetest.service

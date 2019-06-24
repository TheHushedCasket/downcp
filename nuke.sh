#!/bin/bash

# downcp - The script to uninstall cPanel
# Version ?.?
# Last updated 6/23/2019

# First disable services and remove packages
echo "Stopping cPanel..."
systemctl stop cpanel
systemctl disable cpanel
systemctl stop solr
systemctl disable solr

# Removing cPanel packages
echo "Removing cPanel packages..."
yum -y remove *ea-*
yum -y remove *cpanel*
yum -y erase *cpanel*

# Disable and remove cPanel repos
echo "Removing cPanel repos..."
yum-config-manager --disable EA4
yum-config-manager --disable cPAddons
rm -f /etc/yum.repos.d/cPAddons.repo
rm -f /etc/yum.repos.d/EA4.repo

# Make sure yum is ok
echo "Making sure yum isn't totally busted..."
yum -y clean all
yum -y install yum-utils
package-cleanup --problems
package-cleanup --dupes
package-cleanup --cleandupes --removenewestdupes
rpm --rebuilddb

# Then nuke root crontab, removing cPanel crons
echo "Backing up and removing root crons..."
crontab -l > /root/crons
crontab -u root -r

# Delete cPanel related users
echo "Deleting cPanel related users...";
userdel -r cpanelanalytics
userdel -r solr

# Find all files/folders relating to cPanel and nuke 'em
echo "Nuking cPanel files...";
chattr -a /usr/local/cpanel/logs/*
cd /
find . -type d -name "*cpanel*" -exec rm -rf {} +
cd /
find . -type f -name "*cpanel*" -exec rm -rf {} +

# Remove the systemd service files
echo "Removing systemd service files..."
rm -f /etc/systemd/system/cp*
rm -f /etc/systemd/system/queueprocd.service
rm -f /etc/systemd/system/tailwatchd.service
rm -f /etc/systemd/system/spamd.service
rm -f /etc/systemd/system/cpanalyticsd.service
rm -f /etc/systemd/system/cpanel_dovecot_solr.service
rm -f /etc/systemd/system/cphulk.service

# Also remove them from the different targets
rm -f /etc/systemd/system/*/cp*
rm -f /etc/systemd/system/*/queueprocd.service
rm -f /etc/systemd/system/*/tailwatchd.service
rm -f /etc/systemd/system/*/spamd.service
rm -f /etc/systemd/system/cpanalyticsd.service
rm -f /etc/systemd/system/cpanel_dovecot_solr.service
rm -f /etc/systemd/system/cphulk.service

# Reload systemd daemons and clear failed daemons
echo "Reloading systemd..."
systemctl daemon-reload
systemctl reset-failed

# Reload bind and mysql/mariadb as they may get stopped in this process
echo "Restarting MySQL/MariaDB and bind..."
systemctl restart named
systemctl restart mysql

# Replace ~/.bashrc, ~/.bash_profile, /etc/bashrc and /etc/profile
echo "Replacing bashrcs and profiles..."
wget https://raw.githubusercontent.com/killcpanel/downcp/master/etcbashrc -O /etc/bashrc
wget https://raw.githubusercontent.com/killcpanel/downcp/master/etcprofile -O /etc/profile
wget https://raw.githubusercontent.com/killcpanel/downcp/master/bashrc -O ~/.bashrc
wget https://raw.githubusercontent.com/killcpanel/downcp/master/bash_profile -O ~/.bash_profile

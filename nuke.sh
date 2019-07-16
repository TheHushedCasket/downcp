#!/bin/bash

# downcp - The script to uninstall cPanel
# Version 1.0
# Last updated 6/23/2019

# Some pregame notifications
curl https://raw.githubusercontent.com/killcpanel/downcp/master/files/logo

# First disable services
echo -e "\e[43mStopping cPanel..."
systemctl stop cpanel solr cphulkd cpanel_dovecot_solr cpanalyticsd spamd tailwatchd queueprocd
systemctl disable cpanel solr cphulkd cpanel_dovecot_solr cpanalyticsd spamd tailwatchd queueprocd
systemctl unmask cpanel solr cphulkd cpanel_dovecot_solr cpanalyticsd spam tailwatchd queueprocd

# Removing cPanel packages
echo -e "\e[43mRemoving cPanel packages..."
yum -y remove *ea-*
yum -y remove *cpanel*

# Disable and remove cPanel repos
echo -e "\e[43mRemoving cPanel repos..."
yum-config-manager --disable EA4
yum-config-manager --disable cPAddons
rm -f /etc/yum.repos.d/cPAddons.repo
rm -f /etc/yum.repos.d/EA4.repo

# Make sure yum is ok
echo -e "\e[43mMaking sure yum isn't totally busted..."
yum -y clean all
yum -y install yum-utils
package-cleanup -y --problems
package-cleanup -y --dupes
package-cleanup -y --cleandupes --removenewestdupes
rpm --rebuilddb

# Then nuke root crontab, removing cPanel crons
echo -e "\e[43mBacking up and removing root crons..."
crontab -l > /root/crons
crontab -u root -r

# Delete cPanel related users
echo -e "\e[43mDeleting cPanel related users...";
userdel -r cpanelanalytics
userdel -r solr

# Find all files/folders relating to cPanel and nuke 'em
echo -e "\e[43mNuking cPanel files..."
chattr -i /var/cpanel/analytics/system_id
setfacl -m u:root:rw /var/cpanel/analytics/system_id
chattr -a /usr/local/cpanel/logs/*
cd /
find . -type d -name "*cpanel*" -exec rm -rf {} +
find . -type f -name "*cpanel*" -exec rm -rf {} +

# Remove the systemd service files
echo -e "\e[43mRemoving systemd service files..."
rm -f /etc/systemd/system/cp*
rm -f /etc/systemd/system/queueprocd.service
rm -f /etc/systemd/system/tailwatchd.service
rm -f /etc/systemd/system/spamd.service

# Also remove them from the different targets
rm -f /etc/systemd/system/*/cp*
rm -f /etc/systemd/system/*/queueprocd.service
rm -f /etc/systemd/system/*/tailwatchd.service
rm -f /etc/systemd/system/*/spamd.service

# Reload systemd daemons and clear failed daemons
echo -e "\e[43mReloading systemd..."
systemctl daemon-reload
systemctl reset-failed

# Reload bind and mysql/mariadb as they may get stopped in this process
echo -e "\e[43mRestarting MySQL/MariaDB and bind..."
systemctl restart named
systemctl restart mysql

# Replace ~/.bashrc, ~/.bash_profile, /etc/bashrc and /etc/profile
echo -e "\e[43mReplacing bashrcs and profiles..."
wget https://raw.githubusercontent.com/killcpanel/downcp/master/files/etcbashrc -O /etc/bashrc
wget https://raw.githubusercontent.com/killcpanel/downcp/master/files/etcprofile -O /etc/profile
wget https://raw.githubusercontent.com/killcpanel/downcp/master/files/bashrc -O ~/.bashrc
wget https://raw.githubusercontent.com/killcpanel/downcp/master/files/bash_profile -O ~/.bash_profile

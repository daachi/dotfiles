#!/bin/bash

# derived from:
# Openconnect command-line script for connecting to UCI's VPN servers
# from Debian-Ubuntu-derived Linux distro's.  More info at
#    http://www.socsci.uci.edu/~jstern/uci_vpn_ubuntu/ubuntu-openconnect-uci-instructions.html
#
# This script adapted from David Schneider's great page on github at
#    https://github.com/dnschneid/crouton/wiki/Using-Cisco-AnyConnect-VPN-with-openconnect
# and with help from OIT's Linux OpenConnect instructions at
#    http://www.oit.uci.edu/kb/vpn-linux/
#
# Jeff Stern 
# 10/21/2015

# VPNGRP=UCI
VPNUSER=ajohnston

# =============================================================================
# you shouldn't have to change anything below here
VPNURL=https://vpn.us-east.optoro.io
VPNSCRIPT=/usr/share/vpnc-scripts/vpnc-script

sudo openvpn --mktun --dev tun1 && \
sudo ifconfig tun1 up && \
sudo /usr/sbin/openconnect -s $VPNSCRIPT $VPNURL --user=$VPNUSER --interface=tun1
sudo ifconfig tun1 down

# sudo /usr/sbin/openconnect -s $VPNSCRIPT $VPNURL --user=$VPNUSER --authgroup=$VPNGRP --interface=tun1

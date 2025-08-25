#!/bin/bash

sudo apt install dnsmasq -y

sudo tee /etc/dnsmasq.conf > /dev/null << EOF
server=8.8.8.8
server=1.1.1.1
addn-hosts=/etc/dnsmasq.hosts
EOF

DEFAULT_DOMAIN="lan"
read -p "default domain[$DEFAULT_DOMAIN]: " input_host
DOMAIN="${input_host:-$DEFAULT_DOMAIN}"

DEFAULT_K8DOMAIN="k8cluster"
read -p "default domain[$DEFAULT_K8DOMAIN]: " input_host
K8DOMAIN="${input_host:-$DEFAULT_K8DOMAIN}"

sudo tee /etc/dnsmasq.hosts > /dev/null << EOF
192.168.12.111 zbox.$K8DOMAIN.$DOMAIN zbox.$DOMAIN
192.168.12.111 plex.$DOMAIN jellyfin.$DOMAIN
192.168.12.222 victus.$K8DOMAIN.$DOMAIN victus.$DOMAIN
192.168.12.123 minis.$K8DOMAIN.$DOMAIN minis.$DOMAIN
192.168.12.125 adell.$K8DOMAIN.$DOMAIN adell.$DOMAIN
192.168.12.132 dell.$K8DOMAIN.$DOMAIN dell.$DOMAIN
192.168.12.173 iphone-amit.$DOMAIN
EOF

sudo systemctl restart dnsmasq

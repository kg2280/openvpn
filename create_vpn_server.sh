#!/bin/bash

## Scrip to create an openvpn server
## Coded by: Kevin Gagne
## Date: 21 Sept 2017
##

VPN_NAME=mastervpn

## Check if openvpn is installed.  If not, install it
if [[ `dpkg -s openvpn | grep Status` =~ "Status: install ok installed" ]]
then
  echo "OpenVPN already installed"
else
  echo "Installing OpenVPN"
  apt-get update && apt-get dist-upgrade -y && install openvpn easy-rsa -y
fi

## Create vpn folder and download openvpn_server.conf
mdkir -p /etc/openvpn/$VPN_NAME
git clone 


## Enable ip forward
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

## Create RSA working directory
make-cadir /etc/openvpn/$VPN_NAME/easy-rsa && cd /etc/openvpn/$VPN_NAME/easy-rsa/
ln -s openssl-1.0.0.cnf openssl.cnf

## Setup RSA vars
sed -i 's/export KEY_SIZE=.*/export KEY_SIZE=4096/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars
sed -i 's/export KEY_COUNTRY=.*/export KEY_COUNTRY="CA"/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars
sed -i 's/export KEY_PROVINCE=.*/export KEY_PROVINCE="QC"/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars
sed -i 's/export KEY_CITY=.*/export KEY_CITY="MTL"/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars
sed -i 's/export KEY_ORG=.*/export KEY_ORG="IT"/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars
sed -i 's/export KEY_EMAIL=.*/export KEY_EMAIL="noc@cdmsfirst.com"/g' /etc/openvpn/$VPN_NAME/easy-rsa/vars

## Setup key, cert and dh path in server.conf
sed -i 's|ca /etc/openvpn/mastervpn/easy-rsa/keys/ca.crt|ca /etc/openvpn/$VPN_NAME/easy-rsa/keys/ca.crt|g' /etc/openvpn/$VPN_NAME/openvpn_server.conf
sed -i 's|cert /etc/openvpn/mastervpn/easy-rsa/keys/vpn.crt|cert /etc/openvpn/$VPN_NAME/easy-rsa/keys/vpn.crt|g' /etc/openvpn/$VPN_NAME/openvpn_server.conf
sed -i 's|key /etc/openvpn/mastervpn/easy-rsa/keys/vpn.key|key /etc/openvpn/mastervpn/easy-rsa/keys/vpn.key|g'/etc/openvpn/$VPN_NAME/openvpn_server.conf
sed -i 's|dh /etc/openvpn/mastervpn/easy-rsa/keys/dh4096.pem|dh /etc/openvpn/$VPN_NAME/easy-rsa/keys/dh4096.pem|g' /etc/openvpn/$VPN_NAME/openvpn_server.conf
sed -i 's|tls-auth /etc/openvpn/mastervpn/easy-rsa/keys/ta.key|tls-auth /etc/openvpn/$VPN_NAME/easy-rsa/keys/ta.key|g' /etc/openvpn/$VPN_NAME/openvpn_server.conf

## Source the vars script and delete all key
cd /etc/openvpn/$VPN_NAME/easy-rsa && source ./vars

## Build the keys directory
./clean-all

## Generate Diffie-Hellman
openssl dhparam 4096 > /etc/openvpn/$VPN_NAME/easy-rsa/keys/dh4096.pem

## Generate the HMAC key file
openvpn --genkey --secret /etc/openvpn/$VPN_NAME/easy-rsa/keys/ta.key

## Build CA
./build-ca

## Create server private key
./build-key-server server

## Create openvpn user so that openvpn does not run under root nor nobody
adduser --system --shell /usr/sbin/nologin --no-create-home openvpn_server

## Restart openvpn service
service openvpn restart


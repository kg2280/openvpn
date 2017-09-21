#!/bin/bash

##  This little script will create the file you need to setup a client for this vpn
##  Coded by : Kevin Gagne
##  Date : 28 Sept 2015
##  Coded for : Modulis

RSA_DIR=/etc/openvpn/mastervpn/easy-rsa2

if [ $# != 1 ]
then
  echo
  echo "You need to put the client name as argument"
  echo "Usage: $0 client_name"
  exit 1
fi

cd $RSA_DIR
. ./vars
KEY_CN=$1 ./pkitool --pkcs12 $1


echo """client
tls-client
dev tun
port 9195
proto tcp

remote 199.182.132.7             # VPN server IP : PORT
nobind

#ca /etc/openvpn/ca.crt
#cert /etc/openvpn/$1.crt
#key /etc/openvpn/$1.key
pkcs12 /etc/openvpn/$1.p12

comp-lzo
persist-key
persist-tun
tls-cipher ECDHE-RSA-AES256-GCM-SHA384
cipher AES-256-CBC
auth sha512
tls-auth /etc/openvpn/ta.key 1

status /var/log/openvpn-status.log

verb 3

""" > /tmp/$1.conf

echo """Connect to the new server, with "-A", in ssh client.  You will then need to copy these files to the openvpn server
scp -P 10202 root@199.182.132.7:/tmp/$1.conf /etc/openvpn/
scp -P 10202 root@199.182.132.7:/etc/openvpn/mastervpn/easy-rsa2/keys/$1.p12 /etc/openvpn/
scp -P 10202 root@199.182.132.7:/etc/openvpn/mastervpn/easy-rsa2/keys/ta.key /etc/openvpn/
"""


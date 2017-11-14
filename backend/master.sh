#!/usr/bin/env bash

set -e

echo $(date)>> /tmp/keepalived.log 2>&1
aws ec2 disassociate-address --public-ip EIP>> /tmp/keepalived.log 2>&1
aws ec2 associate-address --public-ip EIP --instance-id INSTANCE_ID>> /tmp/keepalived.log 2>&1

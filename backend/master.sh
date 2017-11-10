#!/usr/bin/env bash

set -e


aws ec2 disassociate-address --public-ip EIP
aws ec2 associate-address --public-ip EIP --instance-id INSTANCE_ID

#!/usr/bin/env bash


echo $(date)>> /tmp/keepalived.log 2>&1

# https://unix.stackexchange.com/questions/82598/how-do-i-write-a-retry-logic-in-script-to-keep-retrying-to-run-it-upto-5-times/82610
n=0
until [ $n -ge 10 ]
do
  timeout 5 aws ec2 associate-address --public-ip EIP --instance-id INSTANCE_ID>> /tmp/keepalived.log 2>&1 && break
  n=$[$n+1]
  sleep 1
done

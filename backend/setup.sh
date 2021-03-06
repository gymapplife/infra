#!/usr/bin/env bash

set -e


if [[ -z "${RDS_PASSWORD}" ]]; then
  echo Missing RDS_PASSWORD
  exit 1
fi

if [[ -z "${RDS_HOSTNAME}" ]]; then
  echo Missing RDS_HOSTNAME
  exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
  echo Missing AWS_ACCESS_KEY_ID
  exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
  echo Missing AWS_SECRET_ACCESS_KEY
  exit 1
fi

if [[ -z "${SRC_IP}" ]]; then
  echo Missing SRC_IP
  exit 1
fi

if [[ -z "${PEER_IP}" ]]; then
  echo Missing PEER_IP
  exit 1
fi

if [[ -z "${EIP}" ]]; then
  echo Missing EIP
  exit 1
fi

if [[ -z "${INSTANCE_ID}" ]]; then
  echo Missing INSTANCE_ID
  exit 1
fi

if [ "$TYPE" != "MASTER" ] && [ "$TYPE" != "BACKUP" ]; then
  echo TYPE must be MASTER or BACKUP
  exit 1
fi


# https://gist.github.com/ndarville/3452907
function django_secret() { python -c "import random,string;print(''.join([random.SystemRandom().choice(\"{}{}{}\".format(string.ascii_letters, string.digits, string.punctuation)) for i in range(63)]).replace('\\'','\\'\"\\'\"\\''))"; }


# Dependencies

sudo add-apt-repository ppa:jonathonf/python-3.6 -y
sudo apt update
sudo apt install python3.6 keepalived git nginx awscli -y

sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

wget https://bootstrap.pypa.io/get-pip.py
sudo python3.6 get-pip.py
rm get-pip.py

sudo pip3.6 install virtualenv


# Git, Django, & Setup

cd /home/ubuntu
rm -rf backend
git clone https://github.com/gymapplife/backend.git
cd backend
./scripts/setup.sh
source venv/bin/activate
cd backend
export DJANGO_DEBUG=TRUE
python manage.py collectstatic


# Systemd

echo DJANGO_DEBUG=FALSE> /home/ubuntu/env
echo RDS_PASSWORD=$RDS_PASSWORD>> /home/ubuntu/env
echo RDS_HOSTNAME=$RDS_HOSTNAME>> /home/ubuntu/env
echo "DJANGO_SECRET_KEY='$(django_secret)'">> /home/ubuntu/env

sudo cp /home/ubuntu/infra/backend/gunicorn.service /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl enable gunicorn


# Nginx

sudo ufw allow 'Nginx Full'

sudo cp /home/ubuntu/infra/backend/nginx /etc/nginx/sites-available/gymapplife
sudo ln -sf /etc/nginx/sites-available/gymapplife /etc/nginx/sites-enabled
sudo rm -rf /etc/nginx/sites-enabled/default
sudo systemctl restart nginx


# AWS

mkdir -p ~/.aws
echo [default]> ~/.aws/config
echo region=us-east-1>> ~/.aws/config

echo [default]> ~/.aws/credentials
echo aws_access_key_id=$AWS_ACCESS_KEY_ID>> ~/.aws/credentials
echo aws_secret_access_key=$AWS_SECRET_ACCESS_KEY>> ~/.aws/credentials

sudo cp -R ~/.aws /root/.


# Keepalived

sudo mkdir -p /etc/keepalived

sudo cp /home/ubuntu/infra/backend/master.sh /etc/keepalived/master.sh
sudo sed -i -e "s/EIP/${EIP}/g" /etc/keepalived/master.sh
sudo sed -i -e "s/INSTANCE_ID/${INSTANCE_ID}/g" /etc/keepalived/master.sh

sudo cp /home/ubuntu/infra/backend/keepalived.conf /etc/keepalived/keepalived.conf
sudo sed -i -e "s/SRC_IP/${SRC_IP}/g" /etc/keepalived/keepalived.conf
sudo sed -i -e "s/PEER_IP/${PEER_IP}/g" /etc/keepalived/keepalived.conf

if [ "$TYPE" = "MASTER" ]; then
  sudo sed -i -e "s/MASTER_OR_BACKUP/MASTER/g" /etc/keepalived/keepalived.conf
  sudo sed -i -e "s/PRIORITY/101/g" /etc/keepalived/keepalived.conf
else
  sudo sed -i -e "s/MASTER_OR_BACKUP/BACKUP/g" /etc/keepalived/keepalived.conf
  sudo sed -i -e "s/PRIORITY/100/g" /etc/keepalived/keepalived.conf
fi

sudo service keepalived restart

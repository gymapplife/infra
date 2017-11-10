#!/usr/bin/env bash

set -e

# Dependencies

sudo add-apt-repository ppa:jonathonf/python-3.6 -y
sudo apt update
sudo apt install python3.6 make git nginx -y

sudo apt dist-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y

wget https://bootstrap.pypa.io/get-pip.py
sudo python3.6 get-pip.py
rm get-pip.py

sudo pip3.6 install virtualenv

# Git, Django, & Setup

git clone https://github.com/gymapplife/backend.git
cd backend
./scripts/setup.sh
source venv/bin/activate
source /home/ubuntu/infra/backend/env
echo $RDS_USERNAME

# Systemd
cp gunicorn.service /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

# Nginx

sudo ufw allow 'Nginx Full'
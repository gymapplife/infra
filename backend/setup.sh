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

sudo cp /home/ubuntu/infra/backend/gunicorn.service /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl enable gunicorn

# Nginx

sudo ufw allow 'Nginx Full'

sudo cp /home/ubuntu/infra/backend/nginx /etc/nginx/sites-available/gymapplife
sudo ln -sf /etc/nginx/sites-available/gymapplife /etc/nginx/sites-enabled
rm -rf /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

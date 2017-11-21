#!/usr/bin/env bash

set -e


# Dependencies

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt install nginx nodejs -y

sudo npm install -g yarn


# Git

cd

rm -rf frontend

git clone https://github.com/gymapplife/frontend.git

cd frontend

git checkout origin/build

# Nginx

sudo rm -f /var/www/html/*

sudo cp -R build/* /var/www/html/.

sudo ufw allow 'Nginx Full'
sudo service nginx restart

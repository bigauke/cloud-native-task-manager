#!/bin/bash
set -e
apt-get update
apt-get install -y nodejs npm git

git clone --branch main https://github.com/profdiegoluispires/task-manager.git /opt/task-manager
cd /opt/task-manager
npm install
nohup npm start -- --port=3000 > /var/log/task-manager.log 2>&1 &
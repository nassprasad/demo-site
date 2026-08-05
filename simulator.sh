#!/bin/bash

###############################################################################
# ChartIQ Simulator Bootstrap Script
# Purpose: Install and Configure ChartIQ Simulator Application
###############################################################################

set -e
set -x

# Log everything
exec > >(tee -a /var/log/simulator-bootstrap.log | logger -t simulator-bootstrap -s 2>/dev/console) 2>&1

echo "==================================================================="
echo "ChartIQ Simulator Bootstrap Started"
echo "Hostname : $(hostname)"
echo "Date     : $(date)"
echo "==================================================================="

###############################################################################
# Install Node.js
###############################################################################

echo "Installing Node.js..."

dnf install -y nodejs awscli

echo "Node Version"
node -v

echo "NPM Version"
npm -v

###############################################################################
# Enable Amazon SSM Agent
###############################################################################

echo "Enabling Amazon SSM Agent..."

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

###############################################################################
# Create Temporary Directory
###############################################################################

echo "Creating temporary directory..."

mkdir -p /temp/assets/application

###############################################################################
# Download Artifacts from S3
###############################################################################

echo "Downloading artifacts from S3..."

aws s3 ls s3://siva-app-artifacts/quotesim/prod/application/ /temp/assets/application

aws s3 sync s3://siva-app-artifacts/quotesim/prod/application/ /temp/assets/application

aws s3 cp s3://siva-app-artifacts/quotesim/prod/quotesim.service.txt /temp/assets/quotesim.service


echo "Downloaded Files"

ls -R /temp/assets

###############################################################################
# Verify Download
###############################################################################

if [ ! -f /temp/assets/application/package.json ]; then
    echo "ERROR : package.json not found."
    exit 1
fi

if [ ! -f /temp/assets/application/DataFeed.js ]; then
    echo "ERROR : DataFeed.js not found."
    exit 1
fi

if [ ! -f /temp/assets/simulator.service ]; then
    echo "ERROR : simulator.service not found."
    exit 1
fi

###############################################################################
# Install systemd Service
###############################################################################

echo "Installing simulator.service..."

mv /temp/assets/quotesim.service.txt /etc/systemd/system/simulator.service

###############################################################################
# Create Application Directory
###############################################################################

echo "Creating Application Directory..."

mkdir -p /opt/simulator

###############################################################################
# Copy Application
###############################################################################

echo "Copying Application..."

cp -a /temp/assets/application/* /opt/simulator/

###############################################################################
# Install Node Modules
###############################################################################

echo "Installing Node.js Dependencies..."

cd /opt/simulator

if [ -f package-lock.json ]; then
    npm ci
else
    npm install
fi

###############################################################################
# Set Permissions
###############################################################################

echo "Setting Permissions..."

chown -R ec2-user:ec2-user /opt/simulator

chmod -R 755 /opt/simulator

###############################################################################
# Reload systemd
###############################################################################

echo "Reloading systemd..."

systemctl daemon-reload

###############################################################################
# Enable Service
###############################################################################

echo "Enabling Simulator Service..."

systemctl enable simulator

###############################################################################
# Start Service
###############################################################################

echo "Starting Simulator Service..."

systemctl start simulator

sleep 5

###############################################################################
# Verify Service
###############################################################################

if systemctl is-active --quiet simulator
then
    echo "Simulator Service Started Successfully."
else
    echo "ERROR : Simulator Service Failed."

    journalctl -u simulator --no-pager -n 100

    exit 1
fi

###############################################################################
# Verify Listening Port
###############################################################################

echo "Checking Listening Port..."

ss -tulpn | grep 9876 || true

###############################################################################
# Bootstrap Complete
###############################################################################

echo
echo "==================================================================="
echo "ChartIQ Simulator Bootstrap Completed Successfully"
echo "Completed Time : $(date)"
echo "==================================================================="

echo
echo "Useful Commands"
echo "---------------"

echo "tail -f /var/log/simulator-bootstrap.log"

echo "cat /var/log/cloud-init-output.log"

echo "systemctl status simulator"

echo "journalctl -u simulator -f"

echo "tail -f /var/log/simulator.log"

echo "ss -tulpn | grep 9876"

echo "cloud-init status --long"

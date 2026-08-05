#!/bin/bash

###############################################################################
# ChartIQ Simulator Bootstrap Script
# Purpose : Install and Configure ChartIQ Simulator
# Platform: Amazon Linux 2023
###############################################################################

set -e
set -x

###############################################################################
# Logging
###############################################################################

exec > >(tee -a /var/log/simulator-bootstrap.log | logger -t simulator-bootstrap -s 2>/dev/console) 2>&1

echo "==================================================================="
echo "ChartIQ Simulator Bootstrap Started"
echo "Hostname : $(hostname)"
echo "Date     : $(date)"
echo "==================================================================="

###############################################################################
# Update Operating System
###############################################################################

echo "Updating Operating System..."

dnf update -y

###############################################################################
# Install Required System Packages
###############################################################################

echo "Installing Required System Packages..."

dnf install -y awscli jq

###############################################################################
# Validate Amazon SSM Agent & install
###############################################################################

echo
echo "Validating Amazon SSM Agent..."

if rpm -q amazon-ssm-agent >/dev/null 2>&1
then

    echo "Amazon SSM Agent already installed."

else

    echo "Installing Amazon SSM Agent..."

    dnf install -y amazon-ssm-agent

fi

###############################################################################
# Enable Amazon SSM Agent
###############################################################################

echo

echo "Enabling Amazon SSM Agent..."

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

sleep 5

echo "Amazon SSM Agent Status"
systemctl status amazon-ssm-agent --no-pager

###############################################################################
# Create Temporary Directory
###############################################################################

echo
echo "Creating Temporary Directory..."

mkdir -p /temp/assets/application

###############################################################################
# Download Artifacts from S3
###############################################################################

echo
echo "Downloading Simulator Artifacts..."

aws s3 ls s3://siva-app-artifacts/quotesim/prod/

aws s3 sync s3://siva-app-artifacts/quotesim/prod/application/ /temp/assets/application/

aws s3 cp s3://siva-app-artifacts/quotesim/prod/quotesim.service /temp/assets/quotesim.service

echo
echo "Downloaded Files"
ls -R /temp/assets

###############################################################################
# Create Application Directory
###############################################################################

echo
echo "Creating Application Directory..."

mkdir -p /opt/chartiq

###############################################################################
# Copy Application
###############################################################################

echo
echo "Copying Application..."

cp -a /temp/assets/application/* /opt/chartiq/

echo

echo "Application Directory"

ls -lah /opt/chartiq


###############################################################################
# Determine Required Node.js Version
###############################################################################

echo
echo "Reading Node.js Engine from package.json..."

PACKAGE_JSON="/opt/chartiq/package.json"

if [ ! -f "${PACKAGE_JSON}" ]
then
    echo "ERROR : package.json not found."
    exit 1
fi

NODE_ENGINE=$(jq -r '.engines.node' "${PACKAGE_JSON}")

echo "Application Node.js Engine : ${NODE_ENGINE}"

###############################################################################
# Select Node.js Version
###############################################################################

case "${NODE_ENGINE}" in
    *24*)
        NODE_VERSION="24"
        ;;
    *22*)
        NODE_VERSION="22"
        ;;
    *)
        echo "ERROR : Unsupported Node.js Engine : ${NODE_ENGINE}"
        exit 1
        ;;
esac

echo "Selected Node.js LTS Version : ${NODE_VERSION}"

###############################################################################
# Install Node.js LTS
###############################################################################

echo
echo "Installing Node.js ${NODE_VERSION} LTS..."

curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -

dnf install -y nodejs

NODEJS=$(node -v)

echo "Installed Node.js Version : ${NODEJS}"

###############################################################################
# Validate npm Installation
###############################################################################

echo
echo "Validating npm Installation..."

if ! command -v npm >/dev/null 2>&1
then
    echo "ERROR : npm is not installed."
    exit 1
fi

echo "Installed npm Version : $(npm -v)"

###############################################################################
# Set Permissions
###############################################################################

echo
echo "Setting Application Permissions..."

chown -R ec2-user:ec2-user /opt/chartiq

chmod -R 755 /opt/chartiq

###############################################################################
# Install Node.js Dependencies
###############################################################################

echo
echo "Installing Node.js Dependencies..."

cd /opt/chartiq

if [ -f package-lock.json ]
then
    echo "package-lock.json found."
    echo "Running npm ci..."

    npm ci

else

    echo "package-lock.json not found."
    echo "Running npm install..."

    npm install

fi

echo
echo "Node.js Dependencies Installed Successfully."

echo
echo "Installed Runtime Versions"

echo "--------------------------"

node -v

npm -v

###############################################################################
# Configure Application to Listen on All Interfaces
###############################################################################

echo
echo "Updating DataFeed.js to listen on 0.0.0.0..."

sed -i 's/"127\.0\.0\.1"/"0.0.0.0"/g' /opt/chartiq/DataFeed.js

echo "Verifying Application Listen Address..."

grep -n "0.0.0.0" /opt/chartiq/DataFeed.js


###############################################################################
# Install simulator.service
###############################################################################

echo
echo "Installing simulator.service..."

mv /temp/assets/quotesim.service /etc/systemd/system/simulator.service

###############################################################################
# Reload systemd
###############################################################################

echo
echo "Reloading systemd..."

systemctl daemon-reload

###############################################################################
# Enable Simulator Service
###############################################################################

echo
echo "Enabling Simulator Service..."

systemctl enable simulator

###############################################################################
# Start Simulator Service
###############################################################################

echo
echo "Starting Simulator Service..."

systemctl restart simulator

sleep 10

###############################################################################
# Verify Simulator Service
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

echo
echo "Checking Listening Port..."

ss -lntp | grep 9876 || {

    echo "ERROR : Simulator is not listening on port 9876"

    exit 1

}

echo
echo "Simulator is listening on port 9876."

###############################################################################
# Verify HTTP Response (Optional)
###############################################################################

echo
echo "Checking Local Connectivity..."

curl -I http://localhost:9876

###############################################################################
# Bootstrap Complete
###############################################################################

echo
echo "==================================================================="
echo "ChartIQ Simulator Bootstrap Completed Successfully"
echo "Completed Time : $(date)"
echo "==================================================================="

###############################################################################
# Useful Commands
###############################################################################

echo
echo "Useful Commands"
echo "---------------"

echo "Bootstrap Log"
echo "tail -f /var/log/simulator-bootstrap.log"

echo
echo "Cloud-init Output"
echo "cat /var/log/cloud-init-output.log"

echo
echo "Simulator Service Status"
echo "systemctl status simulator"

echo
echo "Simulator Logs"
echo "journalctl -u simulator -f"

echo
echo "Listening Port"
echo "ss -lntp | grep 9876"

echo
echo "Running Process"
echo "ps -ef | grep DataFeed"

echo
echo "Node Version"
echo "node -v"

echo
echo "NPM Version"
echo "npm -v"

echo
echo "Cloud-init Status"
echo "cloud-init status --long"

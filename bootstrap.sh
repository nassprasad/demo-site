#!/bin/bash

###############################################################################
# ChartIQ Symbols EC2 Bootstrap Script
# Purpose: Install and Configure ChartIQ Symbols Application
###############################################################################

set -e
set -x

# Log everything
exec > >(tee -a /var/log/chartiq-bootstrap.log | logger -t chartiq-bootstrap -s 2>/dev/console) 2>&1

echo "==================================================================="
echo "ChartIQ Symbols Bootstrap Started"
echo "Hostname : $(hostname)"
echo "Date     : $(date)"
echo "==================================================================="

###############################################################################
# Install Java 8
###############################################################################

echo "Installing Java 8..."
dnf install java-1.8.0-amazon-corretto -y

echo "Java Version"
java -version

###############################################################################
# Install IPTables
###############################################################################

echo "Installing IPTables..."
dnf install iptables iptables-services -y

echo "start IPtables"
systemctl enable iptables

###############################################################################
# Create Temporary Directory
###############################################################################

echo "Creating temporary directory..."
mkdir -p /temp/assets

###############################################################################
# Download Artifacts from S3
###############################################################################

echo "Downloading artifacts from S3..."
sudo aws s3 sync s3://demo-bucket-sbl-servers/assets/ /temp/assets/ 

echo "Downloaded Files"
ls -R /temp/assets

###############################################################################
# Verify Download
###############################################################################

if [ ! -f /temp/assets/symbols.service.txt ]; then
    echo "ERROR : symbols.service.txt not found."
    exit 1
fi

if [ ! -d /temp/assets/application ]; then
    echo "ERROR : Application directory missing."
    exit 1
fi

###############################################################################
# Install systemd Service
###############################################################################

echo "Installing symbols.service..."
mv /temp/assets/symbols.service.txt /etc/systemd/system/symbols.service

###############################################################################
# Create Application Directory
###############################################################################

echo "Creating Application Directory..."
mkdir -p /opt/chartiq

###############################################################################
# Copy Application
###############################################################################

echo "Copying Application..."

cp -a /temp/assets/application/* /opt/chartiq/

###############################################################################
# Set Permissions
###############################################################################

echo "Setting Permissions..."
chown -R ec2-user:ec2-user /opt/chartiq
chmod -R 755 /opt/chartiq
chown ec2-user:ec2-user /etc/systemd/system/symbols.service

###############################################################################
# Reload systemd
###############################################################################

echo "Reloading systemd..."
systemctl daemon-reload

###############################################################################
# Create Latest JAR Symlink
###############################################################################

echo "Finding Latest ChartIQ JAR..."
latest_jar=$(find /opt/chartiq -maxdepth 1 -type f -name "Chiq*.jar" | sort -Vr | head -1)

if [ -z "$latest_jar" ]; then
    echo "ERROR : No ChartIQ JAR found."
    exit 1
fi

echo "Latest JAR : $latest_jar"

ln -sf "$latest_jar" /opt/chartiq/symbols.jar

###############################################################################
# Enable Service
###############################################################################

echo "Enabling Symbols Service..."
systemctl enable symbols

###############################################################################
# Start Service
###############################################################################

echo "Starting Symbols Service..."
systemctl start symbols

sleep 5

###############################################################################
# Verify Service
###############################################################################

if systemctl is-active --quiet symbols
then
    echo "Symbols Service Started Successfully."
else
    echo "ERROR : Symbols Service Failed."

    journalctl -u symbols --no-pager -n 100

    exit 1
fi

###############################################################################
# Enable route_localnet
###############################################################################

echo "Configuring route_localnet..."

IFACE=$(ip route | awk '/default/ {print $5}')

echo "Detected Interface : $IFACE"

echo "net.ipv4.conf.${IFACE}.route_localnet = 1"  > /etc/sysctl.d/99-sysctl.conf

# Reloads and applies all Linux kernel parameters from the system's sysctl configuration files without requiring a reboot
sysctl --system

###############################################################################
# Get Private IP
###############################################################################

# IP=$(hostname -I | awk '{print $1}')
# echo "Private IP : $IP"

###############################################################################
# Get EC2 Private IP (IMDSv2)
###############################################################################

echo "Retrieving EC2 Private IP..."

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
-H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

IP=$(curl -s \
-H "X-aws-ec2-metadata-token: ${TOKEN}" \
http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Private IP : ${IP}"

###############################################################################
# Configure IPTables DNAT
###############################################################################

echo "Configuring IPTables DNAT..."
iptables -t nat -I PREROUTING -p tcp -d ${IP}/32 --dport 8777 -j DNAT --to-destination 127.0.0.1:8777

###############################################################################
# Save IPTables
###############################################################################

echo "Saving IPTables..."

iptables-save > /etc/sysconfig/iptables

systemctl restart iptables

###############################################################################
# Initialize Symbol Database
###############################################################################

echo "Initializing Symbol Database..."

sudo -u ec2-user \
java -jar /opt/chartiq/symbols.jar chiq -b

###############################################################################
# Restart Symbols Service
###############################################################################

echo "Restarting Symbols Service..."

systemctl restart symbols

sleep 5

###############################################################################
# Final Verification
###############################################################################

if systemctl is-active --quiet symbols
then
    echo "Symbols Service Running Successfully."
else
    echo "ERROR : Symbols Service Failed After Restart."

    journalctl -u symbols --no-pager -n 100

    exit 1
fi

###############################################################################
# Bootstrap Complete
###############################################################################

echo
echo "==================================================================="
echo "ChartIQ Symbols Bootstrap Completed Successfully"
echo "Completed Time : $(date)"
echo "==================================================================="

echo
echo "Useful Commands"
echo "---------------"
echo "tail -f /var/log/chartiq-bootstrap.log"
echo "cat /var/log/cloud-init-output.log"
echo "systemctl status symbols"
echo "journalctl -u symbols -f"


###############################################################################
After launching the EC2 instance, use these commands to troubleshoot if needed:
###############################################################################

echo "Your custom bootstrap log"
echo "tail -f /var/log/chartiq-bootstrap.log"

echo "Cloud-init output"
echo "cat /var/log/cloud-init-output.log"

echo "Service status"
echo "systemctl status symbols"

echo "Service logs"
echo "journalctl -u symbols -f"

echo "Cloud-init status"
echo "cloud-init status --long"


###############################################################################


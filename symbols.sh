#!/bin/bash

# Exit if any command fails
set -e

# Print every command (useful for debugging)
set -x

# Log everything to both console and file
exec > >(tee -a /var/log/chartiq-bootstrap.log | logger -t chartiq-bootstrap -s 2>/dev/console) 2>&1

echo "=================================================="
echo "ChartIQ Symbols Bootstrap Started"
echo "Date : $(date)"
echo "Hostname : $(hostname)"
echo "=================================================="


#############################################
# Install Java 8
#############################################
echo "Installing Java 8"
sudo dnf install java-1.8.0-amazon-corretto -y

echo "Java Version:"
java -version


#############################################
# Install IPTables
#############################################
echo "Installing iptables..."
sudo dnf install iptables iptables-services -y
sudo systemctl enable iptables

#############################################
# Download Application
#############################################
echo "Downloading application artifacts..."
sudo mkdir -p /temp/assets

# sudo aws s3 sync s3://cloudengineering-us-east-1/assets/ChartIQ/dev/symbols/  /temp/assets/
sudo aws s3 sync s3://demo-bucket-sbl-servers/assets/  /temp/assets

#############################################
# Install systemd Service
#############################################
echo "Installing symbols.service..."
sudo mv /temp/assets/symbols.service.txt  /etc/systemd/system/symbols.service


#############################################
# Create Application Directory
#############################################
echo "Creating /opt/chartiq..."
sudo mkdir -p /opt/chartiq


#############################################
# Copy Application Files
#############################################
echo "Copying application..."
sudo cp -a /temp/assets/application/* /opt/chartiq/


#############################################
# Permissions
#############################################
sudo chown -R ec2-user:ec2-user /opt/chartiq
sudo chmod -R 755 /opt/chartiq

sudo chown ec2-user:ec2-user /etc/systemd/system/symbols.service

#############################################
# Reload systemd
#############################################
sudo systemctl daemon-reload


#############################################
# Create Latest JAR Symlink
#############################################

if [ -f /opt/chartiq/symbols.jar ]; then
    rm -f /opt/chartiq/symbols.jar
fi

latest_jar=$(ls /opt/chartiq | sort -Vr | grep "^Chiq" | head -1)

echo "Latest Jar : $latest_jar"

ln -s /opt/chartiq/$latest_jar \
/opt/chartiq/symbols.jar

#############################################
# Start Service
#############################################

sudo systemctl enable symbols
sudo systemctl start symbols

sleep 5

sudo systemctl status symbols --no-pager

#############################################
# Enable route_localnet
#############################################

echo "Configuring route_localnet..."

IFACE=$(ip route | awk '/default/ {print $5}')

echo "Detected Interface : $IFACE"

echo "net.ipv4.conf.${IFACE}.route_localnet = 1" \
| sudo tee /etc/sysctl.d/99-sysctl.conf

sudo sysctl --system

#############################################
# Get Private IP
#############################################

IP=$(hostname -I | awk '{print $1}')

echo "Private IP : $IP"

#############################################
# Configure IPTables DNAT
#############################################

sudo iptables -t nat -I PREROUTING \
-p tcp \
-d ${IP}/32 \
--dport 8777 \
-j DNAT \
--to-destination 127.0.0.1:8777

#############################################
# Save IPTables
#############################################

sudo iptables-save > /etc/sysconfig/iptables
sudo systemctl restart iptables

#############################################
# Initialize Symbol Database
#############################################

sudo -u ec2-user \
java -jar /opt/chartiq/symbols.jar chiq -b

#############################################
# Restart Symbols
#############################################

sudo systemctl restart symbols

sleep 5

sudo systemctl status symbols --no-pager

echo "=================================================="
echo "ChartIQ Symbols Bootstrap Completed Successfully"
echo "Completed at : $(date)"
echo "=================================================="

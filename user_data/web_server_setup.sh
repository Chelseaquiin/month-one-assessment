#!/bin/bash

yum update -y
yum install httpd -y

systemctl start httpd
systemctl enable httpd

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

echo "<h1>Web Server Running</h1>" > /var/www/html/index.html
echo "<h2>Instance ID: $INSTANCE_ID</h2>" >> /var/www/html/index.html

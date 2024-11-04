#!/bin/bash
sudo apt-get install nginx -y
echo 'hi planet' > /var/www/html/index.html
sudo systemctl --now enable nginx
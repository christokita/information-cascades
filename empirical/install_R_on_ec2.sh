#!/bin/bash
# install R
yum install -y R
# install RStudio-Server
wget https://download2.rstudio.org/rstudio...
yum install -y --nogpgcheck rstudio-server-rhel-0.99.903-x86_64.rpm
yum install -y curl-devel
# add user
useradd ctokita
echo manuel:testing | chpasswd
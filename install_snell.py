# -*- coding: utf-8 -*-

import os
import subprocess


# Get user input
snell_version = input('Snell Version 3 or 4? (Default: 4): ') or '4'
snell_port = input('Snell Port [1-65535] (Default: 14250): ') or '14250'



# Set paths
CONF = "/etc/snell/snell-server.conf"
SYSTEMD = "/etc/systemd/system/snell.service"
SHADOW = "/etc/systemd/system/shadow-tls.service"

# Stop snell and shadow-tls services
subprocess.run('systemctl stop snell shadow-tls'.split(' '))

# Install unzip
subprocess.run('apt-get install unzip -y'.split(' '))

# Change to the home directory
os.chdir(os.path.expanduser("~"))

# Download snell-server
subprocess.run(["wget", "--no-check-certificate", "-O", "snell.zip", "https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip"])
subprocess.run(["unzip", "-o", "snell.zip"])
os.remove("snell.zip")

# -*- coding: utf-8 -*-

import os
import subprocess


# Set paths
CONF = "/etc/snell/snell-server.conf"
SYSTEMD = "/etc/systemd/system/snell.service"
SHADOW = "/etc/systemd/system/shadow-tls.service"

# Get user input
snell_version = input('Snell Version 3 or 4? (Default: 4): ') or '4'
snell_port = input('Snell Port [1-65535] (Default: 14250): ') or '14250'
snell_psk = input("Snell PSK (Default: Random): ") or os.urandom(16).hex()
shadow_port = input('ShadowTLS Port [1-65535] (Default: 58443): ') or '58443'
shadow_psk = input("ShadowTLS PSK (Default: Random): ") or os.urandom(16).hex()

# Stop snell and shadow-tls services
subprocess.run('systemctl stop snell shadow-tls'.split(' '))

# Install unzip
subprocess.run('apt-get install unzip -y'.split(' '))

# Change to the home directory
os.chdir(os.path.expanduser("~"))

# Download snell-server
if snell_version == '3':
    subprocess.run('wget --no-check-certificate -O snell.zip https://github.com/seedds/Scripts/raw/main/snell-server-v3.0.1-linux-amd64.zip'.split(' '))
else:
    subprocess.run('wget --no-check-certificate -O snell.zip https://github.com/seedds/Scripts/raw/main/snell-server-v4.0.1-linux-amd64.zip'.split(' '))
subprocess.run('unzip -o snell.zip'.split(' '))
os.remove('snell.zip')
subprocess.run('chmod +x snell-server'.split(' '))
subprocess.run('mv -f snell-server /usr/local/bin/'.split(' '))

# Remove existing files
subprocess.run('rm -r /etc/snell'.split(' '))
if os.path.exists(SYSTEMD):
    os.remove(SYSTEMD)
if os.path.exists(SHADOW):
    os.remove(SHADOW)

os.makedirs('/etc/snell/')

with open(CONF, "w") as f:
    f.write('[snell-server]\n')
    f.write(f'listen = 0.0.0.0:{snell_port}\n')
    f.write(f'psk = {snell_psk}\n')

with open(SYSTEMD, "w") as f:
    f.write('[Unit]\n')
    f.write('Description=Snell Proxy Service\n')
    f.write('After=network.target\n\n')
    f.write('[Service]\n')
    f.write('Type=simple\n')
    f.write('LimitNOFILE=32768\n')
    f.write(f'ExecStart=/usr/local/bin/snell-server -c {CONF}\n\n')
    f.write('[Install]\n')
    f.write('WantedBy=multi-user.target\n')

subprocess.run('systemctl enable snell'.split(' '))
subprocess.run('systemctl daemon-reload'.split(' '))
subprocess.run('systemctl start snell'.split(' '))

subprocess.run('wget --no-check-certificate https://github.com/ihciah/shadow-tls/releases/download/v0.2.25/shadow-tls-x86_64-unknown-linux-musl -O /usr/local/bin/shadow-tls'.split(' '))
subprocess.run('chmod +x /usr/local/bin/shadow-tls'.split(' '))

with open(SHADOW, "w") as shadow_file:
    shadow_file.write("[Unit]\n")
    shadow_file.write("Description=Shadow-TLS Server Service\n")
    shadow_file.write("Documentation=man:sstls-server\n")
    shadow_file.write("After=network-online.target\n")
    shadow_file.write("Wants=network-online.target\n\n")
    shadow_file.write("[Service]\n")
    shadow_file.write("Type=simple\n")
    shadow_file.write(f"ExecStart=shadow-tls --v3 server --listen ::0:{shadow_port} --server 127.0.0.1:{snell_port} --tls gateway.icloud.com --password {shadow_psk}\n")
    shadow_file.write("StandardOutput=syslog\n")
    shadow_file.write("StandardError=syslog\n")
    shadow_file.write("SyslogIdentifier=shadow-tls\n\n")
    shadow_file.write("[Install]\n")
    shadow_file.write("WantedBy=multi-user.target\n")

# Enable, reload, and start the shadow-tls service
subprocess.run('systemctl enable shadow-tls.service'.split(' '))
subprocess.run('systemctl daemon-reload'.split(' '))
subprocess.run('systemctl start shadow-tls.service'.split(' '))

# Remove existing cron entry
subprocess.run('rm /var/spool/cron/crontabs/root'.split(' '))

# Add a new cron entry
with open("/var/spool/cron/crontabs/root", "a") as f:
    f.write('0 0 * * * systemctl restart snell shadow-tls')

# Restart the cron service
subprocess.run('systemctl restart cron'.split(' '))

# Get the public IP address using curl and sed
my_ip4 = subprocess.check_output('curl -s checkip.dyndns.org'.split(' ')).decode('utf-8')
my_ip4 = my_ip4.split('Current IP Address: ')[1].split('<')[0].strip()

# Print the configuration
print('=' * 20)
print('[snell]')
print(f'port = {snell_port}')
print(f'psk = {snell_psk}')
print('[shadow-tls]')
print(f'port = {shadow_port}')
print(f'psk = {shadow_psk}')
print(f'snell, {my_ip4}, {shadow_port}, psk={snell_psk}, version={snell_version}, shadow-tls-password={shadow_psk}, shadow-tls-sni=gateway.icloud.com, shadow-tls-version=3')
print('=' * 20)
subprocess.run(''.split(' '))

#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
CONF="/etc/snell/snell-server.conf"
SYSTEMD="/etc/systemd/system/snell.service"
apt-get install unzip -y
cd ~/
wget --no-check-certificate -O snell.zip https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
unzip -o snell.zip
rm -f snell.zip
chmod +x snell-server
mv -f snell-server /usr/local/bin/


echo "Snell Port [1-65535]"
read -p "(Default: 14250):" snell_port
[[ -z "${snell_port}" ]] && snell_port="14250"

echo "Snell PSK"
read -p "(Default: Random):" snell_psk
[[ -z "${snell_psk}" ]] && snell_psk=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

mkdir /etc/snell/
echo "Generating new config..."
echo "[snell-server]" >>${CONF}
echo "listen = 0.0.0.0:${snell_port}" >>${CONF}
echo "psk = ${snell_psk}" >>${CONF}

echo "============================="
echo "[snell-server]"
echo "listen = 0.0.0.0:${snell_port}"
echo "psk = ${snell_psk}"
echo "============================="


echo "Generating new service..."
echo "[Unit]" >>${SYSTEMD}
echo "Description=Snell Proxy Service" >>${SYSTEMD}
echo "After=network.target" >>${SYSTEMD}
echo "" >>${SYSTEMD}
echo "[Service]" >>${SYSTEMD}
echo "Type=simple" >>${SYSTEMD}
echo "LimitNOFILE=32768" >>${SYSTEMD}
echo "ExecStart=/usr/local/bin/snell-server -c /etc/snell/snell-server.conf" >>${SYSTEMD}
echo "" >>${SYSTEMD}
echo "[Install]" >>${SYSTEMD}
echo "WantedBy=multi-user.target" >>${SYSTEMD}
systemctl daemon-reload
systemctl enable snell
systemctl start snell
touch /var/spool/cron/crontabs/root

# reboot at 5:00 everyday.
echo "0 5 * * * /sbin/shutdown -r" >> /var/spool/cron/crontabs/root

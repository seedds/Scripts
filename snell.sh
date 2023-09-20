#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
CONF="/etc/snell/snell-server.conf"
SYSTEMD="/etc/systemd/system/snell.service"
SHADOW="/etc/systemd/system/shadow-tls.service"
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

echo "Shadow Port [1-65535]"
read -p "(Default: 58443):" shadow_port
[[ -z "${shadow_port}" ]] && shadow_port="58443"

echo "Shadow PSK"
read -p "(Default: Random):" shadow_psk
[[ -z "${shadow_psk}" ]] && shadow_psk=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

rm ${CONF}
rm ${SYSTEMD}
rm ${SHADOW}

mkdir /etc/snell/
echo "Generating new config..."
echo "[snell-server]" >>${CONF}
echo "listen = 0.0.0.0:${snell_port}" >>${CONF}
echo "psk = ${snell_psk}" >>${CONF}

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
systemctl enable snell
systemctl daemon-reload
systemctl start snell


wget --no-check-certificate https://github.com/ihciah/shadow-tls/releases/download/v0.2.23/shadow-tls-x86_64-unknown-linux-musl -O /usr/local/bin/shadow-tls
chmod +x /usr/local/bin/shadow-tls
echo "[Unit]" >> ${SHADOW}
echo "Description=Shadow-TLS Server Service" >> ${SHADOW}
echo "Documentation=man:sstls-server" >> ${SHADOW}
echo "After=network-online.target" >> ${SHADOW}
echo "Wants=network-online.target" >> ${SHADOW}
echo "" >> ${SHADOW}
echo "[Service]" >> ${SHADOW}
echo "Type=simple" >> ${SHADOW}
echo "ExecStart=shadow-tls --v3 server --listen ::0:${shadow_port} --server 127.0.0.1:${snell_port} --tls gateway.icloud.com --password ${shadow_psk}" >> ${SHADOW}
echo "StandardOutput=syslog" >> ${SHADOW}
echo "StandardError=syslog" >> ${SHADOW}
echo "SyslogIdentifier=shadow-tls" >> ${SHADOW}
echo "" >> ${SHADOW}
echo "[Install]" >> ${SHADOW}
echo "WantedBy=multi-user.target" >> ${SHADOW}
systemctl enable shadow-tls.service
systemctl daemon-reload
systemctl start shadow-tls.service

# restart service
rm /var/spool/cron/crontabs/root
echo "0 0 * * * systemctl restart snell shadow-tls" >> /var/spool/cron/crontabs/root
systemctl restart cron

ip4 = $(hostname -I)
echo "============================="
echo "[snell]"
echo "port = ${snell_port}"
echo "psk = ${snell_psk}"
echo "[shadow-tls]"
echo "port = ${shadow_port}"
echo "psk = ${shadow_psk}"
echo "snell, $(ip4), ${shadow_port}, psk=${snell_psk}, version=4, shadow-tls-password=${shadow_psk}, shadow-tls-sni=gateway.icloud.com, shadow-tls-version=3"
echo "============================="

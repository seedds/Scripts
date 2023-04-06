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

if [ -f ${CONF} ]; then
  echo -e " \033[1;32m 已安装 \033[0m Snell"

  echo
  echo
  echo

  echo -e  "\033[1;33m Snell 配置 \033[0m"
  echo "============================="
  cat /etc/snell/snell-server.conf
  echo "============================="

  else
    echo -e " \033[1;32m 开始安装 \033[0m Snell"
  if [ -z ${snell_port} ]; then
    echo -e "请输入 Snell 端口 [1-65535]"
    read -e -p "(默认: 14250):" snell_port
    [[ -z "${snell_port}" ]] && snell_port="14250"

		echo "============================="
		echo -e "端口 : \033[43;35m ${snell_port} \033[0m"
		echo "============================="

  else
    echo "============================="
		echo -e "端口 : \033[43;35m 12312 \033[0m"
		echo "============================="
  fi

  if [ -z ${snell_obfs} ]; then
    echo -e "请输入 obfs ( tls / http / off ) "
    read -e -p "(默认: tls):" snell_obfs
    [[ -z "${snell_obfs}" ]] && snell_obfs="tls"

		echo "============================="
		echo -e "obfs : \033[43;35m ${snell_obfs} \033[0m"
		echo "============================="

  else
    echo "============================="
		echo -e "obfs : \033[43;35m tls \033[0m"
		echo "============================="
  fi

  if [ -z ${PSK} ]; then
    PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    echo "随机生成 psk "
    echo "============================="
		echo -e "PSK : \033[43;35m ${PSK} \033[0m"
		echo "============================="

  else

    echo "============================="
    echo -e "PSK : \033[43;35m ${PSK} \033[0m"
    echo "============================="

  fi

  mkdir /etc/snell/
  echo "Generating new config..."
  echo "[snell-server]" >>${CONF}
  echo "listen = 0.0.0.0:${snell_port}" >>${CONF}
  echo "psk = ${PSK}" >>${CONF}
  echo "obfs = ${snell_obfs}" >>${CONF}

  echo
  echo
  echo


  echo -e  "\033[1;33m Snell 配置 \033[0m"
  echo "============================="
  echo "[snell-server]"
  echo "listen = 0.0.0.0:${snell_port}"
  echo "psk = ${PSK}"
  echo "obfs = ${snell_obfs}"
  echo "============================="
fi
if [ -f ${SYSTEMD} ]; then
  echo "Found existing service..."
  systemctl daemon-reload
  systemctl restart snell
else
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
fi

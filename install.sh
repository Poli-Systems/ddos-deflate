#!/bin/sh

# Check if the script is executed as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please execute this script as root."
    exit 1
fi

# Check for required dependencies
if [ -f "/usr/bin/apt-get" ]; then
    install_type='2';
    install_command="apt-get"
elif [ -f "/usr/bin/yum" ]; then
    install_type='3';
    install_command="yum"
elif [ -f "/usr/sbin/pkg" ]; then
    install_type='4';
    install_command="pkg"
else
    install_type='0'
fi

packages='nslookup netstat ss ifconfig tcpdump tcpkill timeout awk sed grep grepcidr'

if  [ "$install_type" = '4' ]; then
    packages="$packages ipfw"
else
    packages="$packages iptables"
fi

for dependency in $packages; do
    is_installed=`which $dependency`
    if [ "$is_installed" = "" ]; then
        echo "error: Required dependency '$dependency' is missing."
        if [ "$install_type" = '0' ]; then
            exit 1
        else
            echo -n "Autoinstall dependencies by '$install_command'? (n to exit) "
        fi
        read install_sign
        if [ "$install_sign" = 'N' -o "$install_sign" = 'n' ]; then
           exit 1
        fi
        eval "$install_command install -y $(grep $dependency config/dependencies.list | awk '{print $'$install_type'}')"
    fi
done

if [ -d "$DESTDIR/usr/local/ddos" ]; then
    echo "Please un-install the previous version first"
    exit 0
else
    mkdir -p "$DESTDIR/usr/local/ddos"
fi

clear

if [ ! -d "$DESTDIR/etc/ddos" ]; then
    mkdir -p "$DESTDIR/etc/ddos"
fi

if [ ! -d "$DESTDIR/var/lib/ddos" ]; then
    mkdir -p "$DESTDIR/var/lib/ddos"
fi

echo; echo 'Installing DOS-Deflate 0.9'; echo

if [ ! -e "$DESTDIR/etc/ddos/ddos.conf" ]; then
    echo -n 'Adding: /etc/ddos/ddos.conf...'
    cp config/ddos.conf "$DESTDIR/etc/ddos/ddos.conf" > /dev/null 2>&1
    echo " (done)"
fi

if [ ! -e "$DESTDIR/etc/ddos/ignore.ip.list" ]; then
    echo -n 'Adding: /etc/ddos/ignore.ip.list...'
    cp config/ignore.ip.list "$DESTDIR/etc/ddos/ignore.ip.list" > /dev/null 2>&1
    echo " (done)"
fi

if [ ! -e "$DESTDIR/etc/ddos/ignore.host.list" ]; then
    echo -n 'Adding: /etc/ddos/ignore.host.list...'
    cp config/ignore.host.list "$DESTDIR/etc/ddos/ignore.host.list" > /dev/null 2>&1
    echo " (done)"
fi

echo -n 'Adding: /usr/local/ddos/LICENSE...'
cp LICENSE "$DESTDIR/usr/local/ddos/LICENSE" > /dev/null 2>&1
echo " (done)"

echo -n 'Adding: /usr/local/ddos/ddos.sh...'
cp src/ddos.sh "$DESTDIR/usr/local/ddos/ddos.sh" > /dev/null 2>&1
chmod 0755 /usr/local/ddos/ddos.sh > /dev/null 2>&1
echo " (done)"

echo -n 'Creating ddos script: /usr/local/sbin/ddos...'
mkdir -p "$DESTDIR/usr/local/sbin/"
echo "#!/bin/sh" > "$DESTDIR/usr/local/sbin/ddos"
echo "/usr/local/ddos/ddos.sh \$@" >> "$DESTDIR/usr/local/sbin/ddos"
chmod 0755 "$DESTDIR/usr/local/sbin/ddos"
echo " (done)"

echo -n 'Adding man page...'
mkdir -p "$DESTDIR/usr/share/man/man1/"
cp man/ddos.1 "$DESTDIR/usr/share/man/man1/ddos.1" > /dev/null 2>&1
chmod 0644 "$DESTDIR/usr/share/man/man1/ddos.1" > /dev/null 2>&1
echo " (done)"

if [ -d /etc/logrotate.d ]; then
    echo -n 'Adding logrotate configuration...'
    mkdir -p "$DESTDIR/etc/logrotate.d/"
    cp src/ddos.logrotate "$DESTDIR/etc/logrotate.d/ddos" > /dev/null 2>&1
    chmod 0644 "$DESTDIR/etc/logrotate.d/ddos"
    echo " (done)"
fi

echo;

if [ -d /etc/newsyslog.conf.d ]; then
    echo -n 'Adding newsyslog configuration...'
    mkdir -p "$DESTDIR/etc/newsyslog.conf.d"
    cp src/ddos.newsyslog "$DESTDIR/etc/newsyslog.conf.d/ddos" > /dev/null 2>&1
    chmod 0644 "$DESTDIR/etc/newsyslog.conf.d/ddos"
    echo " (done)"
fi

if [ -d /lib/systemd/system/apache2.service.d/apache2-systemd.conf ]; then
    echo -n 'Adding apache2 configuration'
    sed -i 's,LogFormat "%h %l %u %t \\"%r\\" %>s %O \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined,LogFormat "%a %l %u %t \\"%r\\" %>s %O \\"%{Referer}i\\" \\"%{User-Agent}i\\"" combined,g' /etc/apache2/apache2.conf 
    for vhost in /etc/apache2/sites-available/*; do
        if ! cat ${vhost} | grep -q 'ErrorLog ${APACHE_LOG_DIR}/error.log' ; then 
            sed -i '/^<\/\VirtualHost>/i ErrorLog ${APACHE_LOG_DIR}/\error.log' ${vhost}
        fi
        echo "$vhost"
        if ! cat ${vhost} | grep -q 'CustomLog ${APACHE_LOG_DIR}/access.log combined' ; then 
            sed -i '/^<\/\VirtualHost>/i CustomLog ${APACHE_LOG_DIR}/access.log combined' ${vhost}
        fi
    done

    a2enmod remoteip

    echo '  RemoteIPHeader CF-Connecting-IP
            RemoteIPTrustedProxy 173.245.48.0/20
            RemoteIPTrustedProxy 103.21.244.0/22
            RemoteIPTrustedProxy 103.22.200.0/22
            RemoteIPTrustedProxy 103.31.4.0/22
            RemoteIPTrustedProxy 141.101.64.0/18
            RemoteIPTrustedProxy 108.162.192.0/18
            RemoteIPTrustedProxy 190.93.240.0/20
            RemoteIPTrustedProxy 188.114.96.0/20
            RemoteIPTrustedProxy 197.234.240.0/22
            RemoteIPTrustedProxy 198.41.128.0/17
            RemoteIPTrustedProxy 162.158.0.0/15
            RemoteIPTrustedProxy 104.16.0.0/12
            RemoteIPTrustedProxy 172.64.0.0/13
            RemoteIPTrustedProxy 131.0.72.0/22
            RemoteIPTrustedProxy 2400:cb00::/32
            RemoteIPTrustedProxy 2606:4700::/32
            RemoteIPTrustedProxy 2803:f800::/32
            RemoteIPTrustedProxy 2405:b500::/32
            RemoteIPTrustedProxy 2405:8100::/32
            RemoteIPTrustedProxy 2a06:98c0::/29
            RemoteIPTrustedProxy 2c0f:f248::/32' > /etc/apache2/conf-available/remoteip.conf
            
    a2enconf remoteip

    if pgrep -x apache2 >/dev/null ; then 
        service apache2 restart
    fi
fi

echo;

if [ -d /lib/systemd/system ]; then
    echo -n 'Setting up systemd service...'
    mkdir -p "$DESTDIR/lib/systemd/system/"
    cp src/ddos.service "$DESTDIR/lib/systemd/system/" > /dev/null 2>&1
    chmod 0755 "$DESTDIR/lib/systemd/system/ddos.service" > /dev/null 2>&1
    echo " (done)"

    # Check if systemctl is installed and activate service
    SYSTEMCTL_PATH=`whereis systemctl`
    if [ "$SYSTEMCTL_PATH" != "systemctl:" ] && [ "$DESTDIR" = "" ]; then
        echo -n "Activating ddos service..."
        systemctl enable ddos > /dev/null 2>&1
        systemctl start ddos > /dev/null 2>&1
        echo " (done)"
    else
        echo "ddos service needs to be manually started... (warning)"
    fi
elif [ -d /etc/init.d ]; then
    echo -n 'Setting up init script...'
    mkdir -p "$DESTDIR/etc/init.d/"
    cp src/ddos.initd "$DESTDIR/etc/init.d/ddos" > /dev/null 2>&1
    chmod 0755 "$DESTDIR/etc/init.d/ddos" > /dev/null 2>&1
    echo " (done)"

    # Check if update-rc is installed and activate service
    UPDATERC_PATH=`whereis update-rc.d`
    if [ "$UPDATERC_PATH" != "update-rc.d:" ] && [ "$DESTDIR" = "" ]; then
        echo -n "Activating ddos service..."
        update-rc.d ddos defaults > /dev/null 2>&1
        service ddos start > /dev/null 2>&1
        echo " (done)"
    else
        echo "ddos service needs to be manually started... (warning)"
    fi
elif [ -d /etc/rc.d ]; then
    echo -n 'Setting up rc script...'
    mkdir -p "$DESTDIR/etc/rc.d/"
    cp src/ddos.rcd "$DESTDIR/etc/rc.d/ddos" > /dev/null 2>&1
    chmod 0755 "$DESTDIR/etc/rc.d/ddos" > /dev/null 2>&1
    echo " (done)"

    # Activate the service
    echo -n "Activating ddos service..."
    echo 'ddos_enable="YES"' >> /etc/rc.conf
    service ddos start > /dev/null 2>&1
    echo " (done)"
elif [ -d /etc/cron.d ] || [ -f /etc/crontab ]; then
    echo -n 'Creating cron to run script every minute...'
    /usr/local/ddos/ddos.sh --cron > /dev/null 2>&1
    echo " (done)"
fi

echo; echo 'Installation has completed!'
echo 'Config files are located at /etc/ddos/'
echo
echo 'Please send in your comments and/or suggestions to:'
echo 'https://github.com/jgmdev/ddos-deflate/issues'
echo

exit 0

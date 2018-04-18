#!/usr/bin/env bash


mkdir -p /app/vendor/stunnel/var/run/stunnel/

echo "$STUNNEL_PSK" > /app/vendor/stunnel/psk

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes
pid = /app/vendor/stunnel/stunnel4.pid
client = yes

ciphers = PSK
psksecrets = /app/vendor/stunnel/psk

delay = yes
retry = yes

TIMEOUTconnect = 5
TIMEOUTbusy = 300
TIMEOUTidle = 172800

EOFEOF


# replace non-breaking space chars with real spaces
# (this often happens when setting the variable in Heroku dashboard)
STUNNEL_URLS=${STUNNEL_URLS// / }
for URL in $STUNNEL_URLS
do

  eval URL_VALUE=\$$URL
  PARTS=$(echo $URL_VALUE | perl -lne 'print "$1 $2 $3 $4 $5 $6 $7" if /^([^:]+):\/\/([^:]+):([^@]+)@(.*?):(.*?)(\/(.*?)(\\?.*))?$/')
  URI=( $PARTS )

  URI_SCHEME=${URI[0]}
  URI_USER=${URI[1]}
  URI_PASS=${URI[2]}
  URI_HOST=${URI[3]}
  URI_PORT=${URI[4]}
  URI_PATH=${URI[5]}

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF

[$URL]
accept = 127.0.0.1:$URI_PORT
EOFEOF

  for SERVER in $STUNNEL_SERVERS
  do
    cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
connect = $SERVER:$URI_PORT
EOFEOF
  done

done

chmod go-rwx /app/vendor/stunnel/*

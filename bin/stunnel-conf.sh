#!/usr/bin/env bash


mkdir -p /app/vendor/stunnel/var/run/stunnel/

echo "$STUNNEL_CERT" > /app/vendor/stunnel/cert.pem
echo "$STUNNEL_CA" > /app/vendor/stunnel/cafile.pem

cat > /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes

pid = /app/vendor/stunnel/stunnel4.pid

cert = /app/vendor/stunnel/cert.pem
cafile = /app/vendor/stunnel/cafile.pem

verify = 2
delay = yes

options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

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

  LOCAL_STUNNEL_PORT=2${URI_PORT}

  echo "Setting ${URL}_STUNNEL config var"
  export ${URL}_STUNNEL=$URI_SCHEME://$URI_USER:$URI_PASS@127.0.0.1:$LOCAL_STUNNEL_PORT

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF

[$URL]
client = yes
accept = 127.0.0.1:$LOCAL_STUNNEL_PORT
connect = $URI_HOST:$URI_PORT
retry = yes
EOFEOF

done

chmod go-rwx /app/vendor/stunnel/*

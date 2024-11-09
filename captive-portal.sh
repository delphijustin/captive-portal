#!/bin/bash
accesstime=$(date)
if [[ -n "$NCAT_REMOTE_ADDR" ]]; then
    # Try using ip neigh first, fallback to arp if it fails
    MAC_ADDRESS=$(ip neigh show "$NCAT_REMOTE_ADDR" | awk '/..:..:..:..:..:../ {print $5}')
    if [[ -z "$MAC_ADDRESS" ]]; then
        MAC_ADDRESS=$(arp -n "$NCAT_REMOTE_ADDR" | awk '/..:..:..:..:..:../ {print $3}')
    fi
fi
if [[ "$1" == "stop" ]]
then
killall ncat
exit 0
fi
if [[ "$1" == "http" ]]
then
touch /etc/captiveportal/log.count
source /etc/captiveportal/log.count
if [[ "$count" == "" ]]
then
count=0
fi
source /etc/captiveportal/config
read -t 7 method query protocol
keepreading=1
count=$(expr $count + 1)
echo "<br><a href=\"javascript:toggleEntry($count)\">$accesstime</a><br>" >> /etc/captiveportal/log.html_
echo "<ul class=\"entry\" id=\"entry$count\">" >> /etc/captiveportal/log.html_
echo "<li>IP Address: $NCAT_REMOTE_ADDR</li>" >> /etc/captiveportal/log.html_
echo "<li>MAC Address: $MAC_ADDRESS</li>" >> /etc/captiveportal/log.html_
echo "<li>Method: $method</li>" >> /etc/captiveportal/log.html_
echo "<li>Query: $query</li>" >> /etc/captiveportal/log.html_
while [[ "$keepreading" == "1" ]]
do
keepreading=0
metas=
if read -t 2 meta; then
keepreading=1
echo -n "<li>" >> /etc/captiveportal/log.html_
echo -n "$meta" >> /etc/captiveportal/log.html_
echo "</li>" >> /etc/captiveportal/log.html_
metas=$metas $meta
fi
done
echo "</ul>" >> /etc/captiveportal/log.html_
cat /etc/captiveportal/logheader.html_  /etc/captiveportal/log.html_  /etc/captiveportal/logfooter.html_ > /etc/captiveportal/log.html
echo "count=$count" > /etc/captiveportal/log.count
echo "# This file keeps track of the number of requests logged" >> /etc/captiveportal/log.count
if [[ "$query" == *".."* ]]
then
echo "HTTP/1.0 403 Forbidden"
echo "Content-type: text/html"
contentLength=$(stat -c%s /etc/captiveportal/forbidden.html)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/forbidden.html
exit 0
fi
echo "HTTP/1.0 200 OK"
if [[ "$query" == "/portallogin/"* ]]
then
echo "Content-type: text/html"
echo ""
if [[ -f "/etc/captiveportal/users" ]]
then
mapfile -t users < /etc/captiveportal/users
for userline in "${users[@]}"; do
if [[ "$query" == *"$userline"* ]]
then
if [[ "$userline" != "" ]]
then
if [[ "$userline" != "#"* ]]
then
echo "$query $MAC_ADDRESS" >> /etc/captiveportal/registered/$NCAT_REMOTE_ADDR
mac-add $MAC_ADDRESS ACCEPT $NCAT_REMOTE_ADDR w
exit 0
fi
fi
fi
done
fi
echo "Bad username,password or feature disabled";
exit 0
fi
if [[ "$query" == *"/jquery"* ]]
then
echo "Content-type: text/javascript"
contentLength=$(stat -c%s /etc/captiveportal/jquery.js)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/jquery.js
exit 0
fi
if [[ "$query" == "/favicon.ico" ]]
then
echo "Content-type: image/x-icon"
contentLength=$(stat -c%s /etc/captiveportal/favicon.ico)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/favicon.ico
exit 0
fi
if [[ "$query" == "/ipinfo.js" ]]
then
echo "Content-type: text/javascript"
echo ""
echo "const MAC_ADDRESS='$MAC_ADDRESS';"
echo "clientip='$NCAT_REMOTE_ADDR';"
echo "portalip=\"$portalip\";"
echo "successurl=\"$redirect\";"
echo 'document.writeln("MAC Address: "+MAC_ADDRESS+" IP Address: "+clientip);'
exit 0
fi
if [[ "$query" == "/logo.gif" ]]
then
echo "Content-type: image/gif"
contentLength=$(stat -c%s /etc/captiveportal/logo.gif)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/logo.gif
exit 0
fi
if [[ "$query" == "/portalhost/"* ]]
then
echo "Content-type: text/plain"
echo ""
touch /etc/captiveportal/hosts.domains
hostquery="${query//\portalhost\//}"
mapfile blacklist < /etc/captiveportal/hosts.domains
for hline in "${blacklist[@]}"; do
if [[ "$hline" == "$hostquery" ]]
then
echo -n "Blocked"
exit 0
fi
done
echo -n "Unblocked"
exit 0
fi
if [[ "$query" == "/games/"* ]]
then
mime=text/html
if [[ -d "/etc/captiveportal$query" ]]
then
echo "Content-type: $mime"
echo ""
echo '<!DOCTYPE html><html><body><ul>'
listing=$(ls "/etc/captiveportal$query" -1)
IFS=$'\n' read -rd '' -a array <<< "$listing"
for filename in "${array[@]}"; do
    echo -n '<li><a href="'
    echo -n "$query/$filename"
    echo -n '">'
   echo -n "$filename"
  echo -n '</a></li>'
echo ""
done
echo '</ul></body></html>'
exit 0
fi
if [[ "$query" == *".js" ]]
then
mime=text/javascript
fi
if [[ "$query" == *".xml" ]]
then
mime=text/xml
fi
if [[ "$query" == *".css" ]]
then
mime=text/css
fi
if [[ "$query" == *".gif" ]]
then
mime=image/gif
fi
if [[ "$query" == *".png" ]]
then
mime=image/png
fi
if [[ "$query" == *".jpg" ]]
then
mime=image/jpeg
fi
echo "Content-type: $mime"
contentLength=$(stat -c%s /etc/captiveportal$query)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal$query
if [[ "$?" != "0" ]]
then
echo '<!doctype html><html><body>Could not access file <b>'
echo "/etc/captiveportal$query"
echo '</b></body></html>'
fi
exit 0
fi
if [[ "$query" == "/agree.js" ]]
then
echo "Content-type: text/javascript"
contentLength=$(stat -c%s /etc/captiveportal/agree.js)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/agree.js
exit 0
fi
if [[ "$query" == "/games.js" ]]
then
echo "Content-type: text/javascript"
contentLength=$(stat -c%s /etc/captiveportal/games.js)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/games.js
exit 0
fi
contentLength=$(stat -c%s /etc/captiveportal/blockpage.html)
echo "Content-type: text/html"
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/blockpage.html
exit 0
fi
if [[ "$features" == *"agreement"* ]]
then
agreeID=$RANDOM$RANDOM$RANDOM$RANDOM$RANDOM
echo "?a=$agreeID" > /etc/captiveportal/users
echo "const agree=\"$agreeID\";" > /etc/captiveportal/agree.js
fi
if [[ "$features" == *"renat"* ]]
then
natinstall service
fi
if [[ "$1" == "httpd" ]]
then
echo "Starting delphijustin Captive-Portal(HTTP daemon)..."
ncat -k -l 80 --sh-exec "captive-portal.sh http"
fi
if [[ "$1" == "httpsd" ]]
then
echo "Starting delphijustin Captive-Portal(HTTPS daemon)..."
ncat --ssl --ssl-cert /etc/captiveportal/cert.pem -k -l 8443 --sh-exec "captive-portal.sh http"
fi

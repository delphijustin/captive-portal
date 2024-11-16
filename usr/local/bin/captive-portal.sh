#!/bin/bash
source /etc/captiveportal/config
accesstime=$(date)
if [[ -n "$NCAT_REMOTE_ADDR" ]]; then
    # Try using ip neigh first, fallback to arp if it fails
    MAC_ADDRESS=$(ip neigh show "$NCAT_REMOTE_ADDR" | awk '/..:..:..:..:..:../ {print $5}')
    if [[ -z "$MAC_ADDRESS" ]]; then
        MAC_ADDRESS=$(arp -n "$NCAT_REMOTE_ADDR" | awk '/..:..:..:..:..:../ {print $3}')
    fi
fi
if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "/?" ]]
then
echo "Usage: $0 [action]"
echo "httpd		Starts the http server daemon"
echo "http test		Tests a http query"
exit 0
fi
if [[ "$1" == "http" ]]
then
touch /etc/captiveportal/log.count
source /etc/captiveportal/log.count
if [[ "$httpcount" == "" ]]
then
count=0
fi
if [[ "$2" == "test" ]]
then
read -p "Enter query: " query
else
read -t 7 method query protocol
fi
keepreading=1
metas=""
httpcount=$(expr $httpcount + 1)
echo "<br><a href=\"javascript:toggleEntry($httpcount)\">$accesstime</a><br>" >> /etc/captiveportal/httplog.html
echo "<ul class=\"entry\" id=\"entry$httpcount\">" >> /etc/captiveportal/httplog.html
echo "<li>IP Address: $NCAT_REMOTE_ADDR</li>" >> /etc/captiveportal/httplog.html
echo "<li>MAC Address: $MAC_ADDRESS</li>" >> /etc/captiveportal/httplog.html
echo "<li>Method: $method</li>" >> /etc/captiveportal/httplog.html
echo "<li>Query: $query</li>" >> /etc/captiveportal/httplog.html
while [[ "$keepreading" == "1" ]]
do
keepreading=0
if read -t 2 meta; then
keepreading=1
echo -n "<li>" >> /etc/captiveportal/httplog.html
echo -n "$meta" >> /etc/captiveportal/httplog.html
echo "</li>" >> /etc/captiveportal/httplog.html
metas=$metas $meta
fi
done
echo "</ul>" >> /etc/captiveportal/httplog.html
echo "httpcount=$httpcount" > /etc/captiveportal/log.count
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
if [[ "$query" == "/success.php?redirect="* ]]
then
echo "Content-type: text/javascript"
echo ""
echo "console.log('captiveportal Internet is still applying settings');"
exit 0
fi
if [[ "$query" == "/portalsuccess/"* || "$query" == *"?portaltrys="* ]]
then
echo "Content-type: text/html"
echo ""
cat <<EOF
<!doctype html>
<html>
<head>
<script src="//$RANDOM$RANDOM$RANDOM$RANDOM.portal.dongwa.xyz/success.php?redirect=$redirect" async></script>
<script src="/captiveportal.js"></script>
<title>Getting you online...</title>
<script>
setInterval(function(){retryInternet();},24000);
</script>
</head>
<body>
<center><p><img src="/logo.gif" height="255px" width="255px"><br>
Getting you online...
</p></center>
</body>
</html>
EOF
exit 0
fi
if [[ "$query" == "/captiveportal.js" ]]
then
contentlength=$(stat -c%s /etc/captiveportal/captiveportal.js)
echo "Content-type: text/javascript"
echo "Content-length: $contentlength"
echo ""
cat /etc/captiveportal/captiveportal.js
exit 0
fi
if [[ "$query" == "/portallogin/"* ]]
then
echo "Content-type: text/html"
echo ""
if [[ -f "/etc/captiveportal/users" ]]
then
mapfile -t users < /etc/captiveportal/users
for userline in "${users[@]}"; do
if [[ "$query" == "/portallogin/$userline" ]]
then
if [[ "$userline" != "" ]]
then
if [[ "$userline" != "#"* ]]
then
echo "<p>Welcome to the $wekcomename network</p>"
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
cat /etc/bind/named.conf.local | grep -q "zone \"$hostquery\""
if [[ $? -eq 0 ]]
then
echo -n "Blocked"
exit 0
fi
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
cat /dev/null > /etc/captiveportal/users
cpuser agree $agreeID
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

#!/bin/bash
if [[ "$1" == "stop" ]]
then
killall ncat
exit 0
fi
if [[ "$1" == "http" ]]
then
source /etc/captiveportal/config
read method query protocol
accesstime=$(date)
echo "[$accesstime] $NCAT_REMOTE_ADDR $method $query $protocol" >> /etc/captiveportal/query.log
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
arpinfo=$(arp | grep "$NCAT_REMOTE_ADDR")
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
echo "document.writeln(\"$arpinfo\");"
echo "const portalip=\"$portalip\";"
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
if [[ "$query" == "/null.gif" ]]
then
echo "Content-type: image/gif"
contentLength=$(stat -c%s /etc/captiveportal/null.gif)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/null.gif
exit 0
fi
if [[ "$query" == "/log/"* ]]
then
echo "Content-type: image/gif"
contentLength=$(stat -c%s /etc/captiveportal/null.gif)
echo "Content-length: $contentLength"
echo ""
cat /etc/captiveportal/null.gif
exit 0
fi
if [[ "$query" == "/games/"* ]]
then
mime=text/html
if [[ -d "/etc/captiveportal$query" ]]
then
echo "Content-type: $mime"
echo ""
echo "<!DOCTYPE html><html><body><ul>"
listing=$(ls "/etc/captiveportal$query" -1)
IFS=$'\n' read -rd '' -a array <<< "$listing"
for filename in "${array[@]}"; do
    echo "<li><a href=\"$filename\">$filename</a></li>"
done
echo "</ul></body></html>"
exit 0
fi
if [[ "$query" == *".js" ]]
then
mime=text/javascript
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
contentLength=$(stat-c%s /etc/captiveportal$query)
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
echo "Starting delphijustin Captive-Portal..."
if [[ "$1" != "yeshup" ]]
then
nohup ncat -k -l 80 --sh-exec "captive-portal.sh http" &
else
ncat -k -l 80 --sh-exec "captive-portal.sh http"
fi

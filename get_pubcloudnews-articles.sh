wget -q -O - https://pubcloudnews.tech/feed/ | grep '<link>' | sed 's/<[\/]*link>//g' | sed 's/https\:\/\/pubcloudnews.tech\///' | sed 's/^[\s\t]*//'|grep -v ^http

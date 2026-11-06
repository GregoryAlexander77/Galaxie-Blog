#!/bin/sh
# Galaxie Blog on Lucee: start Tomcat on the same port inside the container as outside (BLOG_PORT, default 8888).
# Galaxie's scheduled tasks (scheduled posts, booking reminders) call the blog at its own address, http://localhost:BLOG_PORT;
# inside the container that address must reach Lucee too, or the tasks fail without a word.
PORT="${BLOG_PORT:-8888}"
# The first time, the blog's volume is empty: put the blog built into the image there (later updates: galaxie-update).
if [ ! -f /var/www/Application.cfc ]; then
	cp -a /opt/galaxie/. /var/www/
fi
sed -i "s/port=\"[0-9]*\" protocol=\"HTTP\/1.1\"/port=\"$PORT\" protocol=\"HTTP\/1.1\"/" /usr/local/tomcat/conf/server.xml
exec catalina.sh run

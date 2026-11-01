#!/bin/sh
# Galaxie Blog on Lucee: start Tomcat on the same port inside the container as outside (BLOG_PORT, default 8888).
# Galaxie's scheduled tasks (scheduled posts, booking reminders) call the blog at its own address, http://localhost:BLOG_PORT;
# inside the container that address must reach Lucee too, or the tasks fail without a word.
PORT="${BLOG_PORT:-8888}"
sed -i "s/port=\"[0-9]*\" protocol=\"HTTP\/1.1\"/port=\"$PORT\" protocol=\"HTTP\/1.1\"/" /usr/local/tomcat/conf/server.xml
exec catalina.sh run

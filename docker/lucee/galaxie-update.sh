#!/bin/sh
# Galaxie Blog on Lucee: copy the version of the blog built into this image (/opt/galaxie) over the running blog (/var/www).
# Run it after "docker compose up -d --build" with the new files:   docker compose exec lucee galaxie-update
# Keeps the blog's own settings (org/camden/blog/blog.ini.cfm), uploads and the cache; the database is updated afterwards
# in the blog (reinit, then Update the database), as on any Galaxie server.
set -e
tar -C /opt/galaxie --exclude=./org/camden/blog/blog.ini.cfm -cf - . | tar -C /var/www -xf -
echo "Galaxie files updated. Now reinit the blog (?reinit=1) and press Update the database in the administrative site."

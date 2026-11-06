# Galaxie Blog on Lucee (2026-11-01). Built by docker-compose.yml in the repository root.
ARG LUCEE_IMAGE=lucee/lucee:7.1
FROM ${LUCEE_IMAGE}

# The server settings: the "galaxie" datasource (MariaDB, from the DB_* variables) and the mail server (the Mailpit container).
COPY docker/lucee/.CFConfig.json /opt/lucee/server/lucee-server/context/.CFConfig.json
# Starts Tomcat on BLOG_PORT, the port the blog has outside the container too, and puts the blog in place the first time.
COPY docker/lucee/start.sh /usr/local/bin/galaxie-start.sh
# Copies a new version of the blog over the installed one (see "Updating" in DOCKER.md).
COPY docker/lucee/galaxie-update.sh /usr/local/bin/galaxie-update
RUN chmod 755 /usr/local/bin/galaxie-start.sh /usr/local/bin/galaxie-update

# The blog itself, kept in the image as it was released. .dockerignore leaves out Git, .env and the Docker files.
# The blog runs from /var/www, a volume: start.sh copies these files there the first time, and galaxie-update copies
# them again after an update. The volume keeps uploads, the cache and blog.ini.cfm when the image is rebuilt.
COPY . /opt/galaxie/

# The docker folder came along with the files; its settings file is already in place above.
RUN rm -rf /opt/galaxie/docker \
	&& mkdir -p /opt/galaxie/cache /opt/galaxie/enclosures \
	&& chmod -R u+rwX,go+rX /opt/galaxie

EXPOSE 8888
CMD ["/usr/local/bin/galaxie-start.sh"]

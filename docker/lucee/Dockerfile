# Galaxie Blog on Lucee (2026-11-01). Built by docker-compose.yml in the repository root.
ARG LUCEE_IMAGE=lucee/lucee:7.1
FROM ${LUCEE_IMAGE}

# The server settings: the "galaxie" datasource (MariaDB, from the DB_* variables) and the mail server (the Mailpit container).
COPY docker/lucee/.CFConfig.json /opt/lucee/server/lucee-server/context/.CFConfig.json
# Starts Tomcat on BLOG_PORT, the port the blog has outside the container too.
COPY docker/lucee/start.sh /usr/local/bin/galaxie-start.sh
RUN chmod 755 /usr/local/bin/galaxie-start.sh

# The blog itself, in Lucee's web root. .dockerignore leaves out Git and the Docker files.
COPY . /var/www/

# The blog writes uploads, card and WebP copies, its cache and blog.ini.cfm.
# The docker folder came along with the files; its settings file is already in place above.
RUN rm -rf /var/www/docker \
	&& mkdir -p /var/www/cache /var/www/enclosures \
	&& chmod -R u+rwX,go+rX /var/www

EXPOSE 8888
CMD ["/usr/local/bin/galaxie-start.sh"]

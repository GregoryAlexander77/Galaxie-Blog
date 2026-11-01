# Galaxie Blog in Docker (Lucee and MariaDB)

Try Galaxie Blog on your own computer with one command. This runs three containers:

- **lucee**: Galaxie Blog on Lucee, at http://localhost:8888
- **db**: MariaDB, with an empty database for the blog
- **mail**: Mailpit, which catches every email the blog sends. Read them at http://localhost:8025. Nothing is sent to the real world.

You need [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows or Mac) or Docker Engine (Linux).

## Start

1. Copy `.env.example` to `.env` and change the two passwords.
2. Run:

   ```
   docker compose up -d --build
   ```

   The first start takes a few minutes: Docker downloads the images, and Lucee installs its MariaDB driver and ORM extensions.
3. Open http://localhost:8888. The Galaxie installer starts. Under **Database**:
   * **Datasource:** `galaxie` (it is already set up for you)
   * **Database:** MySQL or MariaDB

   Press **Check the connection**, then finish the installer and the Site Wizard.
4. In the administrative site, under **Blog Settings**, set the mail server to `mail` and the port to `1025` so the blog's emails go to Mailpit.

## Stop and start again

```
docker compose stop
docker compose start
```

Your posts, uploads and settings are kept in two Docker volumes: the database and the blog's files.

## Start over from scratch

This deletes the blog, its database and its uploads:

```
docker compose down -v
```

## Updating to a new version of Galaxie

The blog's files live in a volume, so a new download doesn't replace them by itself; that keeps your uploads and `blog.ini.cfm`. Update the way any Galaxie blog is updated (see [UPGRADING.md](UPGRADING.md)): copy the new files into the running container, leaving out `blog.ini.cfm`, then reinit and press **Update the database**.

## Notes

- **The Lucee version** is set by `LUCEE_IMAGE` in `.env` (default `lucee/lucee:7.1`).
- **The Lucee administrator** is at http://localhost:8888/lucee/admin/server.cfm. Set its password the first time you open it. This setup is for trying Galaxie on your own computer. For a public server, put a web server with HTTPS in front of it and keep the Lucee administrator closed to the outside.
- **Another port.** If 8888 is taken on your computer, set `BLOG_PORT` in `.env` (for example `BLOG_PORT=8890`) before you run the installer. Lucee then listens on that port inside the container too, because scheduled posts and booking reminders call the blog at its own address, `http://localhost:BLOG_PORT`. If you change the port after installing, also change the blog's address in Blog Settings.
- **Memory.** Lucee gets 1 GB by default. Change it with `LUCEE_JAVA_OPTS` in `.env`, for example `LUCEE_JAVA_OPTS=-Xms256m -Xmx2048m`.

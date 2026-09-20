# Updating Galaxie Blog

This page explains how to update an existing Galaxie Blog to the current version (4.66). It works for any older version, including 4.32 and 4.5. A 4.32 blog can go straight to 4.66 in one step: the update runs every database change that is missing, in order, and it is safe to run more than once.

You do not need to run the installer again, and your posts, comments, users, settings and `blog.ini.cfm` are kept.

## Before you start

1. **Back up your database.**
2. **Back up the `org/camden/blog/blog.ini.cfm` file** (the folder is `/org/camden/blog/`). It holds your datasource name and settings. Never overwrite it with a file from the download, the download does not have one.
3. Make sure that your database user can create and alter tables. The update adds columns and tables.

## Updating

1. **Upload the new files** over the old ones, all of them, and keep your `blog.ini.cfm`. Do not upload only some of the folders, 4.66 changed files in many places.
2. **Delete these two files** if they are still there (they are not used any more, and the update also removes them):
   * `/admin/Application.cfc`
   * `/admin/ApplicationProxyReference.cfc`
3. **Restart the blog** by opening the home page with `?reinit=1` at the end, for example `https://yourdomain.com/blog/?reinit=1`.
   * A blog that is still on an old database shows a short page that says *This site is being updated*. That is expected: visitors get that page instead of errors until the database is updated.
   * Open the home page (not the administrative site) first. The very first request after uploading starts the application, and a request to `/admin/` that arrives before that can show an error such as "application not initialized". Just reload after the home page loaded.
4. **Log in to the administrative site** (`/admin/`). When the database needs to be updated you are taken to the **Update the database** page. It shows the version of your files and of your database, and lists the updates that will run.
5. Press **Update the database** and wait until it says that it is done (it takes a few seconds, sometimes a minute).
6. Open the site and check it. You can use the **Refresh Site** button in the administrative site once, to be sure that every cached page is rebuilt. If the image dialog of the post editor looks like the old one, do a hard reload of the browser (Ctrl+F5), some of the TinyMCE files changed.

After this, the **Blog Updates** window of the administrative site shows when a new version is available and has the same Update the database button for future updates.

## What is changed for you

* The database is updated with what the versions in between added: missing fonts and themes, map providers and map types, marking your existing entries as blog posts (not pages), and the visitor log options. Tables and columns that the new version needs are created when the blog starts.
* Files that are no longer used, from all of the versions in between, are deleted by the update.
* The columns that hold long text (posts, comments) are set up automatically for the database type that the installer saved in `blog.ini.cfm`. The old manual step of copying database specific ORM files is gone.
* The datasource is read from `blog.ini.cfm`. On Lucee you do not need to create a datasource with a special name, and you can run several blogs on one server, each in its own folder with its own `blog.ini.cfm`.

## If something goes wrong

* **A blank page or an error after uploading the files:** you probably skipped step 3. Open `/?reinit=1` of the blog and try again.
* **The update page says that the blog has not finished starting:** open the home page once and reload the update page.
* **The update stops with an error:** the result window shows the step that failed. Nothing is deleted by the update except the unused files. Fix the problem (for example the database permissions) and press the button again, updates that were done are skipped.
* **You want to go back:** restore the database from your backup and upload the old files again.

Questions and problems are welcome at https://www.gregoryalexander.com/blog/.

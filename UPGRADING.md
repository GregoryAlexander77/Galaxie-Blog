# Updating Galaxie Blog

This page explains how to update an existing Galaxie Blog to the current version (4.66). It works for any older version, including 4.32 and 4.5. A 4.32 blog can go straight to 4.66 in one step: the update runs every database change that is missing, in order, and it is safe to run more than once.

You do not need to run the installer again, and your posts, comments, users, settings and `blog.ini.cfm` are kept.

## Before you start

1. **Back up your database.**
2. **Back up the `org/camden/blog/blog.ini.cfm` file** (the folder is `/org/camden/blog/`). It holds your datasource name and settings. The download contains an empty starter file with the same name. **Never upload it over your own**, or the blog forgets its settings and starts the installer again. If you upload the whole download, leave that file out.
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

## Tips for uploading the files

Most problems with an update come from the upload, not from the blog. These are the things that we have seen.

* **Upload into the right folder.** The files go directly into the folder that holds `Application.cfc` and `index.cfm`, or into the folder named `blog` if that is where you installed the blog. Do not extract an archive inside of the blog folder if the archive already starts with a `blog` folder, or you get a second folder, `blog/blog`, and the blog will find the incomplete copy there. If that happened, delete the extra folder, and then clear the caches of your server (see below).
* **Some servers do not let you overwrite a file that is already there.** The upload of that file fails with 'Access denied' or 'Permission denied', and it can work when you try again. When it keeps failing, delete the file on the server first (with your hosting control panel's file manager), and then upload it again.
* **Do not trust an FTP program that says 'same' or 'not transferred'.** Some programs (Dreamweaver, for example) remember what they uploaded before, and skip a file that they believe is already on the server, even when it is not, or when it is an old version. Use the program's **Put** command on the files or folders to force the upload, or use the file manager of your hosting control panel. Afterwards, look at the size of a few files on the server (the file manager shows it) and compare it with the size on your computer.
* **On Linux, upper and lower case letters count.** `latestVersionCheck.cfm` and `latestversioncheck.cfm` are two different files. Use the names exactly as they are in the download, and never rename a file to lower case, or let a program do it for you.
* **Do not upload `org/camden/blog/blog.ini.cfm`.** The download has an empty starter copy of it, and your own copy holds your settings. Uploading the starter over yours makes the blog start the installer again.
* **Upload everything.** Version 4.66 changed files in many places (the entities in `common/cfc/db/galaxieDb`, the templates, the libraries, the installer). If you only upload some of the files, the blog can start with a mix of old and new files, and stops with errors such as a field or a function that 'does not exist'. When you see an error like that, a file in that area is still the old version.
* **Restart, or clear the caches, after moving or deleting files.** ColdFusion and Lucee remember where they found a component, and the database mapping (the entities) is read when the application starts. After you fix files on the server, restart the ColdFusion or Lucee service (or ask your host to), or at least clear the template cache in the administrator, and open `/?reinit=1` after you signed in.
* **See the real error.** While the blog is starting, the error page only says that an error occurred. Add `?startupDebug=1` to the address (for example `https://yourdomain.com/?startupDebug=1`) and the real error is shown. It is also written to a log file named `galaxieBlogErrors.log` in the logs folder of ColdFusion or Lucee. Please include that message when you ask for help.

## If something goes wrong

* **A blank page or an error after uploading the files:** you probably skipped step 3. Open `/?reinit=1` of the blog and try again.
* **The update page says that the blog has not finished starting:** open the home page once and reload the update page.
* **The update stops with an error:** the result window shows the step that failed. Nothing is deleted by the update except the unused files. Fix the problem (for example the database permissions) and press the button again, updates that were done are skipped.
* **You want to go back:** restore the database from your backup and upload the old files again.

Questions and problems are welcome at https://www.gregoryalexander.com/blog/.

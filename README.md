
# Galaxie Blog
Galaxie Blog is intended to be the most beautiful and functional free, open-source ColdFusion-based blog in the world. While it can’t go toe-to-toe with Wordpress functionality, I believe that Galaxie Blog competes with Wordpress in core blogging functionality, especially with its abundant theme-related features and support for various rich media.

## Documentation

The Galaxie Blog documentation is at https://www.galaxieblog.org. Gregory's Blog (https://www.gregoryalexander.com/blog) runs on the same codebase found here, and many of its how-to articles discuss how we have implemented some of the logic.

## Installation

You must have a ColdFusion installed on a server.
Your web server must have ColdFusion installed. Galaxie Blog 5.0 has been tested on Adobe ColdFusion 2023 and 2025, and on Lucee 6 and 7. Earlier versions were tested on ColdFusion 2016, 2018 and 2021.

Theoretically, the blog may support any ColdFusion edition starting from ColdFusion 9. However, your mileage may vary.
We have successfully tested using Apache, TomCat and IIS.
Galaxie Blog runs on Lucee, the open-source CFML engine, as well as on Adobe ColdFusion. https://www.galaxieblog.org runs on Lucee with MariaDB.

Many ISPs offer ColdFusion servers for as low as 12 dollars a month. I use Media3.net, and they have been terrific. You can find out more by searching the web for ColdFusion hosting.

1. Galaxie Blog can be downloaded from the Galaxie Blog Git Hub Repository.

2.  Once downloaded, upload the entire contents into your desired location on a web server
- You can install the contents in the root or in a folder in the root directory of your server.
- We have tested the blog in the root, and in 'blog' and 'galaxie' folders.

3. Create the database to install Galaxie Blog in.

The blog uses Hibernate ORM and was designed to support the following databases; however, we have only tested the blog using SQL Server and MySQL/MariaDB:
- Microsoft SQL Server
- DB2
- DB2AS400
- DB2OS390
- Derby
- Informix
- MySQL
- MySQLwithInnoDB
- MySQLwithMyISAM
- Oracle8i
- Oracle9i
- Oracle10g
- PostgreSQL
- Sybase
- SybaseAnywhere

Create a **new, empty** database for the blog. The installer only installs into an empty database: it checks the datasource that you enter and stops if the database already contains a Galaxie Blog, so that it can never overwrite an existing blog. Use a database name made of letters and numbers (no dots).

4. Create a datasource for the new database in the ColdFusion (or Lucee) administrator, and make sure that it verifies. The installer asks for its name and checks that it exists and connects before going on.
5. Enable Woff and Woff2 Font Support on the Webserver
Galaxie Blog uses web fonts for typography and needs web font mime types set up on the web server. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. If the server does not support these mime types certain textual elements will not be displayed. 

- .woff (use font/woff as the mime type).
- .woff2 (use font/woff2 as the mime type).

6. Installing the software

- Migrate to the URL of your uploaded blog, and the blog should automatically open the installer. For example, if you uploaded the files to the root directory, go to http://yourdomain.com/.
- If you uploaded to a blog directory in your root, go to http://yourdomain.com/blog/, etc.
- The installer will guide you and ask you to enter information, such as your URL, blog name, and other information. 
The installer has four short steps: your site, the database, your account, and Install. It should not take more than five minutes. Afterwards the Site Wizard opens to help you make the site your own.
Be sure to write down your chosen user name and password. You will need to retain this information. Galaxie Blog does not retain passwords—they are hashed using the strongest publicly available encryption process and cannot be recovered.
- Once you are done, the installer will automatically create the database and import the needed data. The final step may take a while for the software to be installed. If there is a time-out error, refresh the browser, and the installation should continue.
- If you get **File not found: /index.cfm** right after uploading (most often when you replace a site's files in the same folder, as for a reinstall), ColdFusion is still using its template cache from the old files. This happens when *Trusted Cache* is on. In the ColdFusion administrator, open Server Settings, Caching, and press **Clear Template Cache Now** (or restart ColdFusion), then reload the page. Lucee: Settings, Performance/Caching, clear the template cache.
- If the blog shows *This site is not available right now* while it starts, the reason is written to the `galaxieBlogStartup.log` file in the logs folder of ColdFusion or Lucee, and is shown when you add `?startupDebug=1` to the address.

7. Once installed, you should see your new blog with a 'No Entries' message on the front page. You will not see any blog posts until you make them using the administrative site; see below.
8. Check the blog's email address. The Site Wizard's first screen fills it in with your own email; if you skipped it, open Blog Settings and fill in the Blog Email Address. The blog sends no email until it is filled in (member sign-in links, comment notices, subscriber email and error summaries). If you leave the Mail Server empty, the blog uses the mail server set in the ColdFusion or Lucee administrator.
    
## What's new in 5.01

A small update to 5.0, mostly fixes. Update from 5.0 as usual (see [UPGRADING.md](UPGRADING.md)), then **run the card tool once** (below).

- **Card pictures are small again.** Cards on the home page and in collections no longer load the full-size upload: each picture gets a 640px card copy in `/enclosures/cards/` (WebP where the server can write it, JPG on ColdFusion 2023). New uploads get theirs by themselves. For the pictures you already have, sign in and open `/common/cfc/TestUtility.cfc?method=makeCardImages&confirm=true` once (run it again if it says there are more), then reinit.
- **Share pictures** (Facebook, LinkedIn, X) use the JPG or PNG copy before the WebP one, and say their size.
- **Export to Excel** on the Error Log, Visitor Log, Subscribers and Comments grids.
- **Popular Blogs** stays hidden until your blog has enough posts (20 by default, Blog Options).
- **Signed out in the middle of something?** The administrative site signs you back in where you were.
- **Site Wizard:** two opt-in boxes, to say hello to the Galaxie Blog project and to ask for your blog to be added to cfblogs.org. Both are off unless you check them.
- **Fixes:** the Scene editor's Save closes the window, links to comments go to the comment, the image quality slider on phones, the traffic cards on the administrative home page refresh themselves one at a time, scenes in posts sit under the floating menu, a comment's cached list is cleared when it's approved, and a reinit no longer stops clearing the cache at the first file it can't delete.

## What's new in 5.0 (Howl at the Moon Edition)

Galaxie Blog 5.0 is about how your blog looks and moves.

- **Scenes.** Scrolling stories at the top of a post or page, animated with GreenSock: layered heroes whose layers move at different speeds, photo, animated, gradient and video heroes, text blocks, slideshows, maps, forms and products. Every blog starts with six ready-made scenes, the gallery has many more, and the Scene editor builds your own with a live preview.
- **Post heroes.** The Enclosure is now the Hero, with four styles (Classic, Tall and held, Tall band, Magazine), hero text with its own font, color, shadow and glow, and a parallax hero picked from ready-made pictures right in the Hero editor.
- **The Site Wizard.** A new blog is set up in a few screens: name, theme, logo, about you, starter content and home page, with a live preview. The installer is now one page. Until your first post, the home page shows a getting-started post with what's left to set up.
- **The Shop.** Products, downloads and services, a cart and checkout through your own Stripe account, orders with shipping and refunds, and download links.
- **A new administrative home page** with Up next and this week's visitors, a Themes window with a live preview, one-step Delete in the grids, test buttons for the mail, database and Stripe settings, and private notes.
- **Comment replies,** a Remember me that works, and visitors see only approved comments.
- **Faster and lighter:** the home page reads its posts in two quick steps, the visitor logs get the indexes they need, the cfblogs.org feed is read in the background, the visitor log is tidied once a day instead of on every visit to the administrative site, and the Visitors grid loads one page at a time. Public pages always use the lighter Kendo Core, even when you're signed in.
- **When a page gets slow:** `?galaxieTimings=1` shows where a page spends its time, and single features can be switched off in `blog.ini.cfm` while you look into it.

The full list is in the [Release Notes: 5.0](https://galaxieblog.org/release-notes-50).

## What's new in 4.9 (Join the Pack Edition)

Galaxie Blog 4.9 turns the blog into a place where visitors can do things: send a form, sign up for an event, book a time with you, and pay. Everyone who does is brought together in one list, Members.

- **Forms.** A dozen ready-made forms (Contact, Request a quote, Feedback, RSVP and more), placed with *Insert, Form* and used as they are, or changed with *Edit this form*. Ten field types, required fields, choice limits, public sign-up lists, and submissions exported to CSV.
- **Events.** A post can be an event, with a date, time, time zone, location and host: an event card with Add to Google Calendar, sign-ups with capacity, guests and paid places, an Events page, a calendar feed and an Upcoming Events pod.
- **Bookings.** Booking types, locations (in person, online or by phone), weekly hours and booking pages; approval, reminders, cancel and reschedule links, and a bookings calendar.
- **Payments.** Paid bookings and paid events through your own Stripe account, with deposits, tax, test mode and automatic refunds.
- **Members.** Everyone who books, signs up, subscribes or sends a form, in one list. Visitors can sign in with an emailed link, no passwords, to see their bookings and sign-ups.
- **Error emails as a nightly summary,** with one email right away only when many errors happen at once.
- A cleaner administrative site that reads properly on phones, and many fixes.

The full list is in the [Release Notes: 4.9](https://galaxieblog.org/release-notes-49).

## What's new in 4.8 (Bella's Pawtrait Edition)

- **Page Collections and a curated home page.** Group pages into collections, show them as card grids, and choose what the home page shows (featured pages, collections, recent blog posts) with *Configure Homepage*. Related pages are shown under each page of a collection.
- **A configurable top menu.** *Configure Menu* sets your own menu links (for example to your other sites), the name of the collections menu, and the combined menu that phones show. Collections can be shown in the menu.
- **Hero images, gradients and animations.** Posts and collections can have a cover image, a generated gradient, or an animated (Vanta) background, with overlay text.
- **Uploads with Uppy**, including galleries and carousels; large images are resized when they are uploaded, and WebP copies and social media sharing images are created.
- **An Atom feed** (`/atom.cfm`) next to RSS, **scheduled releases**, canonical tags, and accessibility improvements.
- **A neutral default footer.** Your own footer lives in *Themes, Composite Footer*.
- **A safer installer.** It checks the datasource, will not install into a database that already holds a blog, inserts its starter data only once, and removes the password from `blog.ini.cfm` when it is done.
- Many fixes for Lucee and for MySQL/MariaDB.

Updating an existing blog? See [UPGRADING.md](UPGRADING.md).

## Acknowledgements

This blog would not have been possible without Raymond Camden. Raymond developed BlogCfc, on which this platform was originally based. Raymond is a ColdFusion enthusiast who has authored thousands of ColdFusion-related posts on the Internet. Like every senior ColdFusion web developer, I have found his posts invaluable and have based many of my own ColdFusion libraries on his approach.

## Authors

- [@gregoryalexander](https://github.com/GregoryAlexander77)

Gregory Alexander

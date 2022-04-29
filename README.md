I am proud to announce that Galaxie Blog 3 is finally released. While this blog does not yet have full fledged content management tools or e-commerce capabilities, it is intended to meet or exceed the out-of-the-box core blogging functionality of all of the major blog platforms such as WordPress and Wix. Unlike some other major blogging platforms, you own your data with Galaxie Blog, and Galaxie Blog only uses non-propreitory open-source libraries and is completely free.

Galaxie Blog was developed with a mobile-first priority. We have put great emphasis on perfecting your mobile experience where you can manage the blog and create a stunning blog post with just your phone. Galaxie Blog 3.0 is also an HTML5 web application. HTML5 is a modern web standard that supports the latest multimedia features and enhances user interaction. 

Galaxie Blog has extensive media support and will take the media that you upload and create new media formatted to the major social media platforms like Facebook and Twitter. You may also edit the images that you upload in the browser- no Photoshop is necessary! 

Galaxie Blog has scores of WYSIWYG editors. You don't need to know any HTML in order to create a beautiful blog post. These interfaces will allow you to upload images, videos, image galleries, and even create maps and map routes. Galaxie Blog is perfect for the travel blogger- it offers comprehensive tools to generate and share various types of maps that are free of charge. 

The blog also allows the users to interact with your post and share your posts on various social media sites. The blog offers options to use other commenting systems, such as Disqus if you want to use them. 

Galaxie Blog is eminently themeable. The blog has nearly 30 different pre-built themes and you can develop your own theme within a few minutes and unique fonts can be applied to any theme. All of your post content will take the characteristics of your selected theme. For example, the blog has branded emails that are sent to your subscriber base and the emails will be branded according to your theme. 

Galaxie Blog supports more databases than any other major blog software and can be used with any modern database. You don't need to have an isolated database and can keep the current database system that you have. Galaxie Blog also will also automatically create the database objects and schemas as required. Galaxie Blog also has an automatic installer and allows you to import data from a prior version of Galaxie Blog or other blogs such as BlogCfc.

Galaxie Blog has extensive SEO features to improve your ranking with the search engines. It also automatically structures your blog data for the search engines using the most modern version of JSON-LD. Galaxie Blog also automatically generates RSS that allows other applications to access your blog posts and create real-time feeds.

Galaxie Blog supports multiple users and user capabilities. There are 9 different user roles and dozens of unique capabilities. You can create new custom roles with unique capabilities. For example, you may assign one user to moderate the blog comments, and another to edit the contents of a post. 

Galaxie Blog allows for custom templates to over-ride the default Galaxie Blog logic. Developers can use custom templates to introduce new logic into the application and keep it separate from the core blog logic to allow the blog to remain current when new updates are made.

Galaxie Blog has many unique features not found in other blogs. For example, the blog allows you to use javascripts and other advanced features into a blog post. The blog can also include a logical programming template using a ColdFusion cfinclude in your blog posts. The blog is also perfect for developers, the blog can display code and can be tailored to support the display of hundreds of different programming languages. Additionally, unlike the majority of other blog software, it displays your code on mobile devices perfectly.

There are many more Galaxie Blog features that I will blog about in the future. 

Happy Blogging!

<p><strong>Getting the software</strong></p>
<ol>
<li>Galaxie Blog can be downloaded from the <a title="Galaxie Blog Git Hub Repository" href="https://github.com/GregoryAlexander77/Galaxie-Blog" target="_blank" rel="noopener">Galaxie Blog Git Hub Repository</a>.</li>
<li>You must have a ColdFusion installed on a server.
<ul>
<li><strong>Important note</strong>: if you are using ColdFusion 2018 or 2021, you must <strong>not </strong>check the <strong>Disable access to internal ColdFusion Java components </strong>checkbox in the ColdFusion Administrator as it will cause the Javaloader, which this blog uses, to fail. Unfortunately, many ISPs, such as Hostek.com shared sites, have this setting enabled on CF2018 and CF2021. Use ColdFusion 2016 if you don't have access to the ColdFusion administrator to turn this setting off.</li>
<li>Your web server must have ColdFusion installed. Galaxie Blog has been tested on ColdFusion 2016, 2018, and 2021.</li>
<li>Theoretically, the blog may support any ColdFusion edition starting from ColdFusion 9, however, your mileage may vary.</li>
<li>We have successfully tested against Apache, TomCat and IIS.</li>
<li>We have not yet tested the blog on Lucee, an open-source version of Adobe ColdFusion. We intend on supporting Lucee in the future.</li>
<li>There are many ISPs which offer ColdFusion servers for as low as 12 dollars a month. Search the web for ColdFusion hosting to find out more.</li>
</ul>
</li>
<li>Once downloaded, upload the entire contents into your desired location on a web server
<ul>
<li>You can install the contents in the root, or in folder in the root directory of your server.</li>
<li>We have tested the blog in the root, and in 'blog' and 'galaxie' folders.</li>
</ul>
</li>
<li>You must have a database that is accessible to the webserver. The blog was <strong><em>should</em></strong> support the following databases, however, we have only tested the blog using SQL Server:
<ul>
<li>Microsoft SQL Server</li>
<li>DB2</li>
<li>DB2AS400</li>
<li>DB2OS390</li>
<li>Derby</li>
<li>Informix</li>
<li>MySQL</li>
<li>MySQLwithInnoDB</li>
<li>MySQLwithMyISAM</li>
<li>Oracle8i</li>
<li>Oracle9i</li>
<li>Oracle10g</li>
<li>PostgreSQL</li>
<li>Sybase</li>
<li>SybaseAnywhere</li>
</ul>
</li>
<li>Create the database to install Galaxie Blog in.
<ul>
<li>You may install Galaxie Blog using your current database, however, you need to make sure that there are no table name conflicts. We will document the database schema in later blog posts.</li>
<li>We have tested Galaxie Blog using our original BlogCFC database with no conflicts.</li>
</ul>
</li>
<li>Create a ColdFusion DSN for the database that you intend to install Galaxie Blog in.</li>
</ol>
<p><strong>Enable Woff and Woff2 Font Support on the Webserver<br></strong>Galaxie Blog uses web fonts for typography and needs web font mime types set up on the webserver. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. If the server does not support these mime types certain textual elements will not be displayed.&nbsp;</p>
<ol>
<li>.woff (use font/woff as the mime type).</li>
<li>.woff2 (use font/woff2 as the mime type).</li>
</ol>
<p><strong>Installing the software</strong></p>
<ol>
<li>Migrate to the URL of your uploaded blog and the blog should automatically open the installer.
<ul>
<li>For example, if you uploaded the files in the root directory go to <a href="http://yourdomain.com/">http://yourdomain.com/</a>.</li>
<li>If you uploaded to a blog directory in your root, go to <a href="http://yourdomain.com/blog/,">http://yourdomain.com/blog/,</a> etc.</li>
</ul>
</li>
<li>The installer will guide you and ask you to enter information, such as your URL, blog name, and other information.&nbsp;</li>
<li>The installer is a 7 step process. Each screen has may provide information and ask you to hit the next button or have multiple questions. It should not take more than 5 minutes to fill out.</li>
<li>Be sure to write down your chosen user name and password. You will need to retain this information. Galaxie Blog does not retain passwords- the passwords are hashed using the strongest publicly available encryption process and they cannot be recovered.</li>
<li>Once you are done, the installer will automatically create the database and import the needed data. In the final step, it may take a while for the software to be installed. If there is a time-out error, refresh the browser and the installation should continue.</li>
<li>Once installed, you should see your new blog with a 'No Entries' message on the front page. You will not see any blog posts until you make them using the administrative site, see below.</li>
</ol>

<p>The Galaxie Blog Administration site can be accessed by clicking on the user icon near the top of the blog page or by appending /admin to the blog URL. Your user credentials must be used to access the site.</p>
<p><strong>Interfaces</strong><br>There are over fifty (50) different administrative interfaces, and each interface is carefully designed for both mobile and desktop clients. We have taken great care to intuitively organize the different interfaces. You can administrate your blog using a mobile or desktop device. There is also native phone functionality, for example, when you are uploading media, can take a picture or use a picture previously taken from your phone.</p>
<p>If you are a site administrator, there are a dozen or so different major interface categories. There are multiple user roles and capabilities, if a user does not have permission or role they will not see the icon to launch the interface.&nbsp;</p>
<p>Galaxie Blog uses a windowing system, similar to Windows or the Macintosh, to open up an interface. The windows have minimize, refresh and close icons at the top right hand of the screen. The minimize icon allows the user to minimize the window to navigate around or open up a new interface. Refreshing the window is handy if you want to set the interface back to its default state, for example, to clear up the filters that you may have applied to an HTML5 grid.&nbsp;</p>
<p>Many of the interfaces open up an HTML5 grid. Nearly every column in the grid is searchable and sortable. When editing a post, you can search for a partial title to find and open a particular post.&nbsp;</p>
<p>There are scores of different advanced WYSIWYG Galaxie Blog editors. Each editor has a certain purpose, such as editing a post or uploading an icon for your site. All of the editors are WYSIWYG and offer a real-time preview. I will cover two of the major post editor interfaces below.</p>
<p><b>Major Post Editors<br></b>There are two different major editors for a given post.</p>
<ol>
<li>the Enclosure Media Editor</li>
<li>the Inline Post Editor</li>
</ol>
<p><strong>Enclosure Media Editor</strong><br>An enclosure is an oversized image or media that is placed at the top of a post. It is often called a hero image as it captures the attention of the user when viewing a post. The enclosure editor is different than the inline post editor and handles different types of media. This editor may be used to attach the following media:</p>
<ol>
<li>Drag and drop interface to upload videos from a local source.&nbsp;&nbsp;</li>
<li>Embed videos from an external source, such as YouTube or Vimeo
<ul>
<li>Videos <em>may </em>also have:
<ul>
<li>A video cover poster (an image that covers the video when it is not being played)</li>
<li>WebVtt Captions can be applied to uploaded videos using the WebVTT Galaxie Editor.</li>
</ul>
</li>
</ul>
</li>
<li>Drag and drop web-friendly images, such as .jpg, png, gif, webp, etc.
<ul>
<li>You can upload or include images from an external source.
<ul>
<li>If you upload an image, Galaxie Blog will try to <em>automatically </em>create the following images:<br>
<ul>
<li>Optimized image for Facebook sharing</li>
<li>Optimized image for Twitter</li>
<li>3 different images optimized for the Google Search Engine (used to display images in Google search results)</li>
<li>Creates thumbnail images for Galaxie Blog preview</li>
</ul>
</li>
<li>Upload images may be edited within the browser. The following actions may be taken: change image orientation, brightness, contrast, gamma, flip image horizontally or vertically, etc,&nbsp;</li>
</ul>
</li>
</ul>
</li>
<li>Create static maps with various options</li>
<li>Create map Routes showing the path of an intended travel route. A route can have two or more destinations (with a max limit of 12).&nbsp;</li>
</ol>
<p><strong>Inline Post Editor<br></strong>The inline post editor handles the editing of the blog post. The inline post editor contains the following options:</p>
<ol>
<li>Undo/Redo</li>
<li>Various paragraph formatting.</li>
<li>Bold, italic</li>
<li>Alignment tools (center, left justify, center, etc)</li>
<li>Bulleting tools and indentation</li>
<li>Link and anchor tools</li>
<li>Special characters</li>
<li>Source code</li>
<li>HTML tables</li>
<li>Code samples for the dozens of programming languages&nbsp;</li>
<li>Image editing of current embedded images</li>
<li>Insert Media (videos and images)</li>
<li>Upload and create image galleries using a drag and drop interface.&nbsp;
<ul>
<li>The Gallery upload interface allows you to use images saved locally or to use your camera on your device if available.&nbsp;</li>
</ul>
</li>
<li>Create static maps</li>
<li>Generate map Routes containing two or more destinations</li>
</ol>
<p>Editor Notes:</p>
<ul>
<li>All editors will automatically create a preview of the media within the editor, even for videos and maps!</li>
<li>Be careful when uploading large videos or images. The max file size generally is around 8MB. If you have larger images videos, you can upload them manually with an FTP client and link to them using the Enclosure Editor.&nbsp;</li>
</ul>
<p><strong>The Edit Post interface<br></strong>Along with the enclosure and inline post WYSIWYG editors that were just covered, there are a few other Edit Post interface concepts that we should cover:</p>
<ul>
<li>Release Post means that the post will be public. A post cannot be seen by non-administrators until it is released.</li>
<li>The post date may include past or future dates. If a post date is in the future you will have the option to automatically schedule the release of a post.</li>
<li>The Post Header contains optional Galaxie Blog Post Directives. These directives are used to attach a javascript to a post, include a ColdFusion template with a cfinclude, embed responsive videos, and manually set the properties of the meta tags used for SEO among other things. See Galaxie Post Directives for more information below.&nbsp;</li>
<li>The JSON-LD button opens up the JSON-LD editor which can be used to manually set the JSON-LD. JSON-LD is automatically generated by Galaxie blog for SEO purposes.&nbsp;</li>
<li>The Promote checkbox will highlight and promote a post to the top of the page.&nbsp;</li>
<li>Change Alias will allow you to change the friendly name in the URL.</li>
<li>Use the Related Posts dropdown to show the related posts underneath the blog post.&nbsp;</li>
</ul>
<p>The rest of the options should be self-explanatory and do not need to be covered.</p>
<p><strong>Comments</strong><br>Manage the blog comments. You can approve a comment using the grid or the comment detail page. Only used when the blog is using the native commenting interface.</p>
<p><strong>Categories</strong><br>Used to manage blog categories.&nbsp;</p>
<p><strong>Themes<br></strong>We have paid very close attention to making all of our interfaces eminently themeable. Nearly every widget that we use matches the characteristics of the theme. Take for example the <a href="https://www.gregoryalexander.com/blog/2019/12/16/Playing-your-own-video-content-with-Galaxie-Blog">video player</a> and note that the buttons take on the primary color of the theme. Even the <a href="https://www.gregoryalexander.com/blog/2022/4/16/One-of-the-most-beautiful-highways-in-the-US-Utah-Highway-12">map route</a> takes on the primary color of the theme.&nbsp;</p>
<p>The Theme Interface is used to select font topography, set display settings, and upload various logos and images for each theme. We are not going to get into the nuts and bolts of each setting but will focus on a few key concepts here and will devote another article discussing the theme setting details in the future.</p>
<ol>
<li><strong>Use Theme</strong> will keep the theme option intact in the themes drop-down menu at the top of the page and in the future will allow you to select a theme for a given post.&nbsp;</li>
<li><strong>Select Theme</strong> over-rides the Use Theme selections and allows you to only display this particular theme on the site. Every page will take on this theme property and all of the other themes will be removed from the themes dropdown at the top of the page.&nbsp;</li>
</ol>
<p><strong>Modern and Classic Theme Styles</strong><br>There are two options that dramatically affect the blog display.</p>
<ul>
<li>The&nbsp;<b>Classic</b> theme style displays the column on the right of the blog containing various 'pods', such as the categories, recent posts, comments, etc. This is a useful design if you want to allow your users to quickly navigate your site or if you want to include visible advertising.</li>
<li>The&nbsp;<b>Modern</b> theme style removes the panel on the right, but the panel is still accessible by clicking on the hamburger at the top of the site. The Modern theme style keeps the blog content center stage.&nbsp;</li>
</ul>
<p><strong>Theme Fonts and Typography<br></strong>Each theme can have its own font. Fonts can be applied to the following elements:&nbsp;</p>
<ol>
<li>The blog header, ie. 'Gregory's Blog'</li>
<li>Blog Menu</li>
<li>Blog Body (everything else)</li>
</ol>
<p>There are <em>many</em> other theme settings but they should be self-explanatory and will not cover these in this overview.&nbsp;</p>
<p><strong>The Galaxie Blog Font Interface<br></strong>Galaxie Blog allows you to upload and manage your fonts and it allows you to preview the look of the font once uploaded. If you're wanting to add a font, you generally don't need to purchase them. Instead, use the google web fonts helper at <a href="https://google-webfonts-helper.herokuapp.com/fonts">https://google-webfonts-helper.herokuapp.com/fonts</a>. Be sure to upload both .woff and .woff2 fonts in order to support legacy browsers. If you upload a google font check the self-hosted and google font checkboxes.&nbsp;</p>
<p>The 'use font' checkbox makes the chosen font available to the post editor. However, if you have assigned a font to a theme <em>these fonts will already be available</em>. Be careful not to select all of your desired fonts as this will increase the page load time as the browser will need to download them.&nbsp;&nbsp;</p>
<p><strong>Branded Emails<br></strong>Galaxie Blog sends branded emails that take on the characteristics of your chosen or selected theme. These emails are responsive and follow the best practices recommended by various SEO sites. Branded emails will be sent when:<strong><br></strong></p>
<ol>
<li>The user subscribes to your blog.&nbsp;</li>
<li>The user is asked to confirm their identity when they make their first comment. However, this is not applicable if you are using the optional built-in Disqus library for your commenting system.</li>
<li>When the user's comment is approved (when using the default commenting system)</li>
<li>To all of the subscribers when a post has been made</li>
<li>A new user is asked to set up their own profile and choose their own password when a new Galaxie User is assigned by the site administrator</li>
</ol>
<p><strong>Subscriber Interface<br></strong>Subscribers will automatically be sent a branded email whenever a new blog post has been made. Blog subscribers are captured when a user types their email address on the main page. When a user fills out the subscribe form they will be sent an email asking for them to double confirm. This is known as a 'double opt-in' process and is generally recommended.</p>
<p>You can use the Subscribers Interface to view and manage your subscribers. Additionally, you may also add new subscribers. Of course, you should obtain their consent before adding them.&nbsp;</p>
<p><strong>User Interface<br></strong>Site administrators may manage Galaxie Blog users using the Galaxie Blog User interfaces. Admins may look at the user profile, however, they cannot view <strong>any </strong>user passwords, even their own! If the site administrator loses their password, there is a way to reset it, however, this is a manual process and someone will have to dig into and temporarily modify the authentication code. I will write a how-to-article in the future describing the manual process.</p>
<p>When the admin assigns a new user, an email will be generated to the new user asking them to create their own profile and to choose a password. The initial user password set by the administrator is only used to authenticate the new user and will be replaced by the password that the user has chosen when creating their new user profile.&nbsp;</p>
<p>Site Administrators also may view the user's log-in history. The user's IP address and browser user agent strings are captured with every successful login.</p>
<p><strong>User Roles<br></strong>The following are the built-in Galaxie Blog user roles. Custom roles can also be created, see the capability section below.</p>
<ul>
<li>Administrators - full access</li>
<li>Author - can create posts</li>
<li>Designer - may modify theme properties</li>
<li>Editor - may edit, but not release a post.</li>
<li>Guest - not used at the present moment</li>
<li>Moderator - can moderate comments if using the native commenting system (not Disqus though)</li>
<li>Subscriber - not used in this version</li>
<li>Super-User - has full access other than having access to the blog settings and options interfaces.</li>
</ul>
<p><strong>User Capabilities<br></strong>Users and custom roles also can be assigned unique capabilities. The following capabilities are available:</p>
<ol>
<li>Add Post - may create and release posts</li>
<li>Asset Editor - may add or modify post media (images, videos, etc)</li>
<li>Edit Category</li>
<li>Edit Comment</li>
<li>Edit File (for future use after adding CMS capabilities)</li>
<li>Edit Page (for future use after adding CMS capabilities)</li>
<li>Edit Post</li>
<li>Edit Profile (may change user information, but not passwords)</li>
<li>Edit Server Setting</li>
<li>Edit Subscriber (may delete or add new subscribers)</li>
<li>Edit Template (future use after adding CMS capabilities)</li>
<li>Edit Theme</li>
<li>Edit User (can manage users)</li>
<li>Release Post (may release a post to the public)</li>
</ol>
<p><strong>Blog Settings<br></strong>The blog settings interface is used to set system settings, such as the database connection strings. Most of these settings are self-explanatory and do not need to be covered.&nbsp;</p>
<p>The parent site name and links allow the blog user to click on the logo at the top of the page, or to click on the menu dropdown and go to your home page or whatever you entered in this setting. You can also set the parent site and link to be the front page of the blog. The choice is up to you.</p>
<p>Server Time Zone allows the blog to sync the time when the server resides in a different time zone than the blog owner. Choose the server time zone and your time zones if they are different.&nbsp;</p>
<p>The mail server settings are critical for the proper delivery of your email. Contact your server administrator to get the information if you need help. You can also set the carbon copy email address to cc that email every time an email is sent out. This is useful to keep track of the email sent out.</p>
<p>Note: the validation requires that <strong>all </strong>of the required form fields are filled out. You may have to click on the page ribbons (ie 'Mail Server Settings') to open up the section that needs to be filled out.</p>
<p><strong>Blog Options<br></strong>Nearly all of the options here are optional. The major settings that require elaboration are:</p>
<ul>
<li><strong>Use SSL</strong> (optional) - it is always recommended to use SSL if you have an SSL Certificate on the server. SSL encrypts your traffic and makes it very difficult if not impossible to 'sniff' confidential information such as user names and passwords. Additionally, many of the optional libraries, such as Discus require SSL.&nbsp;</li>
<li><strong>Server Rewrite Rule in place</strong> (optional) - select this if you have server rewrite rules on the server that allow friendly URLs without the index.cfm extension. Most of the ISPs can assist you in creating a rewrite rule to create a user-friendly URL.&nbsp;</li>
<li><strong>Defer Non-Essential Scripts</strong> - this speeds up the page load by deferring noncritical Javascript. It is recommended to keep this setting turned on.</li>
<li><strong>Minimize Code</strong> - this also speeds up the page load time by removing the white space on the page, however, it is only active when the cache is enabled.</li>
<li><strong>Disable Cache</strong> - this setting should be kept when initially setting up your blog. Only uncheck this checkbox when your blog is completely up and running.&nbsp;</li>
<li><strong>JQuery CDN Location</strong> and Kendo - keep these settings the way they are unless you're an advanced user and are changing your JQuery or Kendo versions.&nbsp;</li>
<li><strong>AddThis API Key </strong>and Toolbox string - AddThis is used to allow users to share your blog posts on various social media sites. However, you need an addThis api key.&nbsp;</li>
<li><strong>Bing Maps API Key</strong> - if you want to use the map and map route blog features, you must sign up to obtain a free BingMaps API Key.&nbsp;</li>
<li><strong>Disqus Library </strong>- These settings are used if you want to use Disqus as your commenting system.</li>
<li><strong>Include GSAP</strong> - the GreenSock library is used by advanced users who want to add dazzle and animations to a page. Unless you are interested keep this off as it consumes extra resources.</li>
</ul>
<p><strong>Blog Updates<br></strong>The blog Updates interface will let the user know if there are new blog updates and what updates should take place.</p>
<p><strong>Import Data<br></strong>Used to import data from a previous BlogCfc or Galaxie Blog installation<strong>&nbsp;</strong></p>
<p><strong>Refresh Site<br></strong>Used to refresh all of the application variables and removes any cache from the page. You can also append ?reinit=1 to the URL to refresh the site.</p>

<b>Brief Technical Overview of the Galaxie Blog Installation Process</b>

<p>This article is meant for <strong>developers </strong>that want to understand or debug the Galaxie Blog Installation process.&nbsp;</p>
<p><strong>Where the site variable data are stored</strong></p>
<p>The root Application.cfc variables, such as the site URL, are stored in two locations.</p>
<ul>
<li>The blog.ini.cfm file stored in the org/camden/blog/ directory</li>
<li>In the Galaxie database</li>
</ul>
<p>We need to use the .ini file to store variables as the database will not be set up prior to the blog installation. We are also storing the variables in the database after the initial installation as it is more efficient to capture the variables from the database rather than to read from the ini file. Once everything is installed we are also storing the variables in the ColdFusion application scope in order to have them available throughout the application.&nbsp;</p>
<p><strong>How the installation process works to set and extract these variables</strong></p>
<p>When the blog URL is entered, the root Application.cfc template will determine if the blog is installed by reading the <strong>installed </strong>argument in the blog.ini file. The default value in the blog.ini file is set to installed=false, and once the Application encounters this it will try to include the 'installer/initial/index.cfm?notInstalled' template. This interface asks the user to fill out the site URL and user information. The interfaces store the information that the user provides in the blog.ini file are all in the 'installer/initial/' directory.&nbsp;</p>
<p>If your installation goes awry and you need to reinstall the application you can manually run this file by commenting out the logic surrounding the cfinclude or appending 'or 1 eq 1' at the end of the conditional logic.&nbsp;</p>
<p>Once the initial installer is run the application will include the 'installer/insertData.cfm' template to configure the database and install the data. This process may take several minutes to complete as it is building the initial database objects, saves the data entered by the user, reads the text files stored in the /installer/dataFiles/ directory, and populates the initial data in the database. Depending upon memory and server settings this process may time out, potentially during a parseUri loop. If this occurs, refresh your browser. The application contains logic to make sure that the data is not duplicated and the application should resume the installation where it failed.</p>
<p>If you're manually reinstalling the database by forcing the initial installer to run, be sure to remove the code that you used to run the initial installer and force the insertData.cfm template to be run, again by either commenting out the code or by appending a 'or 1 eq 1' statement around the insertData.cfm template.</p>
<p><strong>Why are we are sometimes requiring two manual changes to the file structure?</strong></p>
<p>In two steps during the installation process, we are requiring the user to modify the ApplicationProxy.cfc template in the admin folder (if they are not installing the blog into the blog folder) and requiring the user to substitute 4 files (if they are not using SQL Server). It is an easy process as the installer guides you through the process and provides the exact string to enter into the application proxy template and shows the locations of the substituted files. However, I want to briefly explain the rationale for this manual process.&nbsp;</p>
<p>First, we need to extend the application template in the admin folder. I have tried many different approaches, some work with CF2016 and fail with CF2021. I can't find a sure-fire way to extend the base application that works with all servers so I am asking the user to change the string within the extends argument in the application proxy.&nbsp;</p>
<p>We are also asking the user to substitute the persistent ORM-related cfc's as we can't attach dynamic variables in the persistent cfcs. Certain database columns require a very long string, such as the Post.Body column. We are using database-specific language to set a max length and the database vendors have different datatypes for a long string (for example varchar(max) in SQL Server). We have added logic for many databases, but we have not had the time (nor the resources) to test every database server. If you are encountering problems please see the database vendor documentation for a long string (varchar(max), long text, text, etc).</p>
<p>If you have an idea to make this a fully automated process, please feel free to suggest any potential solutions.&nbsp;</p>
<p><strong>If you run into problems...</strong></p>
<p>This is a final release candidate so I am sure that there are going to be a few bugs.<strong>&nbsp;</strong>However, please reach out to me or document the issue on the git hub site. I prefer that you document the issue so that others can also see what is going on. I made some mistakes on the previous version of Galaxie Blog's installer and am frustrated that no one reached out to me. I spent a great deal of time developing this for the community and would like to be aware when something goes wrong.&nbsp;</p>
<p>There are some tools built in the Application.cfc template that may also be used to debug your issues.&nbsp;There is a debug = false statement near the top of the root Application.cfc template. Set this argument to debug = true to print out all of the system variables.</p>
<p>If you're using a hosted provider with CF2018 or CF2021, they may have a setting that causes the Java loader to fail. The 'Disable Internal Java Components' checkbox must not be checked in the ColdFusion administrator. If you can't get around this, for now, use CF2016.&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>

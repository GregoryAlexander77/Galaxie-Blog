
# Galaxie Blog
Galaxie Blog is intended to be the most beautiful and functional free, open-source ColdFusion-based blog in the world. While it can’t go toe-to-toe with Wordpress functionality, I believe that Galaxie Blog competes with Wordpress in core blogging functionality, especially with its abundant theme-related features and support for various rich media.

## Documentation

The Galaxie Blog documentation can be found on Gregory's Blog at https://www.gregoryalexander.com/blog/Galaxie-Blog. Gregory's Blog runs on the same codebase found here. Many how-to articles on Gregory's Blog discuss how we have implemented some of the logic. 

## Installation

You must have a ColdFusion installed on a server.
Your web server must have ColdFusion installed. Galaxie Blog has been tested on ColdFusion 2016, 2018, 2021, and 2023 (2023.0.07.330663).

Theoretically, the blog may support any ColdFusion edition starting from ColdFusion 9. However, your mileage may vary.
We have successfully tested using Apache, TomCat and IIS.
We have not yet tested the blog on Lucee, an open-source version of Adobe ColdFusion, however, I intend on supporting Lucee in the future.

Many ISPs offer ColdFusion servers for as low as 12 dollars a month. I use Media3.net, and they have been terrific. You can find out more by searching the web for ColdFusion hosting.

1. Galaxie Blog can be downloaded from the Galaxie Blog Git Hub Repository.

2.  Once downloaded, upload the entire contents into your desired location on a web server
- You can install the contents in the root or in a folder in the root directory of your server.
- We have tested the blog in the root, and in 'blog' and 'galaxie' folders.

3. Create the database to install Galaxie Blog in.

The blog uses Hibernate ORM and was designed to support the following databases; however, we have only tested the blog using SQL Server and various flavors of MySql:
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

You may install Galaxie Blog using your current database. However, you need to make sure that there are no table name conflicts. We will document the database schema in later blog posts.

4. Create a ColdFusion DSN for the database that you intend to install Galaxie Blog.
5. Enable Woff and Woff2 Font Support on the Webserver
Galaxie Blog uses web fonts for typography and needs web font mime types set up on the web server. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. If the server does not support these mime types certain textual elements will not be displayed. 

- .woff (use font/woff as the mime type).
- .woff2 (use font/woff2 as the mime type).

6. Installing the software

- Migrate to the URL of your uploaded blog, and the blog should automatically open the installer. For example, if you uploaded the files to the root directory, go to http://yourdomain.com/.
- If you uploaded to a blog directory in your root, go to http://yourdomain.com/blog/, etc.
- The installer will guide you and ask you to enter information, such as your URL, blog name, and other information. 
The installer is a seven-step process. Each screen may provide information and ask you to hit the next button or have multiple questions. It should not take more than five minutes to complete.
Be sure to write down your chosen user name and password. You will need to retain this information. Galaxie Blog does not retain passwords—they are hashed using the strongest publicly available encryption process and cannot be recovered.
- Once you are done, the installer will automatically create the database and import the needed data. The final step may take a while for the software to be installed. If there is a time-out error, refresh the browser, and the installation should continue.

7. Once installed, you should see your new blog with a 'No Entries' message on the front page. You will not see any blog posts until you make them using the administrative site; see below.
    
## Acknowledgements

This blog would not have been possible without Raymond Camden. Raymond developed BlogCfc, on which this platform was originally based. Raymond is a ColdFusion enthusiast who has authored thousands of ColdFusion-related posts on the Internet. Like every senior ColdFusion web developer, I have found his posts invaluable and have based many of my own ColdFusion libraries on his approach.

## Authors

- [@gregoryalexander](https://github.com/GregoryAlexander77)

Gregory Alexander

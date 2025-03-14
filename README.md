
# Galaxie Blog
Galaxie Blog is a wickedly fast, full-featured, open-source blog that supports Lucee and Adobe ColdFusion. According to various sources, Lucee is the second fastest web server platform, and Adobe is the third fastest after Lucee and Go. If you want a wickedly fast blog with full functionality and theme support, Galaxie Blog is ready, set, go! 

## Documentation

The Galaxie Blog documentation can be found on Gregory's Blog at https://www.gregoryalexander.com/blog/Galaxie-Blog. Gregory's Blog runs on the same codebase as the one found here. Many how-to articles on Gregory's Blog discuss how we have implemented some of the logic. 

## Installation

Galaxie Blog is a standalone software package that must be installed with ColdFusion or Lucee running on a web server. Once you have met a few requirements, it is simple to install. This article will cover how to get the software, set up basic server requirements, and install Galaxie Blog.

1.  Galaxie Blog can be downloaded from the [Galaxie Blog Git Hub Repository](https://github.com/GregoryAlexander77/Galaxie-Blog).  
      
2.  You must have ColdFusion or Lucee installed on the web server.
    *    **Lucee**
        *   Galaxie Blog has been tested using Lucee 6.031 through Lucee 6.2.0.321. Due to ORM issues, Galaxie Blog does not work with versions below 6.0.
        *   You must have the following packages installed: [Ortus ORM Extension](https://www.ortussolutions.com/products/orm-extension) 6.0+, Image Extension 2.0+, EHCache 2.0+, Mail, and the extensions for the database of your choice. 
    *   **ColdFusion** 
        *   Galaxie Blog has been tested on ColdFusion 2016, 2018, 2021, and 2023 (2023.0.07.330663).
        *   The blog may theoretically support any ColdFusion edition starting from ColdFusion 9; however, your mileage may vary.
        *   The following packages must be installed: Cacheing, Feed, Image, Mail, ODBC, ORM, and the extensions for the database of your choice.
    *   We have successfully tested using Apache, TomCat, and IIS. We also have successfully tested both Lucee and Adobe ColdFusion with CommandBox.  
          
        
3.  Hosting: Many ISPs offer ColdFusion and Lucee Hosting. I use [Media3.net](https://www.media3.net) for Adobe ColdFusion and [VivioTech](https://galaxieblog.org/admin/and%20the%20extensions%20for%20the%20database%20of%20your%20choice.) with Lucee, which are terrific. Search the web for ColdFusion or Lucee hosting to find out more.  
      
    
4.  Once downloaded, upload the content to your desired location on a web server. If you are uploading the blog folder, change the folder name as desired.  
    *   You can install the contents in the root or a folder in your server's root directory.
    *   You can use the root or a subfolder. I have tested the blog in the root ('/'), '/blog', and '/galaxie' folders.  
          
        
5.  You must have a database accessible to the web server. The blog **_should_** support one of the following databases:  
      
    *   Microsoft SQL Server
    *   DB2
    *   DB2AS400
    *   DB2OS390
    *   Derby
    *   Informix
    *   MariaDB
    *   MySQL
    *   MySQLwithInnoDB
    *   MySQLwithMyISAM
    *   Oracle8i
    *   Oracle9i
    *   Oracle10g
    *   PostgreSQL
    *   Sybase
    *   SybaseAnywhere  
          
        
6.  Create the database.  
      
    *   You may install Galaxie Blog using your current database. However, you must ensure that there are no table name conflicts. 
    *   We have tested Galaxie Blog using our original BlogCFC database with no conflicts.  
          
        
7.  Create the Blogs ColdFusion DSN.
    *   If you use a DSN other than GalaxieDb with **Lucee**, you must modify the DSN string in the root Application.cfc. Search for <cfset this.datasource = "GalaxieDb"> and modify the DSN.
    *   As a precaution, set the maximum connections setting to  a value that is less than the database max connections if you're using  **Lucee** and one of the flavors of MySql

* * *

Enable Woff and Woff2 Font Support on the Webserver
---------------------------------------------------

Galaxie Blog uses web fonts for typography and needs web font mime types set up on the web server. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. Certain textual elements will not be displayed if the server does not support these mime types. 

1.  .woff (use font/woff as the mime type).
2.  .woff2 (use font/woff2 as the mime type).

* * *

Installing the Software
-----------------------

Galaxie Blog is simple to install and uses a built-in multi-step installer. However, a few manual steps are required after uploading the software to your web server.

1.  Migrate to the URL of your uploaded blog, and the blog should automatically open the installer.
    *   For example, if you uploaded the files to the root directory, go to [http://yourdomain.com/](http://yourdomain.com/).
    *   If you uploaded to a blog directory in your root, go to [http://yourdomain.com/blog/,](http://yourdomain.com/blog/,) etc.
2.  The installer will guide you and ask you to enter your URL, blog name, and other information. 
3.  The installer is a seven-step process. Each screen may provide information and ask you to hit the next button or have multiple questions. It should not take more than five minutes to complete.
4.  Be sure to write down your chosen username and password. You will need to keep this information. Galaxie Blog does not keep passwords—they are hashed using the strongest publicly available encryption process and cannot be recovered.
5.  Once you are done, the installer will automatically create the database and import the needed data. The final step may take a while for the software to install. If you happen to receive a time-out error, please refresh the browser, and the installation should continue.
6.  Once installed, your new blog should have a 'No Entries' message on the front page. However, you will not see any blog posts until you create them using the administrative site; see below.

If you have any issues, don't hesitate to [contact](https://www.gregoryalexander.com/blog/) me.

## Authors

- [@gregoryalexander](https://github.com/GregoryAlexander77)

Gregory Alexander

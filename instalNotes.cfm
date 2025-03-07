Lucee install notes.
You you have a previous copy of the blog, make sure that you use a clean blog.ini.cfm file from https://github.com/gregoryalexander77/Galaxie-Blog/blob/master/org/camden/blog/blog.ini.cfm. 

Create the datasource. Lucee requires the datasource to be hardcorded when using ORM. The default datasource for this.datasource  is 'GalaxieDb'. Change this value if you're using a different datasource with Lucee. 

Common Issues
When using MySql or MariaDb, you may receive a 'too many connections error'. This error may be due to ORM during the installation process. To fix this, you should set the global max connections on the database to 500 and set the max connections in Lucee below 500 to ensure that the max connections on the database server are not met. See https://www.ionos.com/digitalguide/websites/web-development/solve-mysqlmariadb-too-many-connections-error/ for more information.

Probably not needed
If you are using the blog in the root directory, change the first line of the /application/ApplicationProxyReference.cfm file from 'blog.Application' to Proxy. If you're using a subfolder, such as blog, use blog.Application, etc. Galaxie Blog will walk you through this process during the installation.

You must delete the /installer/databaseOrmFiles folder on the server. You can always get these files from the github repository at https://github.com/gregoryalexander77/Galaxie-Blog/tree/master/installer/databaseOrmFiles if you ever need to change databases.

Notes to self
Update the database installation files before committing to git

Before committing to git, generate new data files for installation at https://gregoryalexander.com/blog/common/data/generateDataFiles.cfm and copy the files over to the installation repositories. These files will be on the server.

Maria conf location
/etc/mysql/conf.d/
/etc/mysql/mariadb.conf.d/

sudo nano /etc/mysql/mariadb.conf.d

UDATE KendoTheme
SET KendoTheme = 'blueopal',
KendoThemeCssFileLocation = 'styles/kendo.blueopal.min.css,
KendoThemeMobileCssFileLocation = 'styles/kendo.blueopal.mobile.min.css'
WHERE KendoThemeId = 2

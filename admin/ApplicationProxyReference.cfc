<cfcomponent extends="Proxy"><!---Examples: extends="blog.Application" if in the blog is in a 'blog' subfolder, extends="Proxy" if in the root directory. --->
	<!--- If the blog is in the root directory, change the extends line to Proxy. If the blog is in a subfolder in your site, let's say the 'blog' folder, add the folder name with a dot and the 'Application' string (ie 'blog.Application') --->
	<!--- The application name must be left blank --->
	<!--- Note: this works from the sub folder and includes the application in the root --->
</cfcomponent>
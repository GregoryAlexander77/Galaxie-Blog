<cfcomponent extends="Proxy"><!---Examples: extends="blog.Application" if in the blog is in a 'blog' subfolder, extends="Proxy" if the Application.cfc is in the root directory. --->
	<!--- If the blog is in the root directory, change the extends line to Proxy. If the blog is in a subfolder in your site, let's say the 'blog' folder, add the folder name with a dot and append an 'Application' string (ie 'blog.Application') --->
	<!--- The application name must be left blank --->
	<!--- Note: this cfc must be placed in the root directory alongside the Application.cfc that you're tyring to extend. --->
</cfcomponent>
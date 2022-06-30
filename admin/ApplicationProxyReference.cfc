<cfcomponent extends="blog.Proxy"><!---blog.Application also *sometimes* works if the folder is blog and the blog is in the root directory. --->
	<!--- The application name must be left blank --->
	<!--- I have tested this on numerous servers and using blog.Application works if the sub folder name is blog, however, this has failed for me on one server and one of the users notified me that this also caused an error. 

	I am switching the logic to use Proxy here instead which will extend the Proxy.cfc component in the root directory which extends the Application.cfc in the root folder.  --->
</cfcomponent>
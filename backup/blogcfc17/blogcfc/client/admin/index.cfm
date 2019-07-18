<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : /client/admin/index.cfm
	Author       : Raymond Camden
	Created      : 04/06/06
	Last Updated : 8/1/07
	History      : Added blog name (rkc 5/17/06)
				 : typo (rkc 8/20/06)
				 : JS alert when coming from settings page (rkc 9/5/06)
				 : htmlEditFormat the title (rkc 10/12/06)
				 : added top entries for past 7 days (rkc 2/28/07)
				 : fixed link to my blog, made "past few days" say seven to be more clear (rkc 8/1/07)
--->

<!--- As with my stats page, this should most likely be abstracted into the CFC. --->
<cfset dsn = application.blog.getProperty("dsn")>
<cfset blog = application.blog.getProperty("name")>
<cfset sevendaysago = dateAdd("d", -7, now())>
<cfset username = application.blog.getProperty("username")>
<cfset password = application.blog.getProperty("password")>

<cfquery name="topByViews" datasource="#dsn#" maxrows="5" username="#username#" password="#password#">
select	id, title, views, posted
from	tblblogentries
where 	tblblogentries.blog = <cfqueryparam cfsqltype="cf_sql_varchar" value="#blog#">
and		posted > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#sevendaysago#">
order by views desc
</cfquery>

<cfmodule template="../tags/adminlayout.cfm" title="Welcome">

	<cfoutput>
	<script>
	$(document).ready(function() {
		$("##latestversioncheck").html("<p>Checking to see if your blog is up to date. Please stand by...</p>").load("latestversioncheck.cfm")
	})
	</script>
	</cfoutput>
	
	<cfif structKeyExists(url, "reinit")>
		<cfoutput>
			<div style="margin: 15px 0; padding: 15px; border: 5px solid ##008000; background-color: ##80ff00; color: ##000000; font-weight: bold; text-align: center;">
				Your blog cache has been refreshed.
			</div>
		</cfoutput>
	</cfif>


	<cfoutput>
	<h3>About</h3>
	<p>
	Welcome to BlogCFC Administrator. You are running BlogCFC version #application.blog.getVersion()#. This blog is named
	#htmlEditFormat(application.blog.getProperty("blogtitle"))#. For more information, please visit the BlogCFC site at <a href="http://www.blogcfc.com">http://www.blogcfc.com</a>.
	BlogCFC was created by <a href="http://www.coldfusionjedi.com">Raymond Camden</a>. For support, please visit the <a href="http://groups.google.com/group/blogcfc">listserv</a>
	or send me an <a href="mailto:ray@camdenfamily.com">email</a>.
	</p>

	<div id="latestversioncheck">
	</div>
	
	<cfif topByViews.recordCount>
	<h3>Top Entries</h3>
	<p>
	Here are the top entries over the past seven days based on the number of views:
	</p>
	<p>
	<cfloop query="topByViews">
	<a href="#application.blog.makeLink(id)#">#title#</a> (#views#)<br/>
	</cfloop>
	</p>
	</cfif>

	<h3>Credits</h3>
	<p>
	BlogCFC has had the support and active help of <i>many</i> people. I'd like to especially thank Scott Stroz, Jeff Coughlin, Charlie Griefer, and Paul Hastings. BlogCFC
	makes use of <a href="http://lyla.maestropublishing.com/">Lyla Captcha</a> from Peter Farrell. Default spam protection provided by <a href="http://cfformprotect.riaforge.org/">CFFormProtect</a> by Jake Munson.
	</p>

	<h3>Support BlogCFC Development!</h3>
	<p>
	If you find this blog useful, please consider visiting my <a href="http://www.amazon.com/o/registry/2TCL1D08EZEYE">wishlist</a>.
	</p>
	</cfoutput>

</cfmodule>

<cfsetting enablecfoutputonly=false>
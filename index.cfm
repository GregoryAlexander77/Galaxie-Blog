<!doctype html>
<cfprocessingdirective suppressWhiteSpace="true">
<cfsilent>
	
<!---
	Name         	: index.cfm
	Author       	: Gregory Alexander
	Created/Updated : See GalaxieBlog GitHub repository
		 	
	Completely reengineered from scratch to make the code compatible as single page application.

Note: for html5, this doctype needs to be the first line on the page. (ga 10/27/2018) --->
<!--- When developing for Lucee you may want to place to following code on the first line to flush the cache. --->
<!---<cfset pagePoolClear()>--->
	
<!--- //******************************************************************************************************************
			Page settings.
//********************************************************************************************************************--->
	
<!--- Unique page settings that may vary on each different page. --->
<cfset pageId = 1>
<cfset pageName = "Blog"><!--- Blog --->
<cfset pageTypeId = 1><!--- Blog --->

<!--- Common and theme settings and includes the getMode tag in order to set the params for the getPost query. The pageSettings also determines when we should cache the page depending upon if the user is logged in. --->
<cfinclude template="#application.baseUrl#/includes/templates/pageSettings.cfm">
	
<!--- Note: I can't use conditional logic to separate the cfcache tags, which behave differently between ACF and Lucee. If I include the cfcache tag, they will cause an error even if a conditional block surrounds them. I need to use cfincludes instead. --->
</cfsilent>	
<cfif application.serverProduct eq 'Lucee'>
	<!--- Include the Lucee home template --->
	<cfinclude template="#application.baseUrl#/includes/lucee/home.cfm">
<cfelse>
	<!--- Include the ACF home template --->
	<cfinclude template="#application.baseUrl#/includes/acf/home.cfm">
</cfif>
<cfsilent>
	<!---//***************************************************************************************************************
				Tail end scripts
	//****************************************************************************************************************--->	
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/tailEndScripts.cfm" />
<!--- 
Note: if the Zion theme is screwed up, check the use custom theme setting in the ini file.
--->
</body>
</html>
</cfprocessingdirective>
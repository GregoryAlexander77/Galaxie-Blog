<!---
	Name         : blog\client\tags\getmode.cfm
	Author       : Raymond Camden/Gregory Alexander
	Created      : 02/09/06
	History      : Check GitHub
This tag sets the params that are sent to the getPost query. 
--->
<cfparam name="url.mode" default="">
<cfparam name="attributes.r_params" type="variableName">

<cfset params = structNew()>
<!--- 
	  SES parsing is abstracted out. This file is getting a bit large so I want to keep things nice and simple.
	  Plus if folks don't like this, they can just get rid of it.
	  Of course, the Blog makes use of it... but I'll worry about that later.
--->
<cfmodule template="parseses.cfm" /> 

<!--- //******************************************************************************************************************
			Set the start row for pagination
//********************************************************************************************************************--->
	
<cfparam name="url.startrow" default="1">
<cfif not isNumeric(url.startrow) or url.startrow lte 0 or round(url.startrow) neq url.startrow>
	<cfset url.startrow = 1>
</cfif>
	
<!--- Set the start row --->
<cfif not isValid("integer", url.startrow)>
	<cfset url.startrow = 1>
</cfif>
	
<cfset params.startrow = url.startrow>
<!--- Preset the maxEntries var. This will be reset to a higher value when looking at categories or reset to 1 when in alias or entry mode. --->
<cfset params.maxEntries = application.maxEntries>

<!--- //******************************************************************************************************************
			Delete previously set vars for day, month, year
//********************************************************************************************************************--->

<cfif isDefined("url.day") and (not isNumeric(url.day) or val(url.day) is not url.day)>
	<cfset structDelete(url,"day")>
</cfif>
<cfif isDefined("url.month") and (not isNumeric(url.month) or val(url.month) is not url.month)>
	<cfset structDelete(url,"month")>
</cfif>
<cfif isDefined("url.year") and (not isNumeric(url.year) or val(url.year) is not url.year)>
	<cfset structDelete(url,"year")>
</cfif>

<!--- //******************************************************************************************************************
			Determine the params based upon the page mode.
//********************************************************************************************************************--->
	
<cfif url.mode is "day" and isDefined("url.day") and isDefined("url.month") and url.month gte 1 and url.month lte 12 and isDefined("url.year")>
	<cfset params.byDay = val(url.day)>
	<cfset params.byMonth = val(url.month)>
	<cfset params.byYear = val(url.year)>
	<cfset month = val(url.month)>
	<cfset year = val(url.year)>
<cfelseif url.mode is "month" and isDefined("url.month") and url.month gte 1 and url.month lte 12 and isDefined("url.year")>
	<cfset params.byMonth = val(url.month)>
	<cfset params.byYear = val(url.year)>
	<cfset month = val(url.month)>
	<cfset year = val(url.year)>
<cfelseif url.mode is "category" and isDefined("url.categoryId")>
	<cfset params.byCat = url.categoryId>
	<!--- Since version 3.5ish, the blog now shows the posts as a card when in category or tag mode. Since the posts are condensed, we can show more of the posts. --->
<cfelseif url.mode is "tag" and isDefined("url.tagId")>
	<cfset params.byTag = url.tagId>
<cfelseif url.mode is "postedby" and isDefined("url.postedby")>
	<cfset params.byPosted = url.postedby>
<cfelseif url.mode is "search" and (isDefined("form.search") or isDefined("url.search"))>
	<cfif isDefined("url.search")>
		<cfset form.search = url.search>
	</cfif>
	<cfset params.searchTerms = encodeForHTML(form.search)>
	<!--- Dont log pages --->
	<cfif url.startrow neq 1>
		<cfset params.dontlogsearch = true>
	</cfif>
<cfelseif url.mode is "entry" and isDefined("url.entry")>
	<cfset params.byEntry = url.entry>
<cfelseif url.mode is "alias" and isDefined("url.alias") and len(trim(url.alias))>
	<cfset params.byAlias = url.alias>
<cfelse>
	<cfset url.mode = "full">
</cfif>

<!--- If user is logged in an has an admin role, then show all entries --->
<cfif application.Udf.isLoggedIn() and structKeyExists(url, "adminview") and url.adminview>
	<cfset params.releasedonly = false />
<!---// Ensures admins wont see unreleased on main page. //--->
<cfelse>
	<cfset params.releasedonly = true />
</cfif>

<cfset caller[attributes.r_params] = params>

<cfexit method="exitTag">

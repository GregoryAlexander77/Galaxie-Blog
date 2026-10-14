<cfcomponent output="false" hint="The cache folder holds generated page fragments that the blog reads itself (tags/galaxieCache.cfm). They are never requested directly (2026-10-14).">
	<cfset this.name = "galaxieCacheFolder">
	<cfset this.sessionManagement = false>
	<cfset this.clientManagement = false>
	<cffunction name="onRequestStart" returntype="boolean" output="false">
		<cfargument name="targetPage" type="string" required="true">
		<cfheader statuscode="404">
		<cfcontent reset="true"><cfabort>
	</cffunction>
</cfcomponent>

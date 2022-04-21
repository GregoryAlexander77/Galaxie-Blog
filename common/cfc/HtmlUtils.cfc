<cfcomponent displayname="HtmlUtils" hint="HTML utilities" name="HtmlUtils">
	
	<!--- Used to create alternating roles in HTML tables --->
	<cffunction name="getKendoClass" access="public" output="true" returntype="string" hint="Switches the Kendo class for the creation of alternating table rows">

		<cfargument name="previousKendoClass" required="yes" hint="What was the previous Kendo class or the prior row?">
			
		<!--- If the previous class is empty, the kendo class is k-content --->
		<cfif previousKendoClass eq '' or previousKendoClass eq 'k-alt'>
			<cfset kendoClass = 'k-content'>
		<cfelse>
			<cfset kendoClass = 'k-alt'>
		</cfif>
		
		<cfreturn kendoClass>
			
	</cffunction>
			
</cfcomponent>			
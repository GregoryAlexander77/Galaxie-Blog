<cfcomponent displayname="DateTime" hint="Cfc to work with dates." name="DateTime">
	
	<cffunction name="getBlogDateTime" access="public" output="false" returntype="date" hint="Gets the current time and adds or subtracts the number of timezones where the server is located at.">
		
		<!---<cfreturn dateAdd("h", instance.offset, now())>--->
	</cffunction>
							
</cfcomponent>
<cfcomponent displayname="Installer" sessionmanagement="yes" clientmanagement="yes" output="false">
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />
	
	<!--- Enable ORM if the database credentials are in the ini file. --->
	<cfset this.ormEnabled = "true">
		
</cfcomponent>

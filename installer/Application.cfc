<cfcomponent displayname="Installer" sessionmanagement="yes" clientmanagement="yes" output="true">
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />
	<cfset this.Name = "GalaxieBlogInstaller" /> 
	
	<!--- Enable ORM if the database credentials are in the ini file. --->
	<cfset this.ormEnabled = "true">
		
</cfcomponent>

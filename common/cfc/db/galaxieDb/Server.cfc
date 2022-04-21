<cfcomponent displayName="Server" persistent="true" table="Server" output="no" hint="ORM logic for the new Server table">
	
	<cfproperty name="ServerId" fieldtype="id" generator="native" setter="false">
	<!--- A blog can potentially have more than one server --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="ServerName" ormtype="string" default="This can be something genertic, like your hosting provider.">
	<cfproperty name="ServerTimeOffset" ormtype="int" default="0" hint="If you server is not in your timezone, set the time offset using the administrative interface.">	
	<cfproperty name="WebpImageSupported" ormtype="boolean" default="false">
	<cfproperty name="Woff2FontSupported" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
<cfcomponent displayName="Server" persistent="true" table="Server" output="no" hint="ORM logic for the new Server table">
	
	<cfproperty name="ServerId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="WebpImageSupported" ormtype="text" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
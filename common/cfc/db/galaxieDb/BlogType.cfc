<cfcomponent displayName="BlogType" persistent="true" table="BlogType" output="no" hint="ORM logic for the new BlogType table.">
	<cfproperty name="BlogTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogType" ormtype="string" default="" length="255">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp">
</cfcomponent>


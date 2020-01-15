<cfcomponent displayName="MainEntityOfPageType" persistent="true" table="MainEntityOfPageType" output="no" hint="ORM logic for the new MainEntityOfPageType table. This is used to with the StructuredData table to assign the MainEntityOfPage.">
	
	<cfproperty name="mainEntityOfPageTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="StructuredDataType" ormtype="string" default="" length="50" hint="The schema.org type. Currently supported values are blog, blogPosting, article, and custom.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
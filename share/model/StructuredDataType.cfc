<cfcomponent displayName="StructuredDataType" persistent="true" table="StructuredDataType" output="no" hint="ORM logic for the new StructuredDataType table.">
	
	<cfproperty name="StructuredDataTypeId" fieldtype="id" generator="native" setter="false">
	<!--- There is only one strucutured data type. --->
	<cfproperty name="StructuredDataTypeRef" ormtype="int" fieldtype="one-to-one" cfc="StructuredDataType" fkcolumn="StructuredDataTypeRef">
	<cfproperty name="StructuredDataType" ormtype="string" default="" length="50" hint="The schema.org type. Currently supported values are blog, blogPosting and article.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
<cfcomponent displayName="ContentOutput" persistent="true" table="ContentOutput" output="no" hint="ORM logic for the new ContentOutput table. This table will store the all of the various content by certain conditions, such as if the device is mobile.">
	
	<cfproperty name="ContentOutputId" fieldtype="id" generator="native" setter="false">
	<!--- Many content to one content template --->
	<cfproperty name="ContentTemplateRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplate" fkcolumn="ContentTemplateRef" cascade="all" missingrowignored="true" hint="Foreign Key to the ContentTemplate.ContentTemplateId">
	<!--- Each page can have its own unique content output --->
	<cfproperty name="PageRef" ormtype="int" hint="Foreign Key to the Page.PageId. I am not joining to the Page table it is easier to work without the join as I am also working with null values like so: WHERE ContentOutput.PageRef IS NULL OR ContentOutput.PageRef = 1. Also, this table is designed to have a bunch of records and having to join using objects will consume too many resources.">
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the ContentOutputTheme table as an intermediatory table to store the many to many relationships between a zone and a template. This is different than all of the other relationship types.---> 
	<cfproperty name="ThemeRef" ormtype="int" hint="Foreign Key to the Theme.ThemeId. Like the PageRef column above, I am not joining to the Theme table it is easier to work without the join as I am also working with null values like so: WHERE ContentOutput.ThemeRef IS NULL OR ContentOutput.ThemeRef = 1">
	
	<!--- These two columns are configured for Postgre. Manually change the text property if you use another db --->
	<cfproperty name="ContentOutput" ormtype="text" default="">
	<cfproperty name="ContentOutputMobile" ormtype="text" default="">
	
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="LastCached" ormtype="date" default="">
	<cfproperty name="Date" ormtype="timestamp">

	<!--- I am had problems generating this using ORM. Instead, I manually created the table using create table ContentOutput (ContentOutputId integer not null auto_increment, ContentOutput longtext,  ContentOutputMobile longtext, Active bit, LastCached date, `Date` date, ContentTemplateRef integer, primary key (ContentOutputId)) engine=InnoDB --->

</cfcomponent> 


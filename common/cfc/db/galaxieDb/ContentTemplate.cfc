<cfcomponent displayName="ContentTemplate" persistent="true" table="ContentTemplate" output="no" hint="ORM logic for the new ContentTemplate table. A content template is either a cfinclude that includes the template found in the content template URL, or HTML. A content template resides in a content zone.">
	
	<cfproperty name="ContentTemplateId" fieldtype="id" generator="native" setter="false">
	<!--- Many types to one template --->
	<cfproperty name="ContentTemplateTypeRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplateType" fkcolumn="ContentTemplateTypeRef" cascade="all" missingrowignored="true" hint="Foreign Key to the ContentTemplateType.ContentTemplateTypeId">
	<!--- Many pods to one template --->
	<cfproperty name="PodRef" ormtype="int" fieldtype="many-to-one" cfc="Pod" fkcolumn="PodRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Pod.PodId">
		
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the PageContentTemplate table as an intermediatory table to store the many to many relationships between a template and a page. This is different than all of the other relationship types.---> 
	<cfproperty name="Pages" singularname="Page" ormtype="int" fieldtype="many-to-many" cfc="Page" fkcolumn="ContentTemplateRef" inversejoincolumn="PageRef" linktable="PageContentTemplate" type="array" cascade="all" inverse="true" missingRowIgnored="true">
		
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the ContentTemplateContentZone table as an intermediatory table to store the many to many relationships between a zone and a template. This is different than all of the other relationship types.---> 
	<cfproperty name="ContentZones" singularname="ContentZone" ormtype="int" fieldtype="many-to-many" cfc="ContentZone" fkcolumn="ContentTemplateRef" inversejoincolumn="ContentZoneRef" linktable="ContentTemplateContentZone" type="array" cascade="all" inverse="true" missingRowIgnored="true">

	<!--- The Pods column below is a psuedo column that is used by this object. --->
	<cfproperty name="Pods" singularname="Pod" ormtype="int" fieldtype="one-to-many" cfc="Pod" fkcolumn="ContentTemplateRef" inversejoincolumn="PodRef" cascade="all" inverse="true" missingRowIgnored="true">
		
	<!--- The ContentOutput column below is a psuedo column that is used by this object. --->
	<cfproperty name="ContentOutput" singularname="Content" ormtype="int" fieldtype="one-to-many" cfc="ContentOutput" fkcolumn="ContentTemplateRef" inversejoincolumn="ContentOutputRef" cascade="all" inverse="true" missingRowIgnored="true">
		
	<cfproperty name="EnableContentTemplate" ormtype="boolean" default="true">
	<cfproperty name="ContentTemplateName" ormtype="string" length="125" default="">
	<cfproperty name="ContentTemplateDesc" ormtype="string" length="1200" default="">
	<cfproperty name="ParentTemplatePath" ormtype="string" length="240" default="">
	<cfproperty name="ContentTemplatePath" ormtype="string" length="240" default="">
	<cfproperty name="ContentTemplateUrl" ormtype="string" length="240" default="">
	<cfproperty name="CustomOutput" ormtype="boolean" default="false" hint="This changes from false to true when the owner wants to change the template path or create custom content using an output template.">
	<cfproperty name="ContentTemplateCacheName" ormtype="string" length="75" default="">
	<cfproperty name="ContentTemplateCachePath" ormtype="string" length="240" default="">
	<cfproperty name="LastCached" ormtype="date" default="">
	<cfproperty name="Cache" ormtype="boolean" default="true">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
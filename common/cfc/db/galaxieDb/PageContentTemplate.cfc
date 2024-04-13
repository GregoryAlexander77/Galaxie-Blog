<cfcomponent displayName="PageContentTemplate" persistent="true" table="PageContentTemplate" output="no" hint="ORM logic for the new PageContentTemplate table. This is used to indicate the content templates for a given page. This is a juntion table beween a page and a content template.">
	<!--- Note: this is a link table --->
	<cfproperty name="PageContentTemplateId" fieldtype="id" generator="native" setter="false">		
	<!--- There can be many pages and zones --->
	<cfproperty name="PageRef" ormtype="int" fieldtype="many-to-one" cfc="Page" fkcolumn="PageRef" cascade="all">
	<cfproperty name="ContentTemplateRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplate" fkcolumn="ContentTemplateRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

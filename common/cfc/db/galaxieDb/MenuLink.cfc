<cfcomponent displayName="MenuLink" persistent="true" table="MenuLink" output="no" hint="The blog owner's own links in the top menu's Menu dropdown (2026-10-10, Galaxie Blog 4.8) - eg. links between the owner's sites. Managed in the admin site's Configure Menu window; shown between the blog's own link and Contact by includes/templates/content/header/navigationMenu.cfm.">

	<cfproperty name="MenuLinkId" fieldtype="id" generator="native" setter="false">
	<!--- The blog's id as a plain number, not an ORM relationship: nothing needs to navigate from a link to its Blog, and a
	cascading many-to-one would put the Blog row at risk whenever a link is deleted. --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="Label" ormtype="string" length="125" default="">
	<cfproperty name="LinkUrl" ormtype="string" length="500" default="">
	<cfproperty name="NewWindow" ormtype="boolean" default="false" hint="Open the link in a new browser tab.">
	<cfproperty name="SortOrder" ormtype="int" default="0" hint="Lower numbers appear first.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>

<cfcomponent displayName="WebFormPost" persistent="true" table="WebFormPost" output="no" hint="A post or page that shows a form, its sign-up list or both below its text (2026-10-13), chosen under 'Show on' in the form editor. What shows is the form's ShowOnMode. Managed by common/cfc/WebForms.cfc.">

	<cfproperty name="WebFormPostId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc): deleting a form or a post must never cascade to the other. --->
	<cfproperty name="WebFormRef" ormtype="int" default="0">
	<cfproperty name="PostRef" ormtype="int" default="0">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>

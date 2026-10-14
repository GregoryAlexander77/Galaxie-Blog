<cfcomponent displayName="WebFormField" persistent="true" table="WebFormField" output="no" hint="One field of a WebForm, in display order (2026-10-13). See common/cfc/WebForms.cfc for the field types.">

	<cfproperty name="WebFormFieldId" fieldtype="id" generator="native" setter="false">
	<!--- The form's id as a plain number (see WebForm.cfc). --->
	<cfproperty name="WebFormRef" ormtype="int" default="0">
	<cfproperty name="Label" ormtype="string" length="255" default="">
	<!--- The key the value is stored under in WebFormSubmission.ValuesJson. Made from the label when the field is created, and
	kept when the label changes, so earlier submissions still line up with the field. --->
	<cfproperty name="FieldName" ormtype="string" length="100" default="">
	<!--- text, email, phone, number, textarea, select, radio, checkboxes, date, consent --->
	<cfproperty name="FieldType" ormtype="string" length="30" default="text">
	<cfproperty name="Required" ormtype="boolean" default="false">
	<cfproperty name="Placeholder" ormtype="string" length="255" default="">
	<cfproperty name="HelpText" ormtype="string" length="500" default="">
	<!--- The choices of a select, radio or checkboxes field, one per line. For a consent field, the text the person agrees to. --->
	<cfproperty name="Options" ormtype="string" length="2000" default="">
	<!--- Choice limits (2026-10-13): how many submissions may pick each choice of a select, radio or checkboxes field, as JSON,
	eg. {"Dessert":4,"Main dish":6}. Empty (or NULL on rows from before this column) means no limits. See WebForms.cfc. --->
	<cfproperty name="ChoiceLimits" ormtype="string" length="2000" default="">
	<!--- Shown in the form's public sign-up list (2026-10-13), when the form's PublicList is on. Never for email or phone fields. --->
	<cfproperty name="ShowPublic" ormtype="boolean" default="false">
	<cfproperty name="SortOrder" ormtype="int" default="0" hint="Lower numbers come first.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>

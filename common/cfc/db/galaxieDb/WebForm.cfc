<cfcomponent displayName="WebForm" persistent="true" table="WebForm" output="no" hint="A form the blog owner builds in the admin site (Forms) and places in a post or page - a signup form, a contact form, an RSVP or a booking's intake form (2026-10-13). Named WebForm, not Form, because FORM is a ColdFusion scope. Its fields are WebFormField rows, and what visitors send are WebFormSubmission rows. Managed by common/cfc/WebForms.cfc.">

	<cfproperty name="WebFormId" fieldtype="id" generator="native" setter="false">
	<!--- The blog's id as a plain number, not an ORM relationship (as in MenuLink.cfc): nothing needs to navigate from a form
	to its Blog, and a cascading many-to-one would put the Blog row at risk whenever a form is deleted. --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="Title" ormtype="string" length="125" default="">
	<!--- Unique per blog. Used to place the form in a post, so it doesn't change when the title does. --->
	<cfproperty name="Alias" ormtype="string" length="100" default="">
	<cfproperty name="Description" ormtype="string" length="1000" default="" hint="Optional text shown above the fields.">
	<cfproperty name="ButtonLabel" ormtype="string" length="50" default="Send">
	<cfproperty name="ConfirmationMessage" ormtype="string" length="2000" default="Thank you. Your form was sent.">
	<cfproperty name="ConfirmationUrl" ormtype="string" length="500" default="" hint="When set, the visitor is sent to this address instead of seeing the confirmation message.">
	<cfproperty name="NotifyEmails" ormtype="string" length="1000" default="" hint="Comma separated addresses emailed for each submission. Empty = the blog's own email address.">
	<cfproperty name="OfferSubscribe" ormtype="boolean" default="false" hint="Show an 'Email me new posts' checkbox; a person who checks it is added through the usual subscriber confirmation email.">
	<cfproperty name="RequireCaptcha" ormtype="boolean" default="true" hint="Ask for the blog's captcha. Checked on the server when the form is sent. Off for a form where accessibility matters most (an image captcha can't be read by a screen reader).">
	<cfproperty name="Active" ormtype="boolean" default="true" hint="An inactive form is not shown in posts and does not accept submissions.">
	<!--- On the site (2026-10-13). PublicList is the privacy switch: only when it is on can the form's sign-up list be shown, with
	the fields marked WebFormField.ShowPublic. ShowOnMode is what appears on the posts the form is assigned to (WebFormPost):
	form, formAndList or list; the two with a list need PublicList. NULL on rows from before these columns = off / form. --->
	<cfproperty name="PublicList" ormtype="boolean" default="false">
	<cfproperty name="ShowOnMode" ormtype="string" length="20" default="form">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>

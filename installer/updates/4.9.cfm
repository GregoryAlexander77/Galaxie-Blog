<!--- description: Makes sure the tables for Forms exist (WebForm, WebFormField and WebFormSubmission). ORM normally creates them when the blog restarts after the upload; if one is missing, this sets the column types for the database and reloads ORM to create it. Forms start empty, so there is nothing to fill in. Safe to run more than once. --->
<!--- The work is done by DatabaseUpdater.cfc's ensureOrmTables(). Add anything else this version needs below it. --->
<cfset ensureOrmTables("WebForm,WebFormField,WebFormSubmission")>

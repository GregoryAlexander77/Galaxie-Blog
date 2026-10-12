<!---
	This template saves the datasource and the type of database from step 4 (in the session and in the ini file) and continues on to the user profile step. It has no user interface.

	It replaces the step that used to have the person installing the blog copy a different set of ORM entity files over the ones in /common/cfc/db/galaxieDb/ when the database was not SQL Server. Each database vendor declares 'long text' columns differently (varchar(max), longtext, clob...) and that is the only thing that differs between the entities for the different databases. The Application.cfc in the blog's root now sets those column types automatically, using the databaseType that is saved here, before ORM reads the entities (see DatabaseOrmTypes.cfc). The installer does not need to do anything for that to happen.
--->
<cfsilent>

<cfif not structKeyExists(Form, "dsn") or not structKeyExists(Form, "databaseType")>
	<cflocation url="step4Dsn.cfm" addToken="false">
</cfif>

<!--- Make sure that the datasource was entered, exists, connects, and is not the database of a blog that already exists, before saving it (see dsnCheck.cfm). A wrong or missing datasource used to be saved anyway, and the blog then failed after the user profile step with only a generic "This site is not available right now" page (found in the 4.8 install test, 2026-10-11) - and a datasource of a blog that was already running on the same server was used to install into, overwriting that blog's settings (2026-10-12). --->
<cfinclude template="dsnCheck.cfm">
<cfset dsnProblem = getInstallDsnProblem(Form.dsn)>
<cfif len(dsnProblem)>
	<cfset session.dsnError = dsnProblem>
	<cfset session.dsnErrorValue = trim(Form.dsn)>
	<cflocation url="step4Dsn.cfm" addToken="false">
</cfif>
<cfset structDelete(session, "dsnError")>
<cfset structDelete(session, "dsnErrorValue")>

<!--- Save the values in the session --->
<cfset session.dsn = trim(Form.dsn)>
<cfset session.databaseType = Form.databaseType>

<!--- Save the values in the ini file --->
<cfset setProfileString(application.iniFile, "default", "dsn", trim(Form.dsn))>
<cfset setProfileString(application.iniFile, "default", "databaseType", Form.databaseType)>

</cfsilent>
<cflocation url="step6UserProfile.cfm" addToken="false">

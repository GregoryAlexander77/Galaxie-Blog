<!---
	This template saves the datasource and the type of database from step 4 (in the session and in the ini file) and continues on to the user profile step. It has no user interface.

	It replaces the step that used to have the person installing the blog copy a different set of ORM entity files over the ones in /common/cfc/db/galaxieDb/ when the database was not SQL Server. Each database vendor declares 'long text' columns differently (varchar(max), longtext, clob...) and that is the only thing that differs between the entities for the different databases. The Application.cfc in the blog's root now sets those column types automatically, using the databaseType that is saved here, before ORM reads the entities (see DatabaseOrmTypes.cfc). The installer does not need to do anything for that to happen.
--->
<cfsilent>

<cfif not structKeyExists(Form, "dsn") or not structKeyExists(Form, "databaseType")>
	<cflocation url="step4Dsn.cfm" addToken="false">
</cfif>

<!--- Save the values in the session --->
<cfset session.dsn = Form.dsn>
<cfset session.databaseType = Form.databaseType>

<!--- Save the values in the ini file --->
<cfset setProfileString(application.iniFile, "default", "dsn", Form.dsn)>
<cfset setProfileString(application.iniFile, "default", "databaseType", Form.databaseType)>

</cfsilent>
<cflocation url="step6UserProfile.cfm" addToken="false">

<html lang="en-US"><head> <title>ORM/Hibernate Setup</title>
<cfsilent>

<!--- Save the DSN in the ini file. --->
<cfif structKeyExists(Form, "dsn")>
	<!--- Set session vars from the form. I am assuming that this block of logic is consumed when the user hits the back button. --->
	<cfset session.dsn = Form.dsn>
	<cfset session.databaseType = Form.databaseType>
		
	<!--- Set the values in the ini file --->
	<cfset setProfileString(application.iniFile, "default", "dsn", Form.dsn)>
<cfelse>
	<!--- Redirect to the previous page. --->
	<cflocation url="dsn.cfm">
</cfif>
	
<cfif isDefined("Form.databaseType")>
	<cfset databaseType = Form.databaseType>
	<cfset session.databaseType = Form.databaseType>
		
	<!--- Determine the files that we need to have the user replace --->
	<cfset dbCfcFilePath = session.basePath & "common/cfc/galaxieDb/" & databaseType>
	<cfset newDbCfcFilePath = session.basePath & "installer/databaseOrmFiles/" & databaseType>
		
	<!--- Save these paths to the session --->
	<cfset session.dbCfcFilePath = dbCfcFilePath>
	<cfset session.newDbCfcFilePath = newDbCfcFilePath>
		
	<!--- See if the database type is SQL Server --->
	<cfif databaseType eq 'SqlServer'>
		<cfset databaseOk = true>
	<cfelse>
		<cfset databaseOk = false>
	</cfif>
	<!--- Save it to the session --->
	<cfset session.databaseOk = databaseOk>
	<!--- Store the DSN in the ini file --->
	<cfset setProfileString(application.iniFile, "default", "databaseType", Form.databaseType)>
<cfelse>
	<!--- Redirect to the previous page. --->
	<cflocation url="step4Dsn.cfm">
</cfif>
</cfsilent>
<!---<cfoutput>#directory# #extendsPath# #extendsStr#</cfoutput>--->

<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="ORM Setup" />
<cfsilent>
<cfparam name="kendoTheme" default="default">
</cfsilent>
<html>
<head>
    <style>html { font-size: 14px; font-family: Arial, Helvetica, sans-serif; }</style>
    <title></title>
    <link rel="stylesheet" href="https://kendo.cdn.telerik.com/2020.3.1021/styles/kendo.common.min.css" />
	<!--- Attach the style for the theme --->
	<a href=""></a>
    <cfoutput>
	<link rel="stylesheet" href="../../common/libs/kendoCore/styles/kendo.#kendoTheme#.min.css" />
    <link rel="stylesheet" href="../../common/libs/kendoCore/styles/kendo.#kendoTheme#.mobile.min.css" />
	</cfoutput>

    <script src="../../common/libs/kendoCore/js/jquery.min.js"></script>
    <script src="../../common/libs/kendoCore/js/kendo.ui.core.min.js"></script>
	
	<script type="text/javascript" src="../../common/libs/momentJs/moments.js"></script>
</head>
<style>
	
	/* Table classes */
	/* Applies a border on the outside of the table */
	table.tableBorder {
		border: 1px solid black;
		width: 100%;
		border-radius: 3px; 
		border-spacing: 0;
	}
	
	td.border {
		border-top: 1px solid #ddd;
	}
	
	label {
		font-weight: 400;
	}
	
	p {
		font-weight: 400;
	}
</style>
<body>
<script src="//cdnjs.cloudflare.com/ajax/libs/jszip/2.4.0/jszip.min.js"></script>

<form action="step6UserProfile.cfm" method="post">
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="5">
	<tr>
		<td>
			<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-header border"></td>
			  </tr>
			  <tr>
				  <td align="left" valign="top" colspan="2" class="k-header" style="font-weight: bold">
					<cfif databaseOk>
						Database Mapping Check
					<cfelse>
						Please upload new database related files
					</cfif>
					<br/>(Step 5 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td style="width:400px">
				  	<img src="../images/receiver.jpg" alt="Site Information" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
				  <cfif databaseOk>
					<p>Your SQL Server database is supported with this version of Galaxie Blog.</p>
					<p>
					  Important note: this Blog is DBMS data independent and using ColdFusion ORM. If you make database changes, such as changing a column length, you will also need to also change the mapping definitions in the <cfoutput>#newDbCfcFilePath#</cfoutput> folder. If you decide to change your database from SQL Server to a another database at a later time, such as migrating to MySql, you should re-run this installer. 
					</p>
					<p>Please click the button at the bottom of the page to continue.</p>
				  <cfelse>
				    <p>
					 We are using ColdFusion ORM and the mapping files are different depending upon the database. We are using a variable length text field in the database to hold the contents of the post along with other long strings. Unfortunately, these variable length text fields differ for each database vendor. In order to make your chosen database work, we need you to locate the specific database files and upload them to your server overwriting the default files that work with Sql Server. All of the steps required to acheived this are listed below.  
					</p>

					<ul>
						<li>Please open the <cfoutput>#newDbCfcFilePath#</cfoutput> folder found in this installation.</li>
						<li>Copy all of the files in this directory. The files should be:
							<ul>
								<li>Comment.cfc</li>
								<li>Container.cfc</li>
								<li>PodContainer.cfc</li>
								<li>Post.cfc</li>
								<li>Users.cfc</li>
							</ul>
						</li>
						<li>Paste these files into the <cfoutput>#dbCfcFilePath#</cfoutput> directory and over-write the orginal Sql Server specific files.</li>
						<li>Upload the new files in the <cfoutput>#dbCfcFilePath#</cfoutput> to your server.</li>
					</ul>
					<p>When you are done, click the button below to continue.</p>
				</cfif>  
				</td>
			</tr>
			<tr>
				<td><input type="submit" value="Continue" class="k-button k-primary" /></td>
			</tr>
		  </table>
		</td>
	</tr>
</table>
</form>
	
<!---
Notes:
DBMS independent variable text 
VARCHAR(max): MS SQL Server
NVARCHAR(max): MS SQL Server
LONGVARCHAR: Derby, H2, HSQLDB
CLOB: Derby, H2, HSQLDB, Oracle, SQLite
TEXT: Oracle
TEXT: MS SQL Server, MySQL, PostgreSQL, SQLite
--->
	
<!--- Note: this function is in other places, but I need to get it here as the app vars are not there yet.  --->
<cffunction name="parseUri" returntype="struct" output="false" hint="Splits any well-formed URI into its components">
	<cfargument name="sourceUri" type="string" required="no" default=""/>

	<!--- If the sourceUri is not passed, use the CGI.HTTP_URL --->
	<cfif not len(arguments.sourceUri)>
		<cfset arguments.sourceUri = CGI.HTTP_URL>
	</cfif>

	<!--- Create an array containing the names of each key we will add to the uri struct --->
	<cfset var uriPartNames = listToArray("source,protocol,authority,userInfo,user,password,host,port,relative,path,directory") />
	<!--- Full list: source,protocol,authority,userInfo,user,password,host,port,relative,path,directory,file,query,anchor --->
	<!--- Get arrays named len and pos, containing the lengths and positions of each URI part (all are optional) --->
	<cfset var uriParts = reFind("^(?:(?![^:@]+:[^:@/]*@)([^:/?##.]+):)?(?://)?((?:(([^:@]*):?([^:@]*))?@)?([^:/?##]*)(?::(\d*))?)(((/(?:[^?##](?![^?##/]*\.[^?##/.]+(?:[?##]|$)))*/?)?([^?##/]*))(?:\?([^##]*))?(?:##(.*))?)",
		sourceUri, 1, true) />
	<cfset var uri = structNew() />
	<cfset var i = 1 />

	<cfloop index="i" from="1" to="#arrayLen(uriPartNames)#">
		<!--- If the part was found in the source URI...
		- The arrayLen() check is needed to prevent a CF error when sourceUri is empty due to a bug,
		  reFind() does not populate backreferences for zero-length capturing groups when run against an empty string
		  (though it does still populate backreference 0).
		- The pos[i] value check is needed to prevent a CF error when mid() is passed a start value of 0, because of
		  the way reFind() considers an optional capturing group that does not match anything to have a pos of 0. --->
		<cfif (arraylen(uriParts.pos) GT 1) AND (uriParts.pos[i] GT 0)>
			<!--- Add the part to its corresponding key in the uri struct --->
			<cfset uri[uriPartNames[i]] = mid(sourceUri, uriParts.pos[i], uriParts.len[i]) />
		<!--- Otherwise, set the key value to an empty string --->
		<cfelse>
			<cfset uri[uriPartNames[i]] = "" />
		</cfif>
	</cfloop>

	<!--- Always end directory with a trailing backslash if a path was present in the source URI.
	Note that a trailing backslash is NOT automatically inserted within or appended to the relative or path parts --->
	<cfif len(uri.directory) gt 0>
		<cfset uri.directory = reReplace(uri.directory, "/?$", "/") />
	</cfif>

	<cfreturn uri />
</cffunction>
<html lang="en-US"><head> <title>DSN and Database Vendor</title>
<cfsilent>
<!--- We don't need to store anything from the extend application template --->
<!--- Get the current form data from the ini file if possible. This is done as the user may come back to this page. --->
<cfset dsn = getProfileString(application.iniFile, "default", "dsn")>
<cfset databaseType = getProfileString(application.iniFile, "default", "databaseType")>
</cfsilent>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="Enter DSN and Database Vendor" />
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
</style>
<body>
<script src="//cdnjs.cloudflare.com/ajax/libs/jszip/2.4.0/jszip.min.js"></script>
	
<!---<cfoutput>blogUrl: #blogUrl#</cfoutput>--->
<form action="step5OrmSetup.cfm" name="dsnSetup" id="dsnSetup" method="post">
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
					Database DSN Credentials<br/>
					(Step 4 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td style="width:400px">
				  	<img src="../images/step2.jpg" alt="Welcome!" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
					  
					  <table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
							<td></td>
							<td align="left" style="vertical-align:middle">
							  Please create an <b>empty</b> database and create a ColdFusion Datasource for the new database. You can use <b>any modern</b> database that you wish, however, ensure this DSN and database exists!
							</td>
						</tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
							<td align="right" valign="middle" style="width:175px;vertical-align:middle">
								DSN:
							</td>
							<td align="left" style="vertical-align:middle">
							  <input type="text" id="dsn" name="dsn" class="k-textbox" style="width:45%" value="<cfoutput>#dsn#</cfoutput>" required>
							</td>
						</tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
					    <tr>
							<td></td>
						  	<td align="left" valign="middle">
								<p>This blog <i>should</i> work with the databases listed in the dropdown below *.</p> 
								<p>While not officially unsupported, you <b>may</b> be able to use a different database that is not in the list, but you will need to manually modify the <cfoutput>#session.basePath#</cfoutput>Application.cfc file and enter the fully qualified class name of the database dialect in the databaseDialect field. You will also need to do a search any strings labeled 'varchar(max)' and replace them with the proper variable length text field that is used by the chosen database (ie 'clob' or 'lob' for example).</p>
								<p>* See notes on next page</p>
						  	</td>
					    </tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
							<td align="right" valign="middle" style="width:175px;vertical-align:middle">
							Database Vendor:
							</td>
							<td align="left" style="vertical-align:middle">
							  <script>
								$(document).ready(function() {
									// create DropDownList from select HTML element
									$("#databaseType").kendoDropDownList();
								});
							  </script>
							  <select name="databaseType" id="databaseType" style="width:50%">
								<option value="apacheDerby">Apache Derby</option>
								<option value="db2">DB2 (all versions)</option>
								<!---<option value="Informix">Informix</option>--->
								<option value="sqlServer">Microsoft Access</option>
								<option value="SqlServer" selected>MS Sql Server</option>
								<option value="mySql">MySQL (any version)</option>
								<option value="oracle">Oracle (any version)</option>
								<option value="postgre">Postgre SQL</option>
								<option value="sybase">Sybase</option>
							  </select>
								
							  <!--- More comprehensive list to be used in a later version:
								<option value="auto" selected>Auto-Detect (works with all major databases)</option>
								<option value="DB2">DB2 (all versions)*</option>
								<option value="Derby">Apache Derby</option>
								<option value="org.hibernate.dialect.FirebirdDialect">Firebird</option>
								<option value="org.hibernate.dialect.FrontbaseDialect">FrontBase</option>
								<option value="org.hibernate.dialect.H2Dialect">H2 Database</option>
								<option value="org.hibernate.dialect.HSQLDialect">Hypersonic SQL</option>
								<option value="org.hibernate.dialect.IngresDialect">Ingres</option>
								<option value="Informix">Informix*</option>
								<option value="org.hibernate.dialect.InterbaseDialect">Interbase</option>
								<option value="org.hibernate.dialect.MckoiDialect">Mckoi SQL</option>
								<option value="MicrosoftSQLServer">Microsoft Access</option>
								<option value="SqlServer">MS Sql Server</option>
								<option value="org.hibernate.dialect.MySQLDialect">MySql*</option>
								<option value="MySql">MySQL (any version)*</option>
								<option value="Oracle">Oracle (any version)*</option>
								<option value="org.hibernate.dialect.PointbaseDialect">Pointbase</option>
								<option value="Postgre">Postgre SQL*</option>
								<option value="org.hibernate.dialect.ProgressDialect">Progress</option>
								<option value="org.hibernate.dialect.SAPDBDialect">SAP DB</option>
								<option value="Sybase">Sybase*</option>
							  --->
							</td>
						</tr>
						<!-- Border -->
					    <tr height="2px">
						  	<td align="left" valign="middle" colspan="2" class="k-content border"></td>
					    </tr>
						<tr>
						  <td></td>
						  <td>
							  <input type="submit" value="Continue" class="k-button k-primary" />
					 	  </td>
						</tr>
					</table> 
				  </td>
			  </tr>
			</table>
		</td>
	</tr>
</table>
</form>

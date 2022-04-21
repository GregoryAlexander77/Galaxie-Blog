<html lang="en-US"><head> <title>General Site Information</title>
<cfsilent>
<!--- Determine if the SSL should be checked as default. --->
<cfif cgi.https eq 'on'>
	<cfset sslChecked = true>
<cfelse>
	<cfset sslChecked = false>
</cfif>
	
<!--- Craft the suggested site url --->
<cfset siteUrl = replaceNoCase(CGI.http_referer, '/installer/initial', '', 'all')>
<!--- Take out the URL argument --->
<cfset siteUrl = replaceNoCase(siteUrl, '?notInstalled', '', 'all')>

<!--- We are storing the info in the session as the user may click on the back button or try again. --->
<cfif isDefined("session.blogUrl")>
	<cfset blogUrl = session.blogUrl>
	<cfset useSsl = session.useSsl>
<cfelse>
	<cfset blogUrl = siteUrl>
	<cfset useSsl = "">
</cfif>
	
<cfif isDefined("session.blogTitle")>
	<cfset blogTitle = session.blogTitle>
<cfelse>
	<cfset blogTitle = "">
</cfif>
</cfsilent>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="Welcome to Galaxie Blog" />
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

<form action="step3ExtendApp.cfm" method="post"><!---step3Dsn.cfm--->
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
					General Site Information<br/>
					(Step 2 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td style="width:400px">
				  	<img src="../images/siteInfo.jpg" alt="Site Information" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
					  
					  <table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
						<!-- Border -->
						<tr height="2px">
							<td align="left" valign="middle" colspan="2" class="k-content border"></td>
						</tr>
						<tr>
							<td align="left" colspan="2">
							  Are you using SSL? Using SSL requires a server SSL certificate and uses a <b>https://</b> prefix in front of the URL. This allows the traffic on your website to be encypted for security. It is <b>highly recommended</b> that you use SSL as some of the libraries that we use require SSL and it greatly improves site security. However, you can still use this blog software without SSL and enable it at a later time.
							</td>
						</tr>
						<tr>
							<td align="right" valign="middle" style="width:175px;vertical-align:middle" class="k-content">
								<label for="useSsl">Are you using SSL?</label>
							</td>
							<td align="left" style="vertical-align:middle" class="k-content">
								<input type="checkbox" name="useSsl" id="useSsl" value="1" <cfif sslChecked>checked</cfif>>
							</td>
						</tr>
						<!-- Border -->
						<tr height="2px">
							<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
						</tr>
						<tr>
							<td align="left" colspan="2" class="k-alt" style="font-weight: 400;">
							  <p>Before we continue, you must let the software know what link you are using. It is critical that you enter this correctly otherwise the blog will have errors. Please enter the site URL that you are using with the proper URL prefix.</p> 
							</td>
						</tr>
						<!-- Border -->
						<tr height="2px">
							<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
						</tr>
						<tr valign="middle" height="30px">
						  <td align="right" valign="middle" width="10%" class="k-alt">
							<label for="blogUrl">Blog URL</label>
						  </td>
						  <td align="left" width="90%" class="k-alt">
							<input id="blogUrl" name="blogUrl" type="url" value="<cfoutput>#blogUrl#</cfoutput>" required validationMessage="URL is required" class="k-textbox" style="width: 66%" /> 
						  </td>
						</tr>
						<!-- Border -->
						<tr height="2px">
							<td align="left" valign="middle" colspan="2" class="k-alt border"></td>
						</tr>
						<tr valign="middle" height="30px">
						  <td align="right" valign="middle" width="10%" class="k-content">
							<label for="blogTitle">Blog Title</label>
						  </td>
						  <td align="left" width="90%" class="k-content">
							<input id="blogTitle" name="blogTitle" type="text" value="<cfoutput>#blogTitle#</cfoutput>" required validationMessage="URL is required" class="k-textbox" style="width: 66%" /> 
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
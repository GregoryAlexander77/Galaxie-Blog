<html lang="en-US"><head> <title>Extending the administrative Application.cfc</title>
<cfsilent>
	
<!--- Save the blogUrl and useSsl from the previous page. --->
<!--- Use SSL is a checkbox and may not exist --->
<cfif structKeyExists(Form, "useSsl") or Form.blogUrl contains 'https'>
	<cfset useSsl = true>
<cfelse>
	<cfset useSsl = false>
</cfif>
<!--- Save it in the session --->
<cfset session.useSsl = useSsl>
<!--- Save the data to the ini file --->
<cfset setProfileString(application.iniFile, "default", "useSsl", useSsl)>

<!--- Save the title --->
<cfif structKeyExists(Form, "blogTitle")>
	<cfset blogTitle = blogTitle>
	<!--- Save it in the session --->
	<cfset session.blogTitle = blogTitle>
	<!--- Save the data to the ini file --->
	<cfset setProfileString(application.iniFile, "default", "blogTitle", blogTitle)>
<cfelse>
	<cflocation url="siteInfo.cfm">
</cfif>

<!--- Handle the blog URL --->
<cfif structKeyExists(Form, "blogUrl")>
	
	<cfset session.blogUrl = Form.blogUrl>
	
	<!--- If we are using SSL, check to see if there is a https:// prefix--->
	<cfif useSsl and Form.blogUrl contains 'https://'>
		<cfset blogUrl = blogUrl>
	<cfelse>
		<cfif blogUrl contains 'http://'>
			<cfset blogUrl = replaceNoCase(blogUrl, 'http', 'https')>
		<cfelse>
			<cfset blogUrl = 'https://' & blogUrl>
		</cfif>
	</cfif>
	
	<!--- The blogUrl must contain a .cfm --->
	<cfif blogUrl contains '/index.cfm'>
		<cfset blogUrl = blogUrl>
	<cfelse>
		<cfset blogUrl = blogUrl & "/index.cfm">
	</cfif>
	<!--- Save it in the session --->
	<cfset session.blogUrl = blogUrl>
	<!--- Now save the data to the ini file --->
	<cfset setProfileString(application.iniFile, "default", "blogUrl", blogUrl)>
		
	<!--- Get the directory. We need this to recommend the correct extends argument. --->
	<cfset directory = parseUri(blogUrl).directory>
	<!--- Remove the first forward slash in the directory. --->
	<cfset basePath = replace(directory, '/', '', 'one')>
	<!--- Replace forward slashes with dots --->
	<cfset extendsPath = replace(basePath, '/', '.', 'all')>
		
	<!--- If the extends path is empty, the installation took place in the root directory and we need to extend the root Proxy.cfc --->
	<cfif not len(extendsPath)>
		<cfset extending = 'root'>
		<cfset extendsStr = 'Proxy'>
	<cfelse>
	<!--- Extend using the ApplicationProxy --->
		<cfset extending = replaceNoCase(basePath, '/', '', 'all') & ' subdirectory'>
		<!--- Append the directory with 'Application' --->
		<cfset extendsStr = extendsPath & 'Application'>
	</cfif>
	<!--- Save this to the sesion. --->
	<cfset session.extendsStr = extendsStr>

	<cfif extendsStr eq 'blog.Application'>
		<cfset extendsStrOk = true>
	<cfelse>
		<cfset extendsStrOk = false>
	</cfif>

	<!--- Save the vars to the session --->
	<cfset session.basePath = basePath>
	<cfset session.extendsStrOk = extendsStrOk>

<cfelse>
	<cflocation url="siteInfo.cfm">
</cfif>
</cfsilent>
<!---<cfoutput>#directory# #extendsPath# #extendsStr#</cfoutput>--->

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

<form action="step4Dsn.cfm" method="post"><!---step3Dsn.cfm--->
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
					<!---
					<cfif session.extendsStrOk>
						Application extends check.
					<cfelse>
						Change one line of code to extend the application.
					</cfif>
					--->
					Application Extends Note.
					<br/>(Step 3 of 6)
				  </td>
			  </tr>
			  <!-- Border -->
			  <tr height="2px">
				  <td align="left" valign="top" colspan="2" class="k-content border"></td>
			  </tr>
			  <tr>
				  <td style="width:400px">
				  	<img src="../images/docking.jpg" alt="Site Information" style="float: left; padding:5px;">
				  </td>
				  <td align="left" valign="top">
				  <p>
					  Note: the extends argument is hardcoded in the ApplicationProxyReference.cfc to extend the root Proxy.cfc. <b>Everything is set and you should need to do anything</b>, but I have noticed that the extends logic is not bullet proof with all of the various server setups. If you can't get into the Administrator please let me know either by creating a new GIT issue or emailing me and I will get back to you promptly. I have been through this quite a few times now and will have some ideas.
				  </p>
				  <p>Please click on button at the bottom of the page to continue.</p> 
				  <!---
					<cfif session.extendsStrOk>
					<p>
					  Note: the extends argument is hardcoded in the ApplicationProxyReference.cfc to extend the parent Application.cfc to the Admin/Application.cfc. <b>Everything is set and you don't need to do anything</b>, but <b>if</b> you change your folder structure at a later time you will need to change the folder name (ie 'blog') with the new folder that you changed.
					</p>
					<p>Please click on button at the bottom of the page to continue.</p>
				  <cfelse>
				    <p>
					 We need you to add the folder name to one word of code to extend the core application logic. We have tried to perform this programatically, but unfortunately, there is no reliable way to extend our application code with all of the various ColdFusion configurations. Here, we are just appending the folder name with a '.Application' if your site is in a subfolder. You will not need to make any more manual code adjustments to install the blog. 
					</p>
					<ul>
						<li>Please open the ApplicationProxyReference.cfc template in the /admin/ folder.</li>
						<li>On the very first line of code locate the extends="blog.Application" string.</li>
						<li>Change this extends argument from 'blog.Application' to <cfoutput><b>#extendsStr#</b></cfoutput> and save the file.</li>
						<li>Upload this file to your server.</li>
					</ul>
				</cfif>
				--->
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
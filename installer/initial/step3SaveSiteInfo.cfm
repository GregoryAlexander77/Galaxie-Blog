<!---
	This template saves the general site information from step 2 (in the session and in the ini file) and continues on to the database step. It has no user interface.

	It replaces the step that used to have the person installing the blog edit the 'extends' string in /admin/ApplicationProxyReference.cfc. That was required because the admin folder had its own Application.cfc that had to extend the blog's Application.cfc, and the path to it depended on where the blog was placed (in the root, in a folder named 'blog', or in any other folder). The admin folder no longer has an Application.cfc; the admin site's settings are applied by the Application.cfc in the blog's root directory (see isAdminRequest() in that file), so there is nothing left to configure.
--->
<cfsilent>

<!--- We need the form data from step 2 --->
<cfif not structKeyExists(Form, "blogTitle") or not structKeyExists(Form, "blogUrl")>
	<cflocation url="step2SiteInfo.cfm" addToken="false">
</cfif>

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
<cfset blogTitle = Form.blogTitle>
<cfset session.blogTitle = blogTitle>
<cfset setProfileString(application.iniFile, "default", "blogTitle", blogTitle)>

<!--- Handle the blog URL --->
<cfset session.blogUrl = Form.blogUrl>

<!--- If we are using SSL, check to see if there is a https:// prefix--->
<cfif useSsl and Form.blogUrl contains 'https://'>
	<cfset blogUrl = Form.blogUrl>
<cfelse>
	<cfif Form.blogUrl contains 'http://'>
		<cfset blogUrl = replaceNoCase(Form.blogUrl, 'http', 'https')>
	<cfelse>
		<cfset blogUrl = 'https://' & Form.blogUrl>
	</cfif>
</cfif>

<!--- The blogUrl must contain a .cfm --->
<cfif blogUrl contains '/index.cfm'>
	<cfset blogUrl = Form.blogUrl>
<cfelse>
	<cfset blogUrl = Form.blogUrl & "/index.cfm">
</cfif>
<!--- Save it in the session --->
<cfset session.blogUrl = blogUrl>
<!--- Now save the data to the ini file --->
<cfset setProfileString(application.iniFile, "default", "blogUrl", blogUrl)>

</cfsilent>
<cflocation url="step4Dsn.cfm" addToken="false">

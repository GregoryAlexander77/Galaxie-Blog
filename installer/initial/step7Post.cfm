<!--- Only continue with a datasource that was entered, exists, connects and is not an existing blog's database (see dsnCheck.cfm). Going straight to this page without one goes back to step 4. --->
<cfsilent>
<cfinclude template="dsnCheck.cfm">
<cfset dsnProblem = getInstallDsnProblem(getProfileString(application.iniFile, "default", "dsn"))>
<cfif len(dsnProblem)>
	<cfset session.dsnError = dsnProblem>
	<cflocation url="step4Dsn.cfm" addToken="false">
</cfif>
</cfsilent>
<cfif structKeyExists(Form, "userName")>
	<!--- Set session vars from the form. I am assuming that this block of logic is consumed when the user hits the back button. --->
	<cfset session.firstName = Form.firstName>
	<cfset session.lastName = Form.lastName>
	<cfset session.profileDisplayName = Form.profileDisplayName>
	<cfset session.email = Form.email>
	<cfset session.website = Form.website>
	<cfset session.userName = Form.userName>
	<cfset session.password = Form.password>
	<cfset session.confirmPassword = Form.confirmPassword>
	<cfset session.securityAnswer1 = Form.securityAnswer1>
	<cfset session.securityAnswer2 = Form.securityAnswer2>
	<cfset session.securityAnswer3 = Form.securityAnswer3>

	<!--- Save user credentials in the ini file. --->
	<cfset setProfileString(application.iniFile, "default", "firstName", Form.firstName)>
	<cfset setProfileString(application.iniFile, "default", "lastName", Form.lastName)>
	<cfset setProfileString(application.iniFile, "default", "profileDisplayName", Form.profileDisplayName)>
	<cfset setProfileString(application.iniFile, "default", "email", Form.email)>
	<cfset setProfileString(application.iniFile, "default", "website", Form.website)>
	<cfset setProfileString(application.iniFile, "default", "userName", Form.userName)>
	<cfset setProfileString(application.iniFile, "default", "password", Form.password)>
	<cfset setProfileString(application.iniFile, "default", "securityAnswer1", Form.securityAnswer1)>
	<cfset setProfileString(application.iniFile, "default", "securityAnswer2", Form.securityAnswer2)>
	<cfset setProfileString(application.iniFile, "default", "securityAnswer3", Form.securityAnswer3)>
		
	<!--- Redirect to the home page with a URL init argument in order to build the initial database and pass in a URL argument to continue processing the install using insertData.cfm. We can't use in include here as the page needs to be refreshed to initialize orm after we have written the datasource into the ini file. After the database is installed, code in the Application.cfm template will then redirect the user to the /installer/step6UserProfile.cfm page. --->
	<cflocation url="../../index.cfm?init=1&install=true">
<cfelse>
	<!--- Redirect to the previous page. --->
	<cflocation url="step6UserProfile.cfm">
</cfif>


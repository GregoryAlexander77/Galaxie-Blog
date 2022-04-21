<cfsilent>
<cfset qs = cgi.query_string>
<cfset qs = reReplace(qs, "logout=[^&]+", "")>
<!--- Include our string utils object to trim strings --->
<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
</cfsilent>

<!--- Forms that hold state. --->
<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>
	
<div id="pagePanel" class="panel">
	<cfsilent>
	<!--- 
	Wide div in the center left of page.
	Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div 
	are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
	--->
	</cfsilent>
	
	<main class="wrapper transition-fade" id="swup">
		
		<div class="blogPost widget k-content" style="padding: 10px">
			<!--- This is our container that we will use to swap templates using SWUP. See my blog article if you want more information. --->
			<span id="innerContentContainer">
				
				<h4 class="topContent">
					Login
				</h4>

				<p class="bottomContent">

				<!--- Submit the form to the admin home page. --->
				<form id="adminLogin" name="adminLogin" action="<cfoutput>#application.baseUrl#</cfoutput>/admin/index.cfm?<cfoutput>#qs#</cfoutput>" method="post" enctype="multipart/form-data">
						<!--- Copy additional fields. The user may have been logged out before they clicked on submit (on any of the admin forms). --->
						<cfloop item="field" collection="#form#">
						<!--- Check to see if an enclosure image was made (while on the create or edit post page). --->
						<cfif field is "enclosure" and len(trim(form.enclosure))>
							<input type="hidden" name="enclosureerror" value="true">
						<cfelseif not listFindNoCase("username,password", field) and isSimpleValue(form[field])>
							<input type="hidden" name="<cfoutput>#field#</cfoutput>" value="<cfoutput>#htmleditformat(form[field])#</cfoutput>">
						</cfif>
					</cfloop>
					
					<table class="k-content" width="100%" cellpadding="3" cellspacing="0">
						<tr height="30px">
							<td align="right" width="30%"><label for="userName">User Name:</label></td>
							<td align="left"  width="*"><input id="userName" name="userName" class="k-textbox" style="width:<cfif session.isMobile>85%<cfelse>350px;</cfif>" autocomplete="username" required data-required-msg="Enter User Name." /></td>
						</tr>
						<tr height="30%">
							<td align="right">Password:</td>
							<td align="left">
								<input type="password" id="password" name="password" class="k-textbox" style="width:<cfif session.isMobile>85%<cfelse>350px;</cfif>" autocomplete="current-password" required data-required-msg="Enter Pasword."/>
							</td>
						</tr>
						<tr>
							<td class="border" colspan="2"></td>
						</tr>
						<tr>
							<td></td>
							<td><input type="submit" id="login" name="login" value="Submit" class="k-button k-primary" style="width: <cfif session.isMobile>115px<cfelse>85px</cfif>" /></td>
						</tr>
						<tr>
							<td class="border" colspan="2"></td>
						</tr>
					</table>
					</form>

				</p><!---<p class="bottomContent">--->

			</div><!---<span id="innerContentContainer" class="transition-fade">--->
		</div><!---<div class="blogPost widget k-content">--->
	</main><!---<div class="mainContent">--->
</div><!---<div id="adminPanel" class="panel">--->
	
<!---//*****************************************************************************************
			New user setup and password change (note: this needs to be put at the end of the page with an abort)
//******************************************************************************************--->

<!--- Handles new users that are required to change their password when first logging in. --->
<cfif structKeyExists(URL, "pkey")>

	<!--- Verify that the password is correct in the link. don't  use the ukey as it won't work. --->
	<cfquery name="Data" dbtype="hql">
		SELECT new Map (
			UserName as UserName,
			Password as Password
		)
		FROM Users
		WHERE 0=0
			AND Password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#StringUtilsObj.trimStr(URL.pkey)#" maxlength="175">
			AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			AND BlogRef = #application.BlogDbObj.getBlogId()#
	</cfquery>
	<!---<cfdump var="#Data#">--->
		
	<!--- Ask the user to change the password. Note: were sending in the password as the optArgs instead of the user name in order to prevent any hacking. The userName is much easier to guess than a long salted and enrypted password. I don't know of any way to hack the URL sent to Kendo window that is hardcoded, but that you never know... --->	
	<!--- Note: the newUser is appended to the URL.otherArgs as true. --->
	<cfif arrayLen(Data)>
		<!--- Open up the profile --->
		<script type="<cfoutput>#scriptTypeString#</cfoutput>">
			createAdminInterfaceWindow(11, <cfoutput>'#Data[1]["UserName"]#'</cfoutput>, true);
		</script>
	</cfif>
	<cfabort>
</cfif>
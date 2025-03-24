	<cfset menuDivName = "fixedNavMenu">
	<header>
	<!--- This container will be displayed when the user scrolls down past the header. It is intended to allow for navigation when the user is down the page.--->
	<div id="fixedNavHeader">
		<cfsilent>
		<!--- Get the parent categories --->
		<cfset parentCategories = application.blog.getCategories(parentCategory=1)>
		<!--- Get the themes. This is a HQL array --->
		<cfset themeNames = application.blog.getThemeNames()>
		<!--- Parent link logic- if the parent site is specified in the admin site, link it to the logo. Otherwise, use the blog site. --->
		<cfif len(application.parentSiteLink)>
			<cfset logoLink = application.parentSiteLink>
			<cfset logoAriaLabel = application.parentSiteName>
		<cfelse>
			<cfset logoLink = application.blogHostUrl>
			<cfset logoAriaLabel = application.BlogDbObj.getBlogTitle()>	
		</cfif>
		<!--- We are not going to cache this template. There would be no gain due to the number of conditional blocks requred.--->
		</cfsilent>
		
		<!--- Include the topMenu template. Note: even though there is not much logic in this template- it is included as it is included in other templates and I am designing this so I don't have to edit duplicate code in multiple locations. I want one location for the code even if it is located in several sections of the code. --->
		<cfinclude template="#application.baseUrl#/includes/templates/content/header/topMenu.cfm">
	</div>
<cfif session.isMobile>			
	<table id="headerContainer" cellpadding="0" cellspacing="0" align="center" class="flexHeader headerBackground">
	  <tr>
		<td>
		<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
		<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>" valign="bottom">
			<tr valign="middle">
				<td id="logo" name="logo" valign="middle" width="<cfoutput>#logoMobileWidth#</cfoutput>">
					<!--- Link the logo to the parent site if it exists, otherwise, link to the blog --->
					<cfoutput><a href="#logoLink#" aria-label="#logoAriaLabel#"><img src="#logoSourcePath#" style="padding-left: #logoPaddingLeft#px;" align="left" valign="center" alt="Header Logo" /></a></cfoutput>
				</td>
				<td id="blogNameContainer">
					<!-- The blog name may not always be displayed. The blog name maybe in the logo for example. -->
					<cfif getTheme[1]["DisplayBlogName"]><cfoutput>#encodeForHTML(application.BlogDbObj.getBlogTitle())#</cfoutput></cfif>
				</td>
			</tr>
			<tr>
				<td id="topMenuContainer" colspan="2"><!-- Holds the menu. -->
				<cfsilent>
				<!---//************************************************************************************************
							Top menu javascript (controls the menu at the top of the page)
				//*************************************************************************************************--->
				</cfsilent>
				<cfset menuDivName = "topMenu">
				<cfinclude template="#application.baseUrl#/includes/templates/content/header/topMenu.cfm">
				</td>
		  </tr>
		</table>
		</td>
	  </tr>
	  <tr>
		<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
	  </tr>
	</table>
<cfelse>
	<table id="headerContainer" cellpadding="0" cellspacing="0" align="center" class="flexHeader headerBackground">
	  <tr>
		<td>
		<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
		<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>">
			<!-- If you want the blog title lower, increase the tr height below and decrease the tr height in the *next* row to keep everything aligned. -->
			<tr height="50px;" valign="bottom">
				<!-- Give sufficient room for a logo. This row will bleed into the next row (rowspan="2") -->
				<td id="logo" name="logo"  valign="middle" rowspan="2">
					<!--- Link the logo to the parent site if it exists, otherwise, link to the blog --->
					<cfoutput><a href="#logoLink#" aria-label="#logoAriaLabel#"><img src="#logoSourcePath#" style="padding-left: #logoPaddingLeft#px;" align="left" valign="center" alt="Header Logo" /></a></cfoutput>
				</td>
				<td id="blogNameContainer">
					<!-- The blog name may not always be displayed. The blog name maybe in the logo for example. -->
					<cfif getTheme[1]["DisplayBlogName"]><cfoutput>#encodeForHTML(application.BlogDbObj.getBlogTitle())#</cfoutput></cfif>
				</td>
			</tr>
			<tr>
			  <td id="topMenuContainer" height="55px" class="topMenu"><!-- Holds the menu. -->
				<cfsilent>
				<!---//************************************************************************************************
							Top menu javascript (controls the menu at the top of the page)
				//*************************************************************************************************--->
				</cfsilent>
				<cfset menuDivName = "topMenu">
				<cfinclude template="#application.baseUrl#/includes/templates/content/header/topMenu.cfm">
			 </td>
		  </tr>
		</table>
		</td>
		<td>
		</td>
	  </tr>
	  <tr>
		<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
	  </tr>
	</table>
</cfif>	
	</header>
	<!-- End header -->
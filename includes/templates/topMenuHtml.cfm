	<cfset divName = "fixedNavMenu">
	<header>
	<!--- This container will be displayed when the user scrolls down past the header. It is intended to allow for navigation when the user is down the page.--->
	<div id="fixedNavHeader">
		<cfif customTopMenuJsTemplate eq "">
			<cfinclude template="#application.baseUrl#/includes/layers/topMenu.cfm">
		<cfelse>
			<cfinclude template="#customTopMenuJsTemplate#" />
		</cfif>	
	</div>
				
	<cfif session.isMobile>
		<table id="headerContainer" cellpadding="0" cellspacing="0" background="<cfoutput>#headerBackgroundImage#</cfoutput>" align="center" class="flexHeader">
		  <tr>
			<td>
			<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
			<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>" valign="bottom">
				<tr valign="middle">
					<td id="logo" name="logo" valign="middle" width="<cfoutput>#logoMobileWidth#</cfoutput>">
						<!--- To do: eliminate hardcoded width below. change logo to around 80 to 120px. --->
						<cfoutput><a href="#application.parentSiteLink#" aria-label="#application.parentSiteName#"><img src="#logoSourcePath#" style="padding-left: #logoPaddingLeft#px;" align="left" valign="center" alt="Header Logo" /></a></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>
					</td>
				</tr>
				<tr>
					<td id="topMenuContainer" colspan="2"><!-- Holds the menu. -->
					<cfsilent>
					<!---//************************************************************************************************
								Top menu javascript (controls the menu at the top of the page)
					//*************************************************************************************************--->
					</cfsilent>
					<cfset divName = "topMenu">
					<cfif customTopMenuJsTemplate eq "">
						<cfinclude template="#application.baseUrl#/includes/layers/topMenu.cfm">
					<cfelse>
						<cfinclude template="#customTopMenuJsTemplate#" />
					</cfif>	
					</td>
			  </tr>
			</table>
			</td>
		  </tr>
		  <tr>
			<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
		  </tr>
		</table>
	<cfelse><!---<cfif session.isMobile>--->
		<table id="headerContainer" cellpadding="0" cellspacing="0" background="<cfoutput>#headerBackgroundImage#</cfoutput>" align="center" class="flexHeader">
		  <tr>
			<td>
			<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
			<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>">
				<!-- If you want the blog title lower, increase the tr height below and decrease the tr height in the *next* row to keep everything aligned. -->
				<tr height="50px;" valign="bottom">
					<!-- Give sufficient room for a logo. This row will bleed into the next row (rowspan="2") -->
					<td id="logo" name="logo"  valign="middle" rowspan="2">
						<!---elimnate hardcoded width below. change logo to around 80 to 120px. maybe make new row.--->
						<cfoutput><cfif application.parentSiteLink neq ''><a href="#application.parentSiteLink#" aria-label="#application.parentSiteName#"></cfif><img src="#logoSourcePath#" style="padding-left: #logoPaddingLeft#px;" align="left" valign="center" alt="Header Logo" /><cfif application.parentSiteLink neq ''></a></cfif></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>
					</td>
				</tr>
				<tr>
				  <td id="topMenuContainer" height="55px"><!-- Holds the menu. -->
					<cfsilent>
					<!---//************************************************************************************************
								Top menu javascript (controls the menu at the top of the page)
					//*************************************************************************************************--->
					</cfsilent>
					<cfset divName = "topMenu">
					<cfif customTopMenuJsTemplate eq "">
						<cfinclude template="#application.baseUrl#/includes/layers/topMenu.cfm">
					<cfelse>
						<cfinclude template="#customTopMenuJsTemplate#" />
					</cfif>	
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
	</cfif><!---<cfif session.isMobile>--->
	</header>
	<!-- End header -->
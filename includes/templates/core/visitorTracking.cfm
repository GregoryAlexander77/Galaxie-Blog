<!--- //**************************************************************************************************************
		Visitor / view logging
//****************************************************************************************************************--->
<!--- Split out of coreLogic.cfm (item 7 of the index.cfm/coreLogic.cfm rewrite proposal) so each concern is easier to find. Assumes it is included from coreLogic.cfm, which is itself included from within a <cfsilent> block on index.cfm. --->

	<!--- //**************************************************************************************************************
			Visitor Logging (in blog mode)
	//****************************************************************************************************************--->
	<!--- Are we looking at the blog? --->
	<cfif pageTypeId eq 1 and application.logVisitors>

		<!--- Block a visitor under a temporary timeout first. Temporary timeouts are applied automatically by blog.cfc's recordDatabaseLockError (called from Application.cfc's onError) when the same IP causes a burst of org.hibernate.exception.LockAcquisitionException database lock errors - typically a bot hammering the site. isTemporarilyTimedOut() is a pure in-memory struct lookup (see Application.cfc's OnRequestStart), so checking it here, ahead of the DB-backed isVisitorBanned() check below, blocks that IP's subsequent requests without spending a single extra query on a database that may already be under strain. --->
		<cfif application.blog.isTemporarilyTimedOut(application.blog.getIpAddress())>
			<cfheader statuscode="429">
			<cfcontent type="text/html" reset="true">Too many requests. Please try again later.<cfabort>
		</cfif>

		<!--- Block banned visitors before doing any further tracking or rendering. Banning is managed via the Ban Visitors admin interface (createAdminInterfaceWindow(66)), which can ban by IP address or by HTTP User-Agent string. This check is done directly against the IpAddress/HttpUserAgent tables (not the AnonymousUser combination), so it also catches a banned IP or User-Agent the very first time it is seen. autoBanBadBot() (blog.cfc, alongside the other ban functions) runs second - via short-circuit evaluation it is skipped entirely once isVisitorBanned() is already true - and checks the User-Agent against getBadBots()'s known bad bot/scraper list, automatically banning (and blocking) it with no admin action required. --->
		<cfif application.blog.isVisitorBanned(ipAddress=application.blog.getIpAddress(), httpUserAgent=CGI.Http_User_Agent) or application.blog.autoBanBadBot(CGI.Http_User_Agent)>
			<cfheader statuscode="403">
			<cfcontent type="text/html" reset="true">You have been blocked from accessing this site.<cfabort>
		</cfif>

		<cfif not structKeyExists(cookie, "gauid")>
			<!--- Get client properties. These cookies only exist when an admin user has logged on and are used to set the interfaces depending upon the screen size --->
			<cftry>
				<cfset screenHeight = cookie['screenHeight']>
				<cfset screenWidth = cookie['screenWidth']>
				<cfcatch type="any">
					<cfset screenHeight = 9999>
					<cfset screenWidth = 9999>	   
				</cfcatch>
			</cftry>

			<!--- Save the annonymous user. This will return an anonymous user object --->
			<cfinvoke component="#application.blog#" method="saveAnonymousUser" returnVariable="AnonymousUserDbObj">
				<cfinvokeargument name="ipAddress" value="#application.blog.getIpAddress()#">
				<cfinvokeargument name="httpUserAgent" value="#CGI.Http_User_Agent#">
				<cfinvokeargument name="screenWidth" value="#screenWidth#">
				<cfinvokeargument name="screenHeight" value="#screenHeight#">
			</cfinvoke>
			<!--- Note: this may not be defined if there is a lock error with the transaction --->
			<cfif isDefined("AnonymousUserDbObj")>
				<cfset anonymousUserId = AnonymousUserDbObj.getAnonymousUserId()>
				<!--- Drop a cookie with the Galaxie Anonymous User Id --->
				<cfcookie expires="NEVER" name="gauid" value="#anonymousUserId#">
			</cfif><!---<cfif isDefined("AnonymousUserDbObj")>--->
		<cfelse><!---<cfif not structKeyExists(cookie, "gauid")>--->
			<cfset anonymousUserId = cookie.gauid>
			<!--- Load the anonymousUser entity --->
			<cfset AnonymousUserDbObj = entityLoadByPk("AnonymousUser", anonymousUserId)>
		</cfif><!---<cfif not structKeyExists(cookie, "gauid")>--->

		<!--- Save the HTTP Referrer if passed. --->
		<cfif len(application.blog.getIpAddress()) and len(CGI.Http_Referer)>
			<cfinvoke component="#application.blog#" method="saveHttpReferrer" returnVariable="httpReferrerId">
				<cfinvokeargument name="HttpReferrer" value="#CGI.Http_Referer#">
			</cfinvoke>
		</cfif><!---<cfif len(CGI.Http_Referer)>--->
			
		<!--- Determine if the visitor is on the home page --->
		<cfif application.siteUrl contains getPageContext().getRequest().getRequestURI()>
			<cfset isHomePage = true>
		<cfelse>
			<cfset isHomePage = false>
		</cfif>

		<!--- If the user is looking at a post, pass in the post object --->
		<cfif postFound and getPageMode() eq 'post'>
			<cfset postId = getPost[1]["PostId"]>
		</cfif>

		<!--- Finally, log the visitor. On rare occasions, this causes an error with Lucee so put it in a try block --->			
		<cftry>
			<cfinvoke component="#application.blog#" method="saveVisitorLog" returnVariable="visitorLog">
				<cfif isDefined("AnonymousUserDbObj")>
					<cfinvokeargument name="anonymousUserId" value="#AnonymousUserDbObj.getAnonymousUserId()#">
				</cfif>
				<cfif application.blog.getUsersId()>
					<cfinvokeargument name="userId" value="#application.blog.getUsersId()#">
				</cfif>
				<!--- Pass in the HTTP Referrer Object if it exists --->
				<cfif len(application.blog.getIpAddress()) and isDefined("httpReferrerId") and httpReferrerId gt 0>
					<cfinvokeargument name="httpReferrer" value="#CGI.Http_Referer#">
				</cfif>
				<cfinvokeargument name="visitingHomePage" value="#isHomePage#">
				<cfif postFound and getPageMode() eq 'post'>
					<cfinvokeargument name="postId" value="#postId#">
				</cfif>
				
			</cfinvoke>
			<cfcatch type="any">
				Error saving visitor log
			</cfcatch>
		</cftry>
	</cfif><!---<cfif pageTypeId eq 1>--->
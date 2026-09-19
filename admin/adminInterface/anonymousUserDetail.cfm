	<cfsilent>
		<!--- Get the data from the db --->
		<cfset getAnnonymousUser = application.blog.getAnonymousUser(anonymousUserId=URL.optArgs)><!--- getVisitorLog--->
		<cfset getVisitedPosts = application.blog.getVisitedPosts(anonymousUserId=URL.optArgs)>
		<cfset getSubscribers = application.blog.getSubscriber(anonymousUserId=URL.optArgs)>
			
		<cfif arrayLen(getAnnonymousUser)>
			<!--- Set the variable values. I want to shorten the long variable names here. --->
			<cfset anonymousUserId = getAnnonymousUser[1]["AnonymousUserId"]>
			<cfset userId = structKeyExists(getAnnonymousUser[1], "UserId") ? getAnnonymousUser[1]["UserId"] : "">
			<cfif structKeyExists(getAnnonymousUser[1], "FullName")>
				<cfset fullName = getAnnonymousUser[1]["FullName"]>
			<cfelse>
				<cfset fullName = ''>
			</cfif>
			<cfset ipAddressId = getAnnonymousUser[1]["IpAddressId"]>
			<cfset ipAddress = getAnnonymousUser[1]["IpAddress"]>
			<cfset userAgentId = getAnnonymousUser[1]["HttpUserAgentId"]>
			<cfset userAgent = getAnnonymousUser[1]["HttpUserAgent"]>
			<!--- Identify the browser and check for a bot on the server. This used to be done in the browser with the ua-parser.js and isbot.js libraries. --->
			<cfif len(userAgent)>
				<cfset browserInfo = application.blog.parseBrowser(userAgent)>
				<cfset browserVersion = "">
				<cfloop list="major,minor,patch" item="versionPart">
					<cfif len(browserInfo[versionPart])>
						<cfset browserVersion = listAppend(browserVersion, browserInfo[versionPart], ".")>
					</cfif>
				</cfloop>
				<cfset browserDisplay = trim(browserInfo.family & " " & browserVersion)>
				<cfset isBotDisplay = application.blog.isBot(userAgent) ? "Yes" : "No">
			<cfelse>
				<cfset browserDisplay = "Unknown">
				<cfset isBotDisplay = "Unknown">
			</cfif>
			<cfset hitCount = getAnnonymousUser[1]["HitCount"]>
			<cfset screenHeight = getAnnonymousUser[1]["ScreenHeight"]>
			<cfset screenWidth = getAnnonymousUser[1]["ScreenWidth"]>
			<cfset note = "">
			<!--- Whether this visitor's IP and/or User-Agent are currently banned (see blog.cfc's getAnonymousUser / setIpAddressBan / setHttpUserAgentBan). Used to pre-check the Ban? checkbox below and to know, on Submit, which of the two actually need to change. --->
			<cfset ipBannedRaw = structKeyExists(getAnnonymousUser[1], "IpBanned") ? getAnnonymousUser[1]["IpBanned"] : "">
			<cfset userAgentBannedRaw = structKeyExists(getAnnonymousUser[1], "UserAgentBanned") ? getAnnonymousUser[1]["UserAgentBanned"] : "">
			<cfset ipBanned = len(ipBannedRaw) and (ipBannedRaw eq true or ipBannedRaw eq 1 or ipBannedRaw eq "1")>
			<cfset userAgentBanned = len(userAgentBannedRaw) and (userAgentBannedRaw eq true or userAgentBannedRaw eq 1 or userAgentBannedRaw eq "1")>
			<cfset isBanned = ipBanned or userAgentBanned>
				
			<!--- See if the IP exists in the error log. If there are any records we will show the error log button at the bottom of the page --->
			<cfset getErrorLog = application.blog.getErrorLog(ipAddress=ipAddress)>
			<!--- Do the same thing for reactions --->
			<cfset getReactions = application.blog.getReactions(ipAddress=ipAddress)>
			
		</cfif>
				
		<!--- Note: links to the visitor grid has various arguments, the usage is return createAdminInterfaceWindow(48, anonymousUserId,IpAddressId,postId) send in by the URL. The vars are: createCustomInterfaceWindow(Id, optArgs, otherArgs, otherArgs1) You can send in a 0 for one of the arguments if you don't want to filter by one of the criteria. --->
	</cfsilent>
	<cfif !arrayLen(getAnnonymousUser)>
		No user found! <cfoutput>#URL.optArgs#</cfoutput>
		<cfabort>
	</cfif>
	<!---		
	<cfdump var="#getAnnonymousUser#">
	<cfdump var="#getVisitedPosts#">
	<cfdump var="#getReactions#">
	<cfdump var="#getSubscribers#" label="getSubscribers">
	--->
		
	<form id="anonymousUserDetailForm" name="anonymousUserDetailForm" data-role="validator">	
	<input type="hidden" id="anonymousUserId" name="anonymousUserId" value="<cfoutput>#URL.optArgs#</cfoutput>"/>
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
		
	<table align="center" class="k-content" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr> 
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="<cfoutput>#thisColSpan#</cfoutput>">
			<p>All of the unique visitors are logged including the IP address and user agent sting. The user name is available for administrative users only.</p>
		</td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="fullName"><cfif len(FullName)>Administrative User</cfif></label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput><a href="#fullName#" target="new">#FullName#</a></cfoutput>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%"> 
			<label for="fullName"><cfif len(FullName)>Administrative User</cfif></label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" align="left" style="width: 80%"> 
			<cfoutput><a href="#fullName#" target="new">#FullName#</a></cfoutput>  
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="ipAddress">IP Address:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfif len(ipAddress)>
				<cfoutput><a href="https://www.ipalyzer.com/#ipAddress#" target="_blank">#ipAddress#</a></cfoutput>
			</cfif>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="ipAddress">IP Address:</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfif len(ipAddress)>
				<cfoutput><a href="https://www.ipalyzer.com/#ipAddress#" target="_blank">#ipAddress#</a></cfoutput>
			</cfif>
		</td>
	  </tr>
	</cfif>
	 <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="httpUserAgent">User Agent</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput><a href="https://gs.statcounter.com/detect?useragent=#userAgent#" target="_blank">#userAgent#</a></cfoutput>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="httpUserAgent">User Agent</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput><a href="https://gs.statcounter.com/detect?useragent=#userAgent#" target="_blank">#userAgent#</a></cfoutput>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
		  
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="uaBrowser">Browser</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="uaBrowser" name="uaBrowser"><cfoutput>#encodeForHTML(browserDisplay)#</cfoutput></div>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="uaBrowser">Browser</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<div id="uaBrowser" name="uaBrowser"><cfoutput>#encodeForHTML(browserDisplay)#</cfoutput></div>
		</td>
	  </tr>
	</cfif>
	<!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="uaIsBot">Is Bot?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="uaIsBot" name="uaIsBot"><cfoutput>#isBotDisplay#</cfoutput></div>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="uaIsBot">Is Bot?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<div id="uaIsBot" name="uaIsBot"><cfoutput>#isBotDisplay#</cfoutput></div>
		</td>
	  </tr>
	</cfif>	
		
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
		  
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="hitCount">Hit Count:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>#hitCount#</cfoutput>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="hitCount">Hit Count:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput>#hitCount#</cfoutput>
	  </tr>
	</cfif>
		
	<!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="banIp">Ban IP Address?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" id="banIp" name="banIp" value="1" <cfif not len(ipAddress)>disabled="disabled"</cfif> <cfif ipBanned>checked="checked"</cfif>>
			<cfif not len(ipAddress)><small>No IP address logged for this visitor.</small></cfif>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="banIp">Ban IP Address?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" id="banIp" name="banIp" value="1" <cfif not len(ipAddress)>disabled="disabled"</cfif> <cfif ipBanned>checked="checked"</cfif>>
			<cfif not len(ipAddress)><small>No IP address logged for this visitor.</small></cfif>
		</td>
	  </tr>
	</cfif>

	<!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="bottom" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="banUserAgent">Ban User Agent?</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="checkbox" id="banUserAgent" name="banUserAgent" value="1" <cfif not len(userAgent)>disabled="disabled"</cfif> <cfif userAgentBanned>checked="checked"</cfif>>
			<cfif not len(userAgent)><small>No User-Agent logged for this visitor.</small></cfif>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="banUserAgent">Ban User Agent?</label>
		</td>
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="checkbox" id="banUserAgent" name="banUserAgent" value="1" <cfif not len(userAgent)>disabled="disabled"</cfif> <cfif userAgentBanned>checked="checked"</cfif>>
			<cfif not len(userAgent)><small>No User-Agent logged for this visitor.</small></cfif>
		</td>
	  </tr>
	</cfif>
		
	<!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
		  
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="note">Notes:</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="textbox" id="note" name="note" value="<cfoutput>#Note#</cfoutput>" class="k-textbox" style="width: 50%">
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="note">Notes:</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="textbox" id="note" name="note" value="<cfoutput>#Note#</cfoutput>" class="k-textbox" style="width: 50%">
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif session.isMobile>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>
			<button id="pagesVisited" name="pagesVisited" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(64,0,#ipAddressId#)">Visitor Logs</button><!---javascript:createAdminInterfaceWindow(48,0,#ipAddressId#)">--->
			<cfif arrayLen(getReactions)>
				<button id="ratingLog" name="ratingLog" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(62,#ipAddressId#)">Reactions</button>
			</cfif>
			<cfif arrayLen(getErrorLog)>
				<button id="errorLog" name="errorLog" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(59,#ipAddressId#)">Error Logs</button>
			</cfif>
			</cfoutput>
		</td>
	  </tr>
	<cfelse><!---<cfif session.isMobile>--->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>">
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<cfoutput>
			<button id="pagesVisited" name="pagesVisited" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(64,0,#ipAddressId#)">Visitor Logs</button><!---javascript:createAdminInterfaceWindow(48,0,#ipAddressId#)">--->
			<cfif arrayLen(getReactions)>
				<button id="ratingLog" name="ratingLog" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(65,#ipAddressId#)">Reactions</button>
			</cfif>
			<cfif arrayLen(getErrorLog)>
				<button id="errorLog" name="errorLog" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(59,#ipAddressId#)">Error Logs</button>
			</cfif>
			<cfif arrayLen(getSubscribers)>
				<button id="subscribedPages" name="subscribedPages" class="k-button k-alt" type="button" onClick="javascript:createAdminInterfaceWindow(26,#ipAddressId#)">Subscribed Pages</button>
			</cfif>
			</cfoutput>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		<td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="errorDetailSubmit" name="errorDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
				
	<script>
		<!--- The ban state this visitor's IP address and User-Agent were in when the page loaded, so Submit only issues the ban/unban calls that are actually needed. See blog.cfc's getAnonymousUser. --->
		var anonymousUserDetailState = {
			ipAddress: <cfoutput>#serializeJSON(ipAddress)#</cfoutput>,
			httpUserAgent: <cfoutput>#serializeJSON(userAgent)#</cfoutput>,
			originalIpBanned: <cfoutput>#serializeJSON(ipBanned)#</cfoutput>,
			originalUserAgentBanned: <cfoutput>#serializeJSON(userAgentBanned)#</cfoutput>
		};

		$(document).ready(function() {
			<!--- Invoked when the submit button is clicked. Insted of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event. --->
			var errorDetailSubmit = $('#errorDetailSubmit');
			errorDetailSubmit.on('click', function(e){
                e.preventDefault();

				<!--- submit the form. Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post. alert('posting'); --->
				postAnonymousUserBan();
			});
		});//...document.ready

		<!--- Bans or unbans this visitor's IP address and/or User-Agent independently, based on the Ban IP Address? / Ban User Agent? checkboxes, reusing the same ProxyController.saveAnonymousUserBan endpoint the Ban Visitors admin interface (createAdminInterfaceWindow(66)) uses. Only issues a call for whichever checkbox's state actually changed, so re-saving with nothing changed is a no-op, and either one can be banned/unbanned without touching the other. --->
		function postAnonymousUserBan(){
			var note = $('#note').val();
			var calls = [];
			var changed = { ip: false, userAgent: false };

			var wantIpBanned = $('#banIp').is(':checked');
			var wantUserAgentBanned = $('#banUserAgent').is(':checked');

			if (anonymousUserDetailState.ipAddress && wantIpBanned !== anonymousUserDetailState.originalIpBanned) {
				changed.ip = true;
				calls.push(saveIpOrUserAgentBan('ip', anonymousUserDetailState.ipAddress, wantIpBanned, note));
			}
			if (anonymousUserDetailState.httpUserAgent && wantUserAgentBanned !== anonymousUserDetailState.originalUserAgentBanned) {
				changed.userAgent = true;
				calls.push(saveIpOrUserAgentBan('userAgent', anonymousUserDetailState.httpUserAgent, wantUserAgentBanned, note));
			}

			if (calls.length === 0) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Nothing to Save", message: "The ban status hasn't changed.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}

			$.when.apply($, calls).done(function(){
				anonymousUserBanSaveResult(changed, wantIpBanned, wantUserAgentBanned);
			}).fail(function (jqXHR, textStatus, error) {
				<!--- This is a secured function. Display the login screen. --->
				if (jqXHR.status === 403) {
					createLoginWindow();
				} else {//...if (jqXHR.status === 403) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveAnonymousUserBan function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
					<!--- Do nothing --->
					});
				}//...if (jqXHR.status === 403) {
			});
		};

		<!--- Issues a single ban or unban call for one value (the IP address or the User-Agent string). Mirrors banVisitors.cfm's postBanVisitors. --->
		function saveIpOrUserAgentBan(banType, value, banned, note){
			return jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveAnonymousUserBan&csrfToken=<cfoutput>#csrfToken#</cfoutput>',
				data: {
					csrfToken: $('#csrfToken').val(),
					banType: banType,
					banValues: JSON.stringify(banned ? [value] : []),
					unbanValues: JSON.stringify(banned ? [] : [value]),
					note: banned ? note : ''
				},
				dataType: "json"
			});
		}

		function anonymousUserBanSaveResult(changed, nowIpBanned, nowUserAgentBanned){
			<!--- Keep our local copy of the ban state in sync in case Submit is clicked again without closing the window. --->
			if (changed.ip) {
				anonymousUserDetailState.originalIpBanned = nowIpBanned;
			}
			if (changed.userAgent) {
				anonymousUserDetailState.originalUserAgentBanned = nowUserAgentBanned;
			}

			<!--- Refresh the Banned Users grid if it happens to be open in another admin window. --->
			try {
				$("#bannedUsersGrid").jsGrid("loadData");
			} catch(e){
				<!--- The grid was not initialized/open. This is a normal error. --->
			}

			<!--- Build a message describing what actually changed, since the two can now be banned/unbanned independently. --->
			var messages = [];
			if (changed.ip) {
				messages.push('IP address ' + (nowIpBanned ? 'banned' : 'unbanned'));
			}
			if (changed.userAgent) {
				messages.push('User-Agent ' + (nowUserAgentBanned ? 'banned' : 'unbanned'));
			}

			$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: messages.join(' and ') + '.', icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
				).done(function () {
				<!--- Close this window --->
				$('#anonymousUserWindow').kendoWindow('destroy');
			});
		}
		
	</script>
				<cfsilent>
				<!--- We need a sideBarType argument supplied prior to the include of this template. --->
				<!--- Get the attributes that were sent in the cfmodule tag from the index.cfm page. --->
				<cfset sideBarType = attributes.sideBarType>
				<cfset scriptTypeString = attributes.scriptTypeString>
				<cfset materialTheme = attributes.materialTheme>
				<cfset modernTheme = attributes.modernTheme>
				<cfset darkTheme = attributes.darktheme>
					
				<!--- Is there a URL rewrite rule in place? If so, we need to eliminate the 'index.cfm' string from all of our links. A rewrite rule on the server allows the blog owners to to obsfucate the 'index.cfm' string from the URL. This setting is in the application.cfc template. --->
				<cfif application.serverRewriteRuleInPlace>
					<cfset thisUrl = replaceNoCase(application.baseUrl, '/index.cfm', '')>
				<cfelse>
					<cfset thisUrl = application.baseUrl>
				</cfif>
				
				<!--- Set the button styles for the pods. --->
				<cfif materialTheme>
					<cfif session.isMobile>
						<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
					<cfelse>	
						<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
					</cfif>
				<cfelse><!---<cfif materialTheme>--->
					<cfif session.isMobile>
						<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
					<cfelse>	
						<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
					</cfif>
				</cfif><!---<cfif materialTheme>--->
							
				</cfsilent>
				<aside>
					<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="downloadPod">
						</cfinvoke>
							
						<!--- Cache notes: We're saving this to the file system. We need to save the dark theme. The timeout is set indefinately and will be updated if the user changes the content --->
						<cfif darkTheme>
							<cfset cacheName = "archivesDark">
						<cfelse>
							<cfset cacheName = "archives">
						</cfif>
					</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-file-download"></i> Download Galaxie Blog</h3>
							<cfinclude template="download.cfm">
						</span>
					</div>
					</cfmodule>
				</cfif>
					<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="subscribePod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-envelope-open-text"></i> Subscribe</h3>
							<div class="calendar">
								<cfinclude template="subscribe.cfm">
							</div>
							<br/>
						</span>
				   </div>
				</cfif>
					<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="cfBlogsFeedPod">
						</cfinvoke>
						
						<!--- Set up cache. We are going to store this in application scope and timeout after 30 minutes --->
						<cfif session.isMobile>
							<cfset cacheName = "podRssFeedMobile">
						<cfelse>
							<cfset cacheName = "podRssFeed">
						</cfif>
					</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" timeout="#(60*30)#" debug="false" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-rss-square"></i> CfBlogs.org Feed</h3>
							<cfinclude template="feed.cfm">
						</span>
					</div>
					</cfmodule>
				</cfif>
				<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="recentPostsPod">
						</cfinvoke>
							
						<!--- Cache notes: We're saving this indefinately to the file system and will be updated if the blog owner changes the content. We need to differentiate between the dark theme and light themes in the key. --->
						<cfif session.isMobile>
							<cfset cacheName = "recentPostsMobile">
						<cfelse>
							<cfset cacheName = "recentPosts">
						</cfif>
						<!--- Dark theme --->
						<cfif darkTheme>
							<cfset cacheName = "recentPostsDark">
						</cfif>
					</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="far fa-newspaper"></i> Recent Posts</h3>
							<cfinclude template="recent.cfm">
						</span>
				   	</div>
					</cfmodule>
				</cfif>
				<cfsilent>
					<!--- Is the template active? --->
					<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
						<cfinvokeargument name="contentTemplate" value="recentCommentsPod">
					</cfinvoke>
						
					<!--- Cache notes: We're saving this to the file system and will update if a new comment has been made scope. We need to differentiate between the side bar tpe in the key. --->
					<cfif sideBarType eq "div">
						<cfset cacheName = "recentCommentsDiv">
					<cfelse>
						<cfset cacheName = "recentCommentsPanel">
					</cfif>
					<!--- Dark theme --->
					<cfif darkTheme>
						<cfset cacheName = cacheName & "Dark">
					</cfif>
					<!--- Moblile cache key.--->	
					<cfif session.isMobile>
						<cfset cacheName = cacheName & "Moblile">
					</cfif>
				</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-comments"></i> Recent Comments</h3>
							<!---Problems with the recent comments code.--->
							<cfinclude template="recentcomments.cfm">
						</span>	
					</div>
					</cfmodule>
				</cfif>
				<cfsilent>
					<!--- Is the template active? --->
					<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
						<cfinvokeargument name="contentTemplate" value="categoriesPod">
					</cfinvoke>

					<!--- Cache notes: We're saving this to the file sytem and will refresh it once a new post has been made. We need to save the dark theme. --->
					<cfif darkTheme>
						<cfset cacheName = "archivesDark">
					<cfelse>
						<cfset cacheName = "archives">
					</cfif>
				</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-tags"></i> Category Archives</h3>
							<cfinclude template="archives.cfm">
						</span>
					</div>
					</cfmodule>
				</cfif>
				<cfsilent>
					<!--- Is the template active? --->
					<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
						<cfinvokeargument name="contentTemplate" value="monthlyArchivesPod">
					</cfinvoke>

					<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the dark theme and light themes in the key. The timeout is set to 24 hours --->
					<cfset cacheName = "monthyArchives">
					<!--- Dark theme --->
					<cfif darkTheme>
						<cfset cacheName = cacheName & "Dark">
					</cfif>
				</cfsilent>
				<cfif isActive>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-archive"></i> Monthly Archives</h3>
							<cfinclude template="monthlyarchives.cfm">
						</span>
					</div>
					</cfmodule>
				</cfif>
					<cfsilent>
					<!--- Notes: 
					1: this widget is always active in this version as it does not have custom output. I need to change this in a later version
					2: the calendar widget is the last item on this page as when using touch devices, it is hard to find space to touch scroll.--->
					
					<!--- Cache notes: We're saving this to the application scope. We need to save the sideBarPanelType. The timeout is set to 1 hour --->
					<cfif sideBarType eq 'div'>
						<cfset cacheName = "calendarDiv">
					<cfelseif sideBarType eq 'panel'>
						<cfset cacheName = "calendarPanel">
					</cfif>
					</cfsilent>
					<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="application" file="#application.baseUrl#/cache/pods/#cacheName#.cfm" timeout="#(60*60)#" debug="false" disabled="#application.disableCache#">
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="far fa-calendar-alt"></i> Blog Calendar</h3>
							<div class="calendar">
								<cfinclude template="calendar.cfm">
							</div>
						</span>
					</div>
					</cfmodule>					

					<!---Put some white space underneath the calendar.--->
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>

					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>
					&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br/>

				</aside>
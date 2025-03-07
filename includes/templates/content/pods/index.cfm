				<cfsilent>
				<!--- We need a sideBarType argument supplied prior to the include of this template. --->
				<!--- Get the attributes that were sent in the cfmodule tag from the index.cfm page. --->
				<cfset sideBarType = attributes.sideBarType>
				<cfset scriptTypeString = attributes.scriptTypeString>
				<cfset themeId = attributes.themeId>
				<cfset kendoTheme = attributes.kendoTheme>
				<cfset modernTheme = attributes.modernTheme>
				<cfset darkTheme = attributes.darktheme>
					
				<!--- Is there a URL rewrite rule in place? If so, we need to eliminate the 'index.cfm' string from all of our links. A rewrite rule on the server allows the blog owners to to obsfucate the 'index.cfm' string from the URL. This setting is in the application.cfc template. --->
				<cfif application.serverRewriteRuleInPlace>
					<cfset thisUrl = replaceNoCase(application.baseUrl, '/index.cfm', '')>
				<cfelse>
					<cfset thisUrl = application.baseUrl>
				</cfif>
				
				<!--- Set the button styles for the pods. --->
				<cfif kendoTheme contains 'material'>
					<cfif session.isMobile>
						<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
					<cfelse>	
						<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
					</cfif>
				<cfelse><!---<cfif kendoTheme contains 'material'>--->
					<cfif session.isMobile>
						<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
					<cfelse>	
						<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
					</cfif>
				</cfif><!---<cfif kendoTheme contains 'material'>--->
				</cfsilent>
				<aside>
					<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="downloadPod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-file-download"></i> Download Galaxie Blog</h3>
							<cfinclude template="download.cfm">
						</span>
					</div>
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
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-rss-square"></i> CfBlogs.org Feed</h3>
							<cfinclude template="feed.cfm">
						</span>
					</div>
				</cfif>
				<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="recentPostsPod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="far fa-newspaper"></i> Recent Posts</h3>
							<cfinclude template="recent.cfm">
						</span>
				   </div>
				</cfif>
				<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="recentCommentsPod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-comments"></i> Recent Comments</h3>
							<!---Problems with the recent comments code.--->
							<cfinclude template="recentcomments.cfm">
						</span>	
					</div>
				</cfif>
				<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="categoriesPod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-tags"></i> Category Archives</h3>
							<cfinclude template="archives.cfm">
						</span>
					</div>
				</cfif>
				<cfsilent>
						<!--- Is the template active? --->
						<cfinvoke component="#application.blog#" method="isContentTemplateActive" returnvariable="isActive">
							<cfinvokeargument name="contentTemplate" value="monthlyArchivesPod">
						</cfinvoke>
					</cfsilent>
				<cfif isActive>
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="fas fa-archive"></i> Monthly Archives</h3>
							<cfinclude template="monthlyarchives.cfm">
						</span>
					</div>
				</cfif>
					<!--- Notes: 
					1: this widget is always active in this version as it does not have custom output. I need to change this in a later version
					2: the calendar widget is the last item on this page as when using touch devices, it is hard to find space to touch scroll.--->
					<div class="widget k-content flexItem">
						<span class="innerContentContainer">
							<h3 class="topContent"><i class="far fa-calendar-alt"></i> Blog Calendar</h3>
							<div class="calendar">
								<cfinclude template="calendar.cfm">
							</div>
						</span>
					</div>

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
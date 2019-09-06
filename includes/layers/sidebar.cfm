				<cfsilent>
				<!--- Get the attributes that were sent in the cfmodule tag from the index.cfm page. --->
				<cfset sideBarType = attributes.sideBarType>
				<cfset scriptTypeString = attributes.scriptTypeString>
				<cfset kendoTheme = attributes.kendoTheme>
				<cfset darkTheme = attributes.darktheme>
				</cfsilent>
				<!--- We need a sideBarType argument supplied prior to the include of this template. --->
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-envelope-open-text"></i> Subscribe</h3>
						<div class="calendar">
							<cfinclude template="#application.baseUrl#/includes/pods/subscribe.cfm">
						</div>
					</span>
               </div>
					
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-tags"></i> Tags</h3>
						<cfinclude template="#application.baseUrl#/includes/pods/tagcloud.cfm">
					</span>
				</div>
                
                <div class="widget k-content flexItem">
                	<span class="innerContentContainer">
						<h3 class="topContent"><i class="far fa-newspaper"></i> Recent Posts</h3>
						<cfinclude template="#application.baseUrl#/includes/pods/recent.cfm">
					</span>
               </div>
                
                <div class="widget k-content flexItem">
                	<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-comments"></i> Recent Comments</h3>
						<!---Problems with the recent comments code.--->
						<cfinclude template="#application.baseUrl#/includes/pods/recentcomments.cfm">

					</span>	
				</div>
				
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-file-archive"></i> Archives</h3>
						<cfinclude template="#application.baseUrl#/includes/pods/archives.cfm">
					</span>
				</div>
					
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-archive"></i> Monthly Archives</h3>
						<cfinclude template="#application.baseUrl#/includes/pods/monthlyarchives.cfm">
					</span>
				</div>
					
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-rss-square"></i> CFBloggers Feed</h3>
						<cfinclude template="#application.baseUrl#/includes/pods/feed.cfm">
					</span>
				</div>
				
				<!---Note: the calendar widget is the last item on this page as when using touch devices, it is hard to find space to touch scroll.--->
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="far fa-calendar-alt"></i> Blog Calendar</h3>
						<div class="calendar">
							<cfinclude template="#application.baseUrl#/includes/pods/calendar.cfm">
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
					
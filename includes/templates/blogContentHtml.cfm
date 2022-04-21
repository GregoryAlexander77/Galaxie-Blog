	<cfsilent>
	<!--- Forms that hold state. --->
	<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->

	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	</cfsilent>

	<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>

	<div id="mainPanel" class="flexParent">
		<cfsilent>
		<!--- 
		Wide div in the center left of page.
		Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div 
		are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
		--->
		</cfsilent>
		<div id="blogContent">
			<cfsilent><!--- Loop thru the articles. --->
			<cfset lastDate = "">
			<!--- Note: getPost is an array and contains one or more posts. It is used when in blog mode (multiple posts), or when in post mode (one post).--->
			</cfsilent>
		<!---<cfdump var="#getPost#" label="getPost">--->
		<cfif arrayLen(getPost)>
			<!--- Loop through the array --->
			<cfloop from="1" to="#arrayLen(getPost)#" index="i">
				<cfsilent>
				<!--- Set the variable values. I want to shorten the long variable names here. --->
				<cfset postId = getPost[i]["PostId"]>
				<cfset postAlias = getPost[i]["PostAlias"]>
				<cfset postUuid = getPost[i]["PostUuid"]>
				<cfset themeId = getPost[i]["ThemeRef"]>
				<cfset promotedPost = getPost[i]["Promoted"]>
				<cfset title = getPost[i]["Title"]>
				<!---<cfset description = getPost[i]["Description"]>--->
				<cfset postHeader = getPost[i]["PostHeader"]>
				<cfset body = getPost[i]["Body"]>
				<cfset userId = getPost[i]["UserId"]>
				<cfset email = getPost[i]["Email"]>
				<cfset fullName = getPost[i]["FullName"]>
				<!--- Media (videos and images) --->
				<cfset mediaType = getPost[1]["MediaType"]>
				<!--- The mime type may not be available when using external sources due to forbidden errors when trying to read the file. --->
				<cfset mimeType = getPost[i]["MimeType"]>
				<cfset mediaHeight = getPost[i]["MediaHeight"]>
				<cfset mediaPath = getPost[i]["MediaPath"]>
				<cfset mediaTitle = getPost[i]["MediaTitle"]>
				<cfset mediaUrl = getPost[i]["MediaUrl"]>
				<cfset mediaWidth = getPost[i]["MediaWidth"]>
				<!--- We need the providers video id (i.e. the YouTube or Vimeo video Id.) This is captured when creating or updating the enclosure --->
				<cfset providerVideoId = getPost[i]["ProviderVideoId"]>
				<cfset moreBody = getPost[i]["MoreBody"]>
				<cfset allowComment = getPost[i]["AllowComment"]>
				<cfset released = getPost[i]["Released"]>
				<cfset mailed = getPost[i]["Mailed"]>
				<cfset numViews = getPost[i]["NumViews"]>
				<cfset datePosted = getPost[i]["DatePosted"]>
				<!--- Set the enclosureMapIdList. We only need to get the value of the first item in the list as all of the values are the same --->
				<cfset enclosureMapIdList = getPost[1]["EnclosureMapIdList"]>
				<!--- Get the map Id of the current row in the list. --->
				<cfset enclosureMapId = getPost[i]["EnclosureMapId"]>
					
				<!--- Get the categories for this post. --->
				<cfset getCategories = application.blog.getCategoriesByPostId(postId)>
				<!--- Get the comment count for this post. --->
				<cfset commentCount = application.blog.getCommentCountByPostId(postId)>
				<!--- Get the post link. The makeRewriteRuleSafeLink function will be used within the makeLink function for server side rewrite rules --->
				<cfset postLink = application.blog.makeLink(getPost[i]["PostId"])>
				<!--- We need to perform the same logic for the post author (remove the 'index.cfm' string when a rewrite rule is in place). --->
				<cfset userLink = application.blog.makeUserLink(getPost[i]["FullName"])>
				<!--- Render the post. This will render cfinclude and video directives if present, the encosure and the body. --->
				<cfset post = RendererObj.renderPost(kendoTheme,getPost,i)> 
				
				<!--- Set our blog content. We need to determine the content based upon the more tag if it exists. If the more tag exists- use the body column when we not looking at an individual post and the body and the moreBody when we are looking at and individual post. ---> 
				<cfif len(moreBody)>
					<cfif getPageMode() eq 'post'>
						<!--- Append the more body to the body --->
						<cfset body = body & ' ' & moreBody>
					</cfif>
				</cfif>					
				<!--- Set the post content --->
				<cfset postContent = RendererObj.renderBody(body, mediaPath, getPageMode())>
					
				<!--- For desktop clients, handle multiple maps on a page. If there are multiple maps, we need to create a script that will load all of the maps at the top of the page. If we are using a mobile device and there are multiple maps- we will use an iframe to display the map. --->
				<cfif not session.isMobile and i eq 1 and listLen(enclosureMapIdList) gt 1>
					<!--- Invoke the renderLoadMapScript function --->
					<cfinvoke component="#RendererObj#" method="renderLoadMapScript" returnvariable="loadMapScript">
						<cfinvokeargument name="kendoTheme" value="#kendoTheme#">
						<cfinvokeargument name="enclosureMapIdList" value="#enclosureMapIdList#">
						<cfinvokeargument name="currentRow" value="#i#">
					</cfinvoke>
				<cfelse>
					<cfset loadMapScript = ''>
				</cfif>
				</cfsilent>
				<cfoutput>
			<cfif len(loadMapScript)><!-- Load the javascript to handle multiple maps on one page -->
				#loadMapScript#
			</cfif>
				<div class="blogPost <cfif promotedPost>highlightedWidget<cfelse>widget</cfif> k-content"><!--- Highlight the post with the themes accent color if it is promoted. --->
					<span class="innerContentContainer">
						<h1 class="topContent">
						<cfsilent><!--- Debugging: currentRow(i): #i# arrayLen(getPost): #arrayLen(getPost)# postId: #postId#<br/>---></cfsilent>
						<!--- Don't show the link in the title when looking at an individual post. --->
						<cfif getPageMode() eq 'post'>
							#title# 
						<cfelse>
							<a href="#postLink#" aria-label="#title#" class="k-content">#title#</a> 
						</cfif>
						<cfif promotedPost>&nbsp;<i class="fa fa-bullhorn" aria-hidden="true" style="font-size: 14pt" title="Announcement"></i></cfif>
						</h1>
						<p class="postDate">
							<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
							<span class="month k-primary">#dateFormat(datePosted, "mmm")#</span>
							<span class="day k-alt">#day(datePosted)#</span>
						</p>
						<p class="postAuthor">
							<span class="info">
								<cfif len(fullName)>by <a href="#userLink#" aria-label="#userLink#" class="k-content">#fullName#</a></cfif>
								<!--- Loop through the categories array. --->
								<cfloop from="1" to="#arrayLen(getCategories)#" index="i">
									<cfsilent>
									<cfset category = getCategories[i]["Category"]>
									<cfset categoryId = getCategories[i]["CategoryId"]>
									<cfset categoryLink = application.blog.makeCategoryLink(CategoryId)>
									</cfsilent>
									<a href="#categoryLink#" aria-label="#categoryLink#" class="k-content">#category#</a><cfif i lt arrayLen(getCategories)>, </cfif> 
								</cfloop>
							</span>
						</p>
						<!-- Post content --> 
						<span class="postContent">	
							<cfsilent>
							<!--- ********************************************************************************************
										Render the post. 
							**********************************************************************************************--->
							</cfsilent>
							<p>#post#</p>							
							<!--- If the more tag exists and we are not looking at a page, summarize the content (done when we set the postContent in logic above) and render a button to get to the full post. --->
						<cfif len(morebody) and getPageMode() neq 'post'><!--- Chjanged logic. Old logic prior to version 1.45 was: and url.mode is not "entry"--->
							<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="location.href='#postLink###more';">
								<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
								<i class="fas fa-chevron-circle-down" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;More...
							</button>
						</cfif>
						
						</span><!--<span class="postContent">--> 
						<p class="bottomContent">
						<cfsilent>
						<!--- ********************************************************************************************
							Related entries
						**********************************************************************************************--->
						</cfsilent>
						<cfset getRelatedPosts = application.blog.getRelatedPosts(postId=postId) />	
						<!---<cfdump var="#getRelatedPosts#">--->
						<cfif arrayLen(getRelatedPosts)>
							<div name="relatedentries">
							<h3 class="topContent">Related Entries</h3>
							<ul name="relatedEntriesList">
							<cfloop from="1" to="#arrayLen(getRelatedPosts)#" index="i">
							<cfsilent>
							<!--- Is there a URL rewrite rule in place? If so, we need to eliminate the 'index.cfm' string from all of our links. A rewrite rule on the server allows the blog owners to to obsfucate the 'index.cfm' string from the URL. This setting is in the application.cfc template. --->
							<cfif application.serverRewriteRuleInPlace>
								<cfset relatedEntryUrl = replaceNoCase(application.blog.makeLink(postId=getRelatedPosts[i]["PostId"]), '/index.cfm', '')>
							<cfelse>
								<cfset relatedEntryUrl = application.blog.makeLink(postId=getRelatedPosts[i]["PostId"])>
							</cfif>
							</cfsilent>
							<li><a href="#relatedEntryUrl#" aria-label="#getRelatedPosts[i]['Title']#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#getRelatedPosts[i]['Title']#</a></li>
							</cfloop>			
							</ul>
							</div>
						</cfif>
						<cfsilent>
						<!--- ********************************************************************************************
							Comment interfaces (Disqus and Galaxie Blog)
						**********************************************************************************************--->
						</cfsilent>
						
					<!-- Button navigation. -->
					<!-- Set a smaller font in the kendo buttons. Note: adjusting the .k-button class alone also adjusts the k-input in the multi-select so we will set it here.-->
					<cfif allowComment>
						<cfif application.includeDisqus>
							<cfif URL.mode neq 'entry' and URL.mode neq 'alias'>
							<!-- The Disqus comment button should not be shown when in blog mode. -->
							<button id="disqusCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
								<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
							</button>
							</cfif>
						<cfelse>
							<button id="addCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#postId#', 'addComment', #session.isMobile#)">
								<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
							</button>
						</cfif>
					</cfif><!---<cfif allowComment>--->
						<!--- The default comment subscribe interface won't work with Disqus --->
						<cfif not application.includeDisqus>
							<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#postId#', 'subscribe', #session.isMobile#)">
								<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
								<i class="fas fa-envelope-open-text" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Subscribe
							</button>
						</cfif>
							<p>This entry was posted on #dateFormat(datePosted, "mmmm d, yyyy")# at #timeFormat(datePosted, "h:mm tt")# and has received #numViews# views. </p>
					<cfif not application.includeDisqus> 
							<h3 class="topContent">Comments</h3>
							<p>There are <cfif commentCount is "">0<cfelse>#commentCount#</cfif> comments.</p> 
						<cfif not allowComment>
							<p>Comments are disabled.</p>
						</cfif>
						<!--- Span to hold the little arrow. Note: the order of the spans in the code are different than the actual display. We need to reverse the order for proper display. We are not going to display this if there are no comments. --->
						<cfif commentCount gt 0>
							<span id="commentControl#postId#" class="collapse k-icon k-i-sort-desc-sm k-primary" style="width: 35px; height:35px; border-radius: 50%;" onClick="handleComments()"></span>&nbsp;&nbsp;<span id="commentControlLabel#postId#">Show Comments</span><br/><br/>
						</cfif><!---<cfif len(commentCount) gt 0>--->
					</cfif><!---<cfif not application.includeDisqus>--->
						<cfsilent>
						<!--- ****************************************************************************************
							Disqus - load disqus if we are in looking at an individual entry
						******************************************************************************************--->
						</cfsilent>
						<cfif application.includeDisqus and (url.mode eq "alias" or URL.mode eq 'entry')>
							<div id="disqus_thread"></div>
							<script type="#application.blog.getScriptTypeString()#">
								/**
								*  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
								*  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#chr(35)#configuration-variables*/
								/*
								var disqus_config = function () {
								var disqus_shortname = '#postAlias#';
								this.page.url = #postLink#;  // Replace PAGE_URL with your page's canonical URL variable
								this.page.identifier = #postId#; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
								};
								*/
								(function() { // don't EDIT BELOW THIS LINE
									var d = document, s = d.createElement('script');
									s.src = 'https://gregorys-blog.disqus.com/embed.js';
									s.setAttribute('data-timestamp', +new Date());
									(d.head || d.body).appendChild(s);
								})();
							</script>
						</cfif><!---<cfif application.includeDisqus and url.mode eq "alias">--->
							
						<cfsilent>
						<!--- ********************************************************************************************
							Original comments interface (non Disqus).
						**********************************************************************************************--->
						</cfsilent>
							
						<cfif len(commentCount) gt 0 and not application.includeDisqus>
							
							<!-- Comments that are shown when the user clicks on the arrow button to open the container. -->
							<div id="comment#postId#" class="widget k-content" style="display:none;"> 
								<table cellpadding="3" cellspacing="0" border="0" class="fixedCommentTable">
								 <tr width="100%">
								 <!---<cftry>--->
								 <!--- Get the comments and loop through them. --->
								 <cfset comments = application.blog.getComments(postId)>
								 <cfparam name="commentLoopCount" default="1">
							<cfloop from="1" to="#arrayLen(comments)#" index="i">
								 <cfsilent>
								 <!--- Set the vars. --->
								 <cfset commentId = comments[i]["CommentId"]>
								 <cfset commentUuid = comments[i]["CommentUuid"]>
								 <cfset comment = comments[i]["Comment"]>
								 <cfset commenterFullName = comments[i]["CommenterFullName"]>
								 <cfset commenterEmail = comments[i]["CommenterEmail"]>
								 <cfset commenterWebsite = comments[i]["CommenterWebsite"]>
								 <cfset commentDatePosted = comments[i]["DatePosted"]>
								 </cfsilent>

								 <!--- Note: the URL is appended with an extra 'c' in front of the commentId. --->
								 <tr id="c#CommentId#" name="" class="<cfif commentLoopCount mod 2>k-content<cfelse>k-alt</cfif>">
									<td class="fixedCommentTableContent">
										 <a class="comment-id" href="#application.blog.makeLink(postId)###c#CommentId#" aria-label="Comment by #commenterFullName#" class="k-content">###i#</a> by <b>
										 <cfif len(commenterWebsite)>
											<a href="#commenterWebsite#" aria-label="#commenterFullName#" rel="nofollow">#commenterFullName#</a>
										 <cfelse>
											#commenterFullName#
										 </cfif></b> 
										 on #dateFormat(commentDatePosted, "mmmm d, yyyy")# at #timeFormat(commentDatePosted, "h:mm tt")#</p>
									</td>
								 <tr class="<cfif commentLoopCount mod 2>k-content<cfelse>k-alt</cfif>">
									<td>
										<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" title="#commenterFullName#'s Gravatar" alt="#commenterFullName#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
										#application.Udf.paragraphFormat2(comment)#
										<cfsilent><!---
										The replaceLinks function is removed with V2 and the new tinymce editor
										#paragraphFormat2(replaceLinks(comment))# 
										---></cfsilent>
									</td>
								 </tr>
								 <!--- If the number of records is even, create the bottom border.--->
							 <cfif arrayLen(comments) mod 2 is 0>
								 <tr class="<cfif commentLoopCount mod 2>k-alt<cfelse>k-content</cfif>">
									<td class="border"></td>
								 </tr>
							 </cfif>
							 <cfset commentLoopCount = commentLoopCount + 1>
						</cfloop>
							 <!---<cfcatch type="any">
								<tr>
									<td>
										#cfcatch.detail#
									</td>
								</tr>
							 </cfcatch>
							 </cftry>--->
							</table>
						</div><!---<div id="comment#CommentId#" class="widget k-content" style="display:none;">--->
					</cfif><!---<cfif application.includeDisqus>--->

					</span><!---<span class="innerContentContainer">--->
				</div><!---<div class="blogPost">--->
			</cfoutput></cfloop><!---<cfloop from="1" to="#arrayLen(getPost)#" index="i">--->
		</cfif><!---<cfif arrayLen(getPost)>--->					
			<a href="#chr(35)#" id="pagerAnchor" aria-label="Pager+"></a>
			<cfsilent>
			<!--- ********************************************************************************************************
				Add social media icons when there is only one entry
			**********************************************************************************************************--->
			</cfsilent>					
		<cfif addSocialMediaUnderEntry>
			<p class="bottomContent">
				<!-- Go to www.addthis.com/dashboard to customize your tools --> 
				<script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#pubid=<cfoutput>#application.addThisApiKey#</cfoutput>"></script>
				<div class="<cfoutput>#application.BlogOptionDbObj.getAddThisToolboxString()#</cfoutput>"></div>
			</p>
		</cfif><!---<cfif addSocialMediaUnderEntry>--->
			<cfsilent>
			<!--- *******************************************************************************************************
				Pagination
			**********************************************************************************************************--->
			</cfsilent>
			<!--- 
			Debugging: <cfoutput>url.startRow: #url.startRow# application.maxEntries: #application.maxEntries# arrayLen(getPost): #arrayLen(getPost)# #round(URL.startRow + application.maxEntries)#</cfoutput>---> 
			
			<cfif (URL.startRow gt 1) or (arrayLen(getPost) gte application.maxEntries)>
				<cfsilent>
				<!--- Get the number of pages --->
				<cfset totalPages = ceiling(postCount/application.maxEntries)>

				<!--- Set links --->
				<!--- Get the path if not /index.cfm --->
				<cfset path = rereplace(cgi.path_info, "(.*?)/index.cfm", "")>
				<!--- Clean out startrow from query string --->
				<cfset queryString = cgi.query_string>
				<!--- Safety check. Handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
				<cfset queryString = reReplace(queryString, "<.*?>", "", "all")>
				<cfset queryString = reReplace(queryString, "[\<\>]", "", "all")>
				<cfset queryString = reReplaceNoCase(queryString, "&*startrow=[\-0-9]+", "")>
				<!--- Remove the page variable. This is hard coded in the datasource below. --->
				<cfset queryString = reReplaceNoCase(queryString, "&*page=[\-0-9]+", "")>
				<!--- If it is not already defined, preset the URL page var --->
				<cfif not isDefined("URL.page")>
					<cfset URL.page = 0>
				</cfif>
				<!--- 
				Debugging: 
				url.startRow: #url.startRow# application.maxEntries: #application.maxEntries# lastPageQueryString: #lastPageQueryString# currentPage: #currentPage# totalPages: #totalPages# prevPageEnabled:#prevPageEnabled# nextPageEnabled:#nextPageEnabled#--->
				
				</cfsilent>
				<cfoutput>
					<div id="pager" data-role="pager" class="k-pager-wrap k-widget k-floatwrap k-pager-lg">
					<script  type="#scriptTypeString#">
						// Create the datasource with the URL
						var pagerDataSource = new kendo.data.DataSource({
						data: [<cfset thisStartRow = 0><!--- Loop through the pages. ---><cfloop from="1" to="#totalPages#" index="page"><cfset thisLink = queryString & "&startRow=" & thisStartRow & "&page=" & page>
							{ pagerUrl: "#thisLink#", page: "#page#" }<cfif page lt totalPages>,</cfif><cfset thisStartRow = thisStartRow + application.maxEntries></cfloop>
						],
							pageSize: 1,// Leave this at 1.
							page: #URL.page#
						});

						 var pager = $("#chr(35)#pager").kendoPager({
							dataSource: pagerDataSource,
							messages: {
							  display: "page {0} of {2}"
							},
							change: function() {
								onPagerChange(this.dataSource.data());//this.datasource.productName
							}
						}).data("kendoPager");

						pagerDataSource.read();

						function onPagerChange(data){
							// Get the current page of the pager. The method to extract the current page is 'page()'.
							var currentPage = pager.page();
							// We are going to get the data item held in the datasource using its zero index array, but first we need to subtract 1 from the page value.
							var index = currentPage-1;
							// Get the url that is stored in the datsource using our new index.
							var pagerUrl = "?" + data[index].pagerUrl;
							// Open the page.
							window.location.href = pagerUrl;
						}
					</script>
					</div>
				</cfoutput>
			</cfif>
			<!--- **** Logic to display content when no data is found (ie when a user clicks on the wrong date) ****--->
			<cfif arrayLen(getPost) eq 0>
				<div class="blogPost widget k-content" style="font-weight: bold;">
					<span class="innerContentContainer">
						<h1 class="topContent">
							No Entries
						</h1> 
						<span class="postContent">
						<cfif url.mode is "day">
							There are no entries for the selected dates. Please select a highlighted date in the calendar control.
							<!--- Kind of a hack. Fill the div, otherwise the side content will push to the left (see float left comment near the top of the page.)--->
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
						<cfelse>
							<!--- Handle errors when the post alias in the URL was not found. This could be the result of someone manually changing the URL, or if the post has not yet been released yet. --->
							<cfif not postFound>
							Post not available or found.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							<cfelse>
							<!--- This occurs when there is an error, or the blog is completely empty after installation. --->
							There are no blog entries.
							</cfif>
						</cfif>
						<br/><br/>
						</span>
					</span><!---<span class="innerContentContainer">--->
				</div><!---<div class="blogPost">--->
			</cfif><!---<cfif articles.recordcount eq 0>--->
		</div><!---blogContent--->
		<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. We will not include it if the break point is not 0 or is equal or above 50000 --->
	<cfif breakpoint gt 0>
		<div id="sidebar">
			<!---Suppply the sideBarType argument before loading the side bar--->
			<cfmodule template="#application.baseUrl#/includes/layers/sidebar.cfm" sideBarType="div" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" darkTheme="#darktheme#">
		</div><!---<nav id="sidebar">--->
		</cfif>
	</div><!---<div class="mainPanel hiddenOnNarrow">--->

	<cfsilent>
	<!---//***************************************************************************************************************
				Sidebar panel
	//****************************************************************************************************************--->
	</cfsilent>		
	<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. --->
	<nav id="sidebarPanel" class="k-content">
		<div id="sidebarPanelWrapper" name="sidebarPanelWrapper" class="flexScroll">
			<!---Suppply the sideBarType argument before loading the side bar--->
			<cfmodule template="#application.baseUrl#/includes/layers/sidebar.cfm" sideBarType="panel" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" darkTheme="#darktheme#">
		</div>
	</nav><!---<nav id="sidebar">--->
	<!--- This script must be placed underneath the layer that is being used in order to effectively work as a flyout menu.--->
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		$(document).ready(function() {	
			$("#sidebarPanel").kendoResponsivePanel({
				// On mobile devices, always achieve the breakpoint by setting it to 0, otherwise, use the breakpoint setting that is defined in the administrative interface.
				breakpoint: breakpoint,
				orientation: "left",
				autoClose: true,// Note: autoclose true will cause the panel to fly off to the left. It looks a bit funny, but it works.. 
				open: onSidebarOpen,
				close: onSidbarClose
			})
		});//..document.ready
		
		function onSidebarOpen(){
			// Change the value of the hidden input field to keep track of the state. We need some lag time and need to wait half of a second in order to allow the form to be changed, otherwise, we can't keep an accurate state and the panel will always think that the panel is closed and always open when you click on the button.
			// Display the sidebar 
			$('#sidebarPanel').fadeTo(0, 500, function(){
				$('#sidebarPanel').css('visibility','visible'); 
				// Set the state
				$('#sidebarPanelState').val("open");
			}); // duration, opacity, callback
		}
		
		// Event handler for close event for mobile devices. Note: this is not consumed with desktop devices.
		function onSidbarClose(){
			// Hide the sideBar
			$('sidebarPanel').css("visibility", "hidden"); 
			$('#sidebarPanel').fadeTo(500, 0, function(){
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			}); // duration, opacity, callback
		};

		// Function to open the side bar panel. We need to have the name of the div that is consuming this in order to adjust the top padding.
		function toggleSideBarPanel(layer){
			// Determine if we should open or close the sidebar.
			if (getSidebarPanelState() == 'open'){
				// On desktop, set visibility to hidden, otherwise there will be an animation on desktop devices that just looks wierd.
				if (!isMobile){
					$('#sidebarPanel').css("visibility", "hidden"); 
				}
				// Close the sidebar
				$("#sidebarPanel").kendoResponsivePanel("close");
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			} else { //if ($('#sidebarPanel').css('display') == 'none'){ 
				// Set the padding.
				setSidebarPadding(layer);
				// Open the sidebar
				$("#sidebarPanel").kendoResponsivePanel("open");
			}//if ($('#sidebarPanel').css('display') == 'none'){ 
		}
		
		// Sidebar helper functions.
		function getSidebarPanelState(){
			// Note: There is no way to automatically get the state, so I am toggling a hidden form with the state using the onSideBarOpen and close. Also, when the user clicks on the button the first time, there will be an error 'Uncaught TypeError: Cannot read property 'style' of undefined', so we will put this in a try block and iniitialize the panel if there is an error. 
			
			// The hidden sidebarPanelState form is set to initial on page load. We need to initialize the sidebarPanel css by setting the css to display: 'block'
			if ($('#sidebarPanelState').val() == 'initial'){
				// Set the display property to block. 
				$('#sidebarPanel').css('display', 'block');
				var sidebarPanelState = 'closed';
			} else if (($('#sidebarPanelState').val() == 'open')){
				var sidebarPanelState = 'open';
			} else if (($('#sidebarPanelState').val() == 'closed')){
				var sidebarPanelState = 'closed';
			} else {
				// Default state is closed (if anything goes wrong)
				var sidebarPanelState = 'closed';
			}
			return sidebarPanelState;
		}
		
		function setSidebarPadding(layer){
			// !! Note: there are setSidebarPadding functions. One for the blog, and the other for all other pages. When looking at the blog requires different logic as the sideBar container is to the right of the blog content when in classic mode. 
			if (layer == 1){// The topMenu element is invoking this method.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The header is 105px for mobile.
					var marginTop = "105px";
				} else {
					// When this is invoked in the blog, there is no padding for desktop. The layer is correctly positioned within the mainContainer
					var marginTop = "0px";
				}
				var marginTop = marginTop;

				// Set the css margin-top property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			} else if (layer == 2){// The fixed 'fixedNavHeader' element is invoking this method.
				// The height of the fixedMenu is 35 or 45 pixels depening upon device.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The fixedNavHeader is 35 pixels for mobile. We'll add another 2px.
					var marginTop = "37px";
				} else {
					// We need to find out how far from the top we are to figure out how many pixes to drop the Kendo responsive panel down as we have scrolled away from the top of the screen.
					var pixelsToTop = window.pageYOffset || document.documentElement.scrollTop;
					// Subtract 60 pixes from the pixels to top to determine the placement of the sidebar panel. 
					var marginTop = (pixelsToTop - 60) + "px";
				}
				var marginTop = marginTop;
				// Set the margin-top css property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			}
		}//..function setSidebarPadding(layer){
	</script>
	<div class="responsive-message"></div>
<cfsilent>
	<cfprocessingdirective pageencoding="utf-8">
	<!---
		Name         : recentcomments.cfm
		Author       : Gregory Alexander
		Created      : April 13, 2006
		Last Updated : 9/28/2019
		History      : Gregory put a new Kendo front end on the pod. The UI has been completely revised.
		Purpose		 : Display recent comments

	There are 3 different commenting systems: 1) the revised BlogCfc based commenting system that Gregory put in 2) using the Disqus recent comments widget that uses a registered disqus blog but does not require the blog owner to have their own disqus API key, and getting the data from the Disqus API that requires both a registered disqus account and a registered Disqus API key. Please see documentation on Gregory's Blog (www.gregoryalexander.com/blog/) for more information.
	--->
		
	<cfset numComments = 5><!--- How many comments do you want to retrived to be displayed on the sidebar? Default value is 5. --->
		
	<!--- Comment Settings. --->
	<!--- How long do you want the comment to be? --->
	<cfset lenComment = "200">
	<cfif not application.includeDisqus>
		<!--- We will use the revised commenting interface that was built into Galaxie Blog --->
		<cfset getRecentComments = application.blog.getRecentComments(numComments)>
	</cfif><!---<cfif application.includeDisqus>--->

	<!--- Set the name of the element that will contain the recent disqus comments. --->
	<cfif sideBarType eq "div">
		<cfset recentCommentsElementId="recentCommentsDiv">
	<cfelse>
		<cfset recentCommentsElementId="recentCommentsPanel">
	</cfif>
	<!--- Set the padding for the avatar. Mobile is smaller than desktop. --->
	<cfif session.isMobile>
		<cfset avatarPadding = "3px 3px 3px 3px">
	<cfelse>
		<cfset avatarPadding = "6px 6px 6px 6px">
	</cfif>
		
	<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the side bar tpe in the key. The timeout is set to 30 minutes --->
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
	
<!--- Note: this template works with either the original comment interface, or disqus. The logic is similiar, but if the blog owner prefers to use disqus we need to get the comments from an external feed provided by disqus. --->
</cfsilent>
	<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#60*30#" disabled="#application.disableCache#">
		<cfif application.includeDisqus and application.disqusApiKey neq "">
			<!--- Styles for disqus --->
			<style>
				.userProfile {
					margin: 15px 0;	 
					list-style-type: none;	 
					clear: both;
				}

				img.disqusAvatar {
					width: <cfif session.isMobile>32<cfelse>64</cfif>px;
					height: <cfif session.isMobile>32<cfelse>64</cfif>px;
					float: left;
					position: relative;
					z-index: 99;
					border: 0px;
					/* Pad the content to the right of the image */
					margin-right: 5px;
					/* The padding needs to be uniform, otherwise the avatar circle will be elongated */
					padding: <cfoutput>#avatarPadding#</cfoutput>;
					-moz-border-radius: 50%;
					-webkit-border-radius: 50%;
					-webkit-box-shadow: 0 1px 2px rgba(0,0,0,0.2);
					-moz-box-shadow: 0 1px 2px rgba(0,0,0,0.2);
					box-shadow: 0 1px 2px rgba(0,0,0,0.2);
					overflow: hidden;
				}

				#disqusComment a {
					overflow: hidden; /* Prevent wrapping */
				}

				#disqusComment p {
					display: inline; /* Prevent wrapping */
				}

				.comment-avatar img {
					width: 100%;
					height: 100%;
				}
			</style>

			<!--- If the blog owner has an API key, we are going to get the data from the Disqus API and build our own interface. --->
			<script type="<cfoutput>#scriptTypeString#</cfoutput>">
			
				// In classic mode, the sidebarType of 'div' gets loaded first, then the 'panel' gets loaded. In modern themes the sidebar on the right does not exist.
			<cfif sideBarType eq 'div' or modernTheme>

				function getRecentDisqusComments(){
	
					// Submit form via AJAX.
					$.ajax(
						{
							type: "get",
							url: "https://disqus.com/api/3.0/forums/listPosts.json?related=thread",
							data: {
								// Passing Disqus keys.
								api_key: "<cfoutput>#application.disqusApiKey#</cfoutput>",
								forum:  "<cfoutput>#application.disqusBlogIdentifier#</cfoutput>",
								limit: "<cfoutput>#numComments#</cfoutput>"
							},
							// jsponp is supported as well. 
							dataType: "json",
							cache: false,
							success: function(data) {
								setTimeout(function () {
									// Callback function
									getDisqusCommentsResponse(data);
								// The timeout ensures that the data will be available to the callback function.
								}, 250);
							}
						}
					);
				}//..function getRecentDisqusComments(){

				function getDisqusCommentsResponse(data){
					var html = "";
					// Handle empty data
					if (!data.response.length){
						$(document).ready(function() {
							$("#recentCommentsDiv").html('There are no comments');
							$("#recentCommentsPanel").html('There are no comments');
						});
					} else {
						// Loop through the json structure.
						for (var i = 0, len = data.response.length; i < len; i++) {
							// Isolate our post (or entry).
							var post = data.response[i];
							// Set a current row value from our index. I need a whole number to determine the alternating row color. I could just use [i]+1, but I am setting this for readability.
							var row = parseInt([i]);
							// Get the data for the post.
							var authorName = post.author.name;
							var authorProfileUrl = post.author.profileUrl;
							var authorAvatarUrl = post.author.avatar.cache;
							// We need to strip the HTML out of the comment. It has links that are not useful and will take up our space.
							var comment = stripHtml(post.message);
							var commentPromoted = post.isHighlighted;
							var approved = post.isApproved;
							// Get the timestamp and convert it into a proper js date object.
							var created = new Date(post.createdAt);
							// Find the link to the actual article. Note: for this to work, you must have related=thread appended to the ajax link (ie https://disqus.com/api/3.0/forums/listPosts.json?related=thread).
							var pageLink = post.thread.link;
							var pageTitle = post.thread.title;

							// Create the HTML. We will try to keep this nearly identical to the recent comment widget, but put in our own kendo classes here.
							// Create the table on the first row.
							if (row == 0){
								html += '<table id="disqusComment" align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">';
							}
							// Create the row and alternate the k-content and k-alt class.
							if (isOdd(row)){
								html += '<tr class="k-alt" height="50px;">';
							} else {
								html += '<tr class="k-content" height="50px;">';
							}
							// After the first iteration, create a row with a border. Javascript arrays (which is our 'row') start at 0.
							if (row == 0){
								html += '<td align="left" valign="top" class="userProfile">';
							} else {
								html += '<td align="left" valign="top" class="border userProfile">';
							}
							// Wrap the avatar with the authors profile link
							html += '<a href="' + authorProfileUrl + '" aria-label="Profile for ' + authorName + '" rel="nofollow noopener">' + authorName;
							// Place the avatar into the cell and close the anchor link.
							html += '<img class="disqusAvatar" src="' + authorAvatarUrl + '" aria-label="Profile for ' + authorName + '"></a><br/>';
							// Add the comment. The comment is already wrapped with a paragraph tag.
							html += truncateString(comment, <cfoutput>#lenComment#</cfoutput>) + '<br/>';
							// Create the HTML to insert into the page title.
							html += '<a href="' + pageLink + '" aria-label="' + pageLink + '">' + pageTitle + '</a> - ';
							// Add the timestamp to quickly identify how recent the post is.
							html += timeSince(new Date(created)) + ' ago<br/>';
							// Close the cell and the row.
							html += '</td></tr>';
							// Close the table on the last row
							if (row == <cfoutput>#round(numComments-1)#</cfoutput>){
								html += '</table>'
							}
							// Append the html to the page.
							$(document).ready(function() {
								$("#recentCommentsDiv").html(html);
								$("#recentCommentsPanel").html(html);
							});

						}//..for (var i = 0, len = data.response.length; i < len; i++) {
						
					}

				}

				// Helper function to determine if the numer is even or odd. This is used to create alternating row colors.
				function isOdd(num) {
					return num % 2;
				}

				function stripHtml(html){
					html.replace(/<[^>]*>?/gm, '');
					return html;
				}

				// Function to write out the time since the post.
				// Source: https://stackoverflow.com/questions/3177836/how-to-format-time-since-xxx-e-g-4-minutes-ago-similar-to-stack-exchange-site	
				function timeSince(date) {
				  var seconds = Math.floor((new Date() - date) / 1000);
				  var interval = Math.floor(seconds / 31536000);

				  if (interval > 1) {
					return interval + " years";
				  }
				  interval = Math.floor(seconds / 2592000);
				  if (interval > 1) {
					return interval + " months";
				  }
				  interval = Math.floor(seconds / 86400);
				  if (interval > 1) {
					return interval + " days";
				  }
				  interval = Math.floor(seconds / 3600);
				  if (interval > 1) {
					return interval + " hours";
				  }
				  interval = Math.floor(seconds / 60);
				  //alert(interval + ' minutes date: ' + date);
				  if (interval > 1) {
					return interval + " minutes";
				  }
				  return Math.floor(seconds) + " seconds";
				}
				
				truncateString = function(str, length, ending) {
					if (length == null) {
						length = 100;
					}
					if (ending == null) {
						ending = '...';
					}
					if (str.length > length) {
						return str.substring(0, length - ending.length) + ending;
					} else {
						return str;
					}
				};
				
  				// Call the method to populate the recent comments.
				getRecentDisqusComments();
				
				</cfif>
				
			</script>
		</cfif><!---<cfif application.includeDisqus and application.disqusApiKey neq "">--->
			<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="0" cellspacing="0">
		<cfif not application.includeDisqus>
			<cfif not arrayLen(getRecentComments)>
				<tr>
					<td class="k-content">
					<cfoutput>There are no recent comments.</cfoutput>
					</td>
				</tr>
			</cfif><!---<cfif not getComments.recordCount>--->
			<!--- Set a loop counter to mimic ColdFusion's currentRow --->
			<cfparam name="recentCommentLoopCount" default="1">
			<!--- Loop through the array --->
			<cfloop from="1" to="#arrayLen(getRecentComments)#" index="i">
				<cfsilent>
					<!--- Set the values. --->
					<cfset commentId =  getRecentComments[i]["CommentId"]>
					<cfset commentUuid =  getRecentComments[i]["CommentUuid"]>
					<cfset comment =  getRecentComments[i]["Comment"]>
					<cfset commentPostId = getRecentComments[i]["PostId"]>
					<cfset PostDatePosted = getRecentComments[i]["PostDatePosted"]>
					<cfset commentPostUuiId = getRecentComments[i]["PostUuid"]>
					<cfset commentPostAlias = getRecentComments[i]["PostAlias"]>
					<cfset commentPostTitle = getRecentComments[i]["PostTitle"]>
					<cfset commenterFullName = getRecentComments[i]["CommenterFullName"]>
					<cfset commenterEmail = getRecentComments[i]["CommenterEmail"]>
					<cfset commentDatePosted = getRecentComments[i]["DatePosted"]>

					<!--- Set the anchor link that will be wrapped around the title. There is extra logic required here as we need to grab this from various functions. --->

					<!--- Set the link --->
					<cfset commentLink = application.blog.makeCommentLink(commentPostId, PostDatePosted, commentPostAlias, commentId)>

					<!--- Shorten and format the comment.--->
					<cfset formattedComment = comment>
					<cfif len(formattedComment) gt len(lenComment)>
						<cfset formattedComment = left(formattedComment, lenComment)>
					</cfif>
					<cfset formattedComment = application.Udf.replaceLinks(formattedComment,25)>
					<cfif len(comment) gt lenComment>
						<cfset formattedComment = formattedComment & "...">
					</cfif>

				</cfsilent>
			<cfoutput>
			<tr class="#iif(recentCommentLoopCount MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
				<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
				We will create a border between the rows if the current row is not the first row. --->
				<cfif recentCommentLoopCount eq 1>
					<td valign="top">
				<cfelse>
					<td align="left" valign="top" class="border">
				</cfif>
					<!--- Create the comment link
					See notes above the showComment function on index.cfm template for more information.  --->
				<cftry>
					<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" title="#commenterFullName#'s Gravatar" alt="#commenterFullName#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
					<cfcatch type="any">
					</cfcatch>
				</cftry>
					<a href="#commentLink#" aria-label="#commentLink#" style="display: block; padding-top: 10px; padding-bottom: 5px;<cfif darkTheme> color:whitesmoke</cfif>">#commentPostTitle#:</a>
					<span style="display: block; padding-bottom: 10px; color:<cfif darkTheme>whitesmoke<cfelse>black</cfif>">#formattedComment#</span>
				</td>
			</tr>
			</cfoutput>
			<cfset recentCommentLoopCount = recentCommentLoopCount + 1>
			</cfloop>

	<cfelse><!---<cfif not application.includeDisqus>--->
		
		<!--- There are two ways to display the disqus recent comments: with an API key using the Disqus API, and without an API key using a recent comments widget. The method you take is up to you. ---> 
		<cfif application.disqusApiKey neq "">
				<tr>
					<td>
						<!--- Comments will be displayed here. --->
						<div id="<cfoutput>#recentCommentsElementId#</cfoutput>"></div>
					</td>
				</tr>
		<cfelse><!---<cfif application.disqusApiKey neq "">--->
			<tr class="k-content" height="75px;">
				<td align="left" valign="top" id="removeUlPadding">
					<!--- We are using the recent comments widget. --->
					<script type="text/javascript" src="https://<cfoutput>#application.disqusBlogIdentifier#</cfoutput>.disqus.com/recent_comments_widget.js?num_items=<cfoutput>#numComments#</cfoutput>&hide_avatars=0&avatar_size=40&excerpt_length=100"></script>
				</td>
			</tr>
		</cfif><!---<cfif application.disqusApiKey neq "">--->
	</cfif><!---<cfif not application.includeDisqus>--->				
		</table>
		<br/>
	</cfmodule>
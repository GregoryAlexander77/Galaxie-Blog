<!--- The post's comments (moved out of includes/templates/blogContentHtml.cfm on 2026-11-07, unchanged, so live updates can show
new comments with exactly the same markup: common/services/liveComments.cfm includes it too). Approved comments only, with their
replies one level deep. Needs: postId, postLink (the post's address) and allowComment. Has its own cfoutput (an include doesn't inherit the caller's). --->
<cfoutput>
									<table cellpadding="5" cellspacing="0" border="0" class="fixedCommentTable">
									 <tr width="100%">
									 <cftry>
									 <!--- Get the comments and loop through them. --->
									 <!--- Only approved comments (2026-10-22): comments waiting for approval were shown to everyone. --->
									 <cfset comments = application.blog.getComments(postId = postId, publicOnly = true)>
									 <cfsilent>
									 <!--- Replies (2026-10-22, owner): one level deep, under the comment that started the thread, oldest first. The
									 comments come newest first; a reply whose comment isn't shown is listed on its own. --->
									 <cfset commentById = {}>
									 <cfloop array="#comments#" index="oneComment"><cfset commentById[oneComment["CommentId"]] = true></cfloop>
									 <cfset topComments = []>
									 <cfset repliesByParent = {}>
									 <cfloop array="#comments#" index="oneComment">
										<cfset oneParentId = structKeyExists(oneComment, "ParentCommentId") and isNumeric(oneComment["ParentCommentId"]) ? oneComment["ParentCommentId"] : 0>
										<cfif oneParentId gt 0 and structKeyExists(commentById, oneParentId)>
											<cfif not structKeyExists(repliesByParent, oneParentId)><cfset repliesByParent[oneParentId] = []></cfif>
											<cfset arrayPrepend(repliesByParent[oneParentId], oneComment)>
										<cfelse>
											<cfset arrayAppend(topComments, oneComment)>
										</cfif>
									 </cfloop>
									 </cfsilent>
									 <cfparam name="commentLoopCount" default="1">
								<cfloop from="1" to="#arrayLen(topComments)#" index="i">
									 <cfset thread = [ topComments[i] ]>
									 <cfif structKeyExists(repliesByParent, topComments[i]["CommentId"])><cfset arrayAppend(thread, repliesByParent[topComments[i]["CommentId"]], true)></cfif>
									 <cfset rowClass = commentLoopCount mod 2 ? "k-content" : "k-alt">
									 <cfloop from="1" to="#arrayLen(thread)#" index="threadIndex">
										 <cfsilent>
										 <cfset c = thread[threadIndex]>
										 <cfset isReply = threadIndex gt 1>
										 <cfset commentId = c["CommentId"]>
										 <cfset comment = c["Comment"]>
										 <!--- Visitors type the name and website, so both are encoded for the page; a website that isn't an
										 http(s) address is left out (2026-10-14). --->
										 <cfset commenterFullName = encodeForHtml(c["CommenterFullName"] ?: "")>
										 <cfset commenterEmail = structKeyExists(c, "CommenterEmail") ? c["CommenterEmail"] : "">
										 <cfset commenterWebsite = structKeyExists(c, "CommenterWebsite") and reFindNoCase("^https?://[^\s""'<>]+$", trim(c["CommenterWebsite"])) ? encodeForHtmlAttribute(trim(c["CommenterWebsite"])) : "">
										 <!--- The blog's own author (a signed-in admin's comment is linked to their account). --->
										 <cfset commentByAuthor = structKeyExists(c, "UserName") and len(c["UserName"])>
										 <cfset commentDatePosted = c["DatePosted"]>
										 <!--- The post's own link plus #c and the comment's id (2026-10-31): it was built from the comment's date, not the
										 post's, so a comment made on a later day linked to a page that does not exist, and with #60 instead of #c60. --->
										 <cfset commentLink = postLink & "##c" & c["CommentId"]>
										 </cfsilent>
										 <!--- Note: the URL is appended with an extra 'c' in front of the commentId. --->
										 <tr id="c#commentId#" name="" class="#rowClass#">
											<td class="fixedCommentTableContent<cfif isReply> galaxieCommentReply</cfif>">
												 <cfif isReply>&##8627;<cfelse><a class="comment-id" href="#commentLink#" aria-label="Comment by #commenterFullName#" class="k-content">###i#</a></cfif> by <b>
												 <cfif len(commenterWebsite)>
													<a href="#commenterWebsite#" aria-label="#commenterFullName#" rel="nofollow">#commenterFullName#</a>
												 <cfelse>
													#commenterFullName#
												 </cfif></b><cfif commentByAuthor> &middot; Author</cfif>
												 on #dateFormat(commentDatePosted, "mmmm d, yyyy")# at #timeFormat(commentDatePosted, "h:mm tt")#</p>
											</td>
										 </tr>
										 <tr class="#rowClass#">
											<td<cfif isReply> class="galaxieCommentReply"</cfif>>
												<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" title="#commenterFullName#'s Gravatar" alt="#commenterFullName#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
												#application.Udf.formatComment(comment)#
												<!--- Reply (2026-10-22): a reply to a reply joins the same thread. --->
												<cfif allowComment><p class="galaxieCommentReplyLink"><button type="button" class="k-button" onclick="createAddCommentSubscribeWindow('#postId#', 'addComment', #session.isMobile#, #topComments[i]["CommentId"]#);" aria-label="Reply to #commenterFullName#">Reply</button></p></cfif>
											</td>
										 </tr>
									 </cfloop>
									 <!--- If the number of records is even, create the bottom border.--->
									 <cfif arrayLen(topComments) mod 2 is 0>
										 <tr class="<cfif commentLoopCount mod 2>k-alt<cfelse>k-content</cfif>">
											<td class="border"></td>
										 </tr>
									 </cfif>
									 <cfset commentLoopCount = commentLoopCount + 1>
								</cfloop>
								 <cfcatch type="any">
									<tr>
										<td>
											#cfcatch.detail#
										</td>
									</tr>
								 </cfcatch>
								 </cftry>
								</table>
</cfoutput>

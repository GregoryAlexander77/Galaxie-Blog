<!--- The Hero window's Hero text row, at the top (11-05, owner: the same as the gradient and animation windows). The post's heading
and the button that opens the window it is set in: the Hero text window, or for a moving hero the Moving hero window, whose heading
is the moving hero's own. Included by enclosureImageEditor.cfm, and by admin/loadPreview.cfm (previewId=6) when the Hero text or
the moving hero is saved. Needs getPost (getPostByPostId). --->
<cfsilent>
<cfset htPost = getPost[1]>
<cfset htPostId = val(htPost["PostId"])>
<cfset htMoving = application.blog.getScenes().getPostHeroParallax(htPostId)>
<cfif htMoving.active>
	<cfset htText = htMoving.heading>
	<cfset htWindow = 119>
<cfelse>
	<cfset htText = structKeyExists(htPost, "HeroOverlayText") and not isNull(htPost["HeroOverlayText"]) ? trim(toString(htPost["HeroOverlayText"])) : "">
	<cfset htWindow = 109>
</cfif>
</cfsilent>
<cfoutput>
Hero text:
<button type="button" class="k-button normalFontWeight" style="margin-left: 8px;" onclick="createAdminInterfaceWindow(#htWindow#, #htPostId#);"><i class="fontAwesomeIcon fas fa-heading" style="margin-right: 4px;"></i> Hero text...</button>
<span style="margin-left: 8px;">#len(htText) ? encodeForHtml(htText) : "None"#</span>
<cfif htMoving.active><span class="k-form-hint" style="display: block;">The moving hero's heading, set in its Moving hero window.</span></cfif>
</cfoutput>

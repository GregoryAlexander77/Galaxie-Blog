<!--- The Hero window's one line under the preview (11-04, owner: the window had "a lot of stuff at the bottom" that the wizards and
windows made confusing): what the post's hero is, and its cover, with the cover's window as a link. Included by
enclosureImageEditor.cfm, and by admin/loadPreview.cfm (previewId=5) when galaxieRefreshHeroEditorPreview() redraws it after a save.
Needs getPost (getPostByPostId). --->
<cfsilent>
<!--- From Hero.cfc (2026-11-06, the hero pipeline): the same answer as the Edit Post row, the cards and sharing. --->
<cfset hsHero = application.blog.getHeroes().getAdminHero(getPost[1])>
<cfset hsPostId = val(getPost[1]["PostId"])>
<cfset hsLink = function (text) { return ' <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">' & text & '</a>'; }>
<cfset hsHeroText = hsHero.kind eq "none" ? "none yet. Use the buttons above to add one" : hsHero.sentence>
<cfif hsHero.cover.unused>
	<cfset hsCover = hsHero.cover.state & "." & hsLink("Cover")>
<cfelseif len(hsHero.coverUrl)>
	<cfset hsCover = "set." & hsLink("Change the cover")>
<cfelseif hsHero.cover.state eq "the hero picture">
	<cfset hsCover = "the hero picture, so no cover is needed">
<cfelseif hsHero.cover.state eq "none" and hsHero.cardShowsMedia>
	<cfset hsCover = "none yet, so sharing has no picture (cards show the " & hsHero.mediaKind & ")." & hsLink("Add a cover")>
<cfelseif hsHero.cover.state eq "none">
	<cfset hsCover = "none yet, so cards and sharing have no picture." & hsLink("Add a cover")>
<cfelse>
	<cfset hsCover = hsHero.cover.state & ", for sharing." & hsLink("Use a different cover")>
</cfif>
</cfsilent>
<cfoutput><span id="heroStatusLine">Hero: #encodeForHtml(hsHeroText)#. Cover: #hsCover#</span></cfoutput>

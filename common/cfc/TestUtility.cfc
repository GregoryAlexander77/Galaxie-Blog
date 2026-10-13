<cfcomponent displayName="TestUtility" output="false" hint="Reusable dev/test diagnostics and one-off data-repair tools, grown out of throwaway debug scripts written during 2026-09 dev sessions. See feedback-test-utility-cfc memory for why this exists as one component instead of a folder of standalone .cfm scripts: one file to grep for existing tools, shared auth/dry-run handling instead of copy-pasted boilerplate, and it matches this codebase's own ProxyController.cfc pattern (a component full of access=remote methods, each starting with an auth check). Lives in common/cfc/ alongside every other real app component (moved here from common/utilities/ on 2026-09-25 once the file had settled down) - see reminder-move-testutility-to-common-cfc memory.">

<!---
	*************************************************************************************************************
	Every public method here is meant to be hit directly in a browser while logged into the admin interface,
	e.g.:  /common/cfc/TestUtility.cfc?method=checkThemeBackgroundImages
	       /common/cfc/TestUtility.cfc?method=importPostsFromRss&confirm=true
	Every method calls requireEditSiteAccess() as its first line - a logged-in session with the
	EditServerSetting capability (the same one gating Blog Settings/Blog Options in the admin toolbar) is
	required for all of them. Anything that writes to the database defaults to a dry run; pass confirm=true
	to actually persist.
	*************************************************************************************************************
--->

<cffunction name="requireEditSiteAccess" access="private" returntype="void" output="yes"
		hint="Shared guard for every public method below. These tools can read and rewrite live database rows, so they must never be reachable by an unauthenticated request.">
	<!--- statustext dropped from both cfheader calls below - Lucee supports it as an extension, but Adobe
	ColdFusion's cfheader only accepts CHARSET/NAME/STATUSCODE/VALUE and hard-errors on an unknown attribute,
	confirmed via a live 500 on CF2025 dev (this guard, called by every method in this file, had never actually
	run there before this). statuscode alone is sufficient - the numeric code is what actually matters for the
	response, the reason phrase is cosmetic. --->
	<cfif not application.Udf.isLoggedIn()>
		<cfheader statuscode="403">
		<cfoutput>Access denied - log in to the admin interface first.</cfoutput>
		<cfabort>
	</cfif>
	<cfset var proxyController = createObject("component", application.proxyControllerComponentPath)>
	<cfif not proxyController.authorizedCapability("EditServerSetting")>
		<cfheader statuscode="403">
		<cfoutput>Access denied - your account doesn't have the Edit Site capability.</cfoutput>
		<cfabort>
	</cfif>
</cffunction>

<!---
	*************************************************************************************************************
	dumpPostHero

	Read-only - dumps a single Post's Hero* fields (gradient/overlay text-color-font, animation effect/options)
	straight from the entity, bypassing getPost()'s HQL/PostStruct copy-step entirely. Useful whenever the
	rendered HTML doesn't match what was just saved - tells you immediately whether the problem is "didn't
	persist" (this comes back empty) vs. "persisted fine, something in the render/getPost() path is wrong"
	(this shows the real value). /common/cfc/TestUtility.cfc?method=dumpPostHero&postId=123
	*************************************************************************************************************
--->
<cffunction name="dumpPostHero" access="remote" returntype="void" output="yes">
	<cfargument name="postId" type="numeric" required="true">
	<cfset requireEditSiteAccess()>
	<cfset var post = entityLoadByPK("Post", arguments.postId)>
	<cfif not isObject(post)>
		<cfoutput>No post found for postId=#arguments.postId#</cfoutput>
		<cfreturn>
	</cfif>
	<cfoutput>
		--- Direct entity read ---<br>
		HeroGradient: [#post.getHeroGradient()#]<br>
		HeroOverlayText: [#post.getHeroOverlayText()#]<br>
		HeroOverlayTextColor: [#post.getHeroOverlayTextColor()#]<br>
		HeroOverlayFont: [#post.getHeroOverlayFont()#]<br>
		HeroAnimationEffect: [#post.getHeroAnimationEffect()#]<br>
		HeroAnimationOptions: [#post.getHeroAnimationOptions()#]<br>
		HeroCoverImageUrl: [#post.getHeroCoverImageUrl()#]<br>
	</cfoutput>
	<!--- Also call the real getPost() path, isolating whether the problem is inside that function vs.
	somewhere downstream of it (renderMediaPreview/postDetail.cfm). --->
	<cfset var viaGetPost = application.blog.getPost(postIdList=arguments.postId, showPendingPosts=true, showRemovedPosts=true)>
	<cfoutput>
		<br>--- Via application.blog.getPost(postIdList=#arguments.postId#) ---<br>
		arrayLen: [#arrayLen(viaGetPost)#]<br>
		<cfif arrayLen(viaGetPost)>
			HeroGradient: [#viaGetPost[1]["HeroGradient"]#]<br>
			HeroOverlayText: [#viaGetPost[1]["HeroOverlayText"]#]<br>
			HeroOverlayTextColor: [#viaGetPost[1]["HeroOverlayTextColor"]#]<br>
			<cfset var hasOverlayFontKey = structKeyExists(viaGetPost[1], "HeroOverlayFont")>
			HeroOverlayFont key exists: [#hasOverlayFontKey#]<br>
			<cfif hasOverlayFontKey>
				HeroOverlayFont: [#viaGetPost[1]["HeroOverlayFont"]#]<br>
			</cfif>
			<cfset var hasCoverImageKey = structKeyExists(viaGetPost[1], "HeroCoverImageUrl")>
			HeroCoverImageUrl key exists: [#hasCoverImageKey#]<br>
			<cfif hasCoverImageKey>
				HeroCoverImageUrl: [#viaGetPost[1]["HeroCoverImageUrl"]#]<br>
			</cfif>
		</cfif>
	</cfoutput>
</cffunction>

<!--- 2026-10-01: diagnostic for the curated-homepage promoted-post highlight bug - lists every post with
Promote=true (Post.Promote, aliased "Promoted" by getPost()'s own SELECT) so you can confirm whether a post the
user expects to see highlighted actually has the flag set, without guessing a postId first. --->
<cffunction name="dumpPromotedPosts" access="remote" returntype="void" output="yes">
	<cfset requireEditSiteAccess()>
	<cfset var getPromoted = application.blog.getPost(showPromoteAtTopOfQuery=true, params={maxEntries: 500, startRow: 1})>
	<cfoutput>
		arrayLen: [#arrayLen(getPromoted)#]<br><br>
	</cfoutput>
	<cfloop from="1" to="#arrayLen(getPromoted)#" index="i">
		<cfset var hasPromotedKey = structKeyExists(getPromoted[i], "Promoted")>
		<cfoutput>
			PostId: [#getPromoted[i]["PostId"]#] Title: [#getPromoted[i]["Title"]#] hasPromotedKey: [#hasPromotedKey#]<cfif hasPromotedKey> Promoted: [#getPromoted[i]["Promoted"]#]</cfif><br>
		</cfoutput>
	</cfloop>
</cffunction>

<!--- 2026-10-01: companion to dumpPromotedPosts() above - lets you toggle a post's Promote flag directly for
testing the promoted-post highlight without fighting the admin post editor's own save-confirmation dialogs
(verifyPostEmail()'s subscriber-email prompt, etc.). --->
<cffunction name="setPostPromoted" access="remote" returntype="void" output="yes">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="promoted" type="boolean" required="true">
	<cfset requireEditSiteAccess()>
	<cfset var post = entityLoadByPK("Post", arguments.postId)>
	<cfif not isObject(post)>
		<cfoutput>No post found for postId=#arguments.postId#</cfoutput>
		<cfreturn>
	</cfif>
	<cfset post.setPromote(arguments.promoted)>
	<cfset entitySave(post)>
	<cfset ormFlush()>
	<cfoutput>postId=#arguments.postId# Promote set to #arguments.promoted#</cfoutput>
</cffunction>

<!--- 2026-10-01: companion cleanup helper for Hero Cover Image testing - clears HeroCoverImageUrl back to
empty without needing to go through the admin upload UI. --->
<cffunction name="clearHeroCoverImage" access="remote" returntype="void" output="yes">
	<cfargument name="postId" type="numeric" required="true">
	<cfset requireEditSiteAccess()>
	<cfset application.blog.savePostHeroCoverImage(postId=arguments.postId, heroCoverImageUrl="")>
	<cfoutput>postId=#arguments.postId# HeroCoverImageUrl cleared</cfoutput>
</cffunction>

<!--- 2026-10-01: live test for blog.cfc's new getComplementaryColor()/getRotatedThemeColors() - confirms
java.awt.Color's RGBtoHSB/HSBtoRGB round-trips correctly through Lucee/CF's Java marshalling (the one thing not
yet verified about this approach) against the site's actual current theme, before wiring it into
Image.cfc's generateHeroArt()/generateAnimationDefault(). --->
<cffunction name="testComplementaryColors" access="remote" returntype="void" output="yes">
	<cfset requireEditSiteAccess()>
	<cfset var kendoTheme = application.blog.getSelectedKendoTheme()>
	<cfset var accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme=kendoTheme, setting="accentColor")>
	<cfset var complement = application.blog.getComplementaryColor(accentColor)>
	<cfset var rotated = application.blog.getRotatedThemeColors(kendoTheme=kendoTheme, count=8)>
	<cfoutput>
		kendoTheme: [#kendoTheme#]<br>
		accentColor: [###accentColor#]<br>
		complement of accentColor: [###complement#]<br>
		complement of complement (should round-trip back to accentColor): [###application.blog.getComplementaryColor(complement)#]<br>
		<br>
		getRotatedThemeColors(count=8):<br>
		<cfloop from="1" to="#arrayLen(rotated)#" index="i">
			[#i#]: ###rotated[i]#<br>
		</cfloop>
	</cfoutput>
	<!--- End-to-end check: generateHeroArt() actually writes a real SVG using these colors - postId mod 8 runs
	through 0-7 (200-207) so every one of the 8 rotation angles gets exercised, since the flat-gradient bug
	(fixed 2026-10-01) only showed up for some angles, not all. --->
	<cfobject component="#application.imageComponentPath#" name="ImageTestObj">
	<cfoutput>
		<br>
		<cfloop array="#[200,201,202,203,204,205,206,207]#" index="testPostId">
			generateHeroArt(#testPostId#) angle=#(testPostId mod 8) * 45#: <a href="#ImageTestObj.generateHeroArt(testPostId)#" target="_blank">#ImageTestObj.generateHeroArt(testPostId)#</a><br>
		</cfloop>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	setDebugTrace

	Turns Udf.cfc's session-scoped debugTrace() tracer on or off for your own admin session only - use to
	capture a fresh trace of a suspect code path while reproducing a hard-to-catch "no error, but nothing
	happened" bug, then turn it back off. See galaxieDebugTrace.log (same folder as galaxieBlogErrors.log) for
	the actual trace output once enabled.
	*************************************************************************************************************
--->
<cffunction name="setDebugTrace" access="remote" returntype="string" output="false" returnformat="plain"
		hint="Turns the session-scoped debugTrace() tracer on or off for your own admin session only.">
	<!--- returnformat="plain" - without it, a remote CFC method hit directly by URL defaults to Content-Type:
	text/xml (WDDX), which Firefox renders as a hard XML parse error the moment the body isn't well-formed XML
	(a plain confirmation string here, or the full styled error page on a 403). Chrome/Edge tolerate it, which is
	why this went unnoticed on the other methods in this file - same fix would apply to those if it comes up.
	returntype must be "string" (not "void") and the confirmation must be a real <cfreturn>, not <cfoutput> -
	confirmed via a live 500 on Adobe ColdFusion (though not Lucee, which tolerated the original void+plain
	combination fine): "RETURNFORMAT cannot be plain for a complex return type", and ACF treats void as complex
	for this purpose. --->
	<cfargument name="enabled" type="boolean" required="false" default="true">

	<cfset requireEditSiteAccess()>
	<cfset session.debugTraceEnabled = arguments.enabled>
	<cfreturn "debugTrace is now " & (arguments.enabled ? "ON" : "OFF") & " for this session. Log file: galaxieDebugTrace.log (same folder as galaxieBlogErrors.log).">
</cffunction>

<!---
	*************************************************************************************************************
	setSuppressOutput

	Lucee's Application.cfc OnRequestStart sets <cfsetting enablecfoutputonly="true"> (suppressing the raw
	whitespace its own <cfset>/<cfif> plumbing would otherwise emit on every single request) unless this session
	has turned it off. Turn it off (enabled=false) only while you specifically need to see a debug-gated
	<cfoutput> block in Application.cfc itself (the ones guarded by the hardcoded "debug" var near the top of the
	file) - normal debugging of everything else (TestUtility's own tools, ProxyController methods, etc.) doesn't
	need this. Turn it back on (enabled=true, the default) when done. Kept in this file for consistency across all
	three copies even though this specific Application.cfc (CF2025 dev's /blog-subfolder install) hasn't had the
	matching enablecfoutputonly fix applied yet - see reminder-onrequeststart-whitespace-cleanup memory.
	*************************************************************************************************************
--->
<cffunction name="setSuppressOutput" access="remote" returntype="string" output="false" returnformat="plain"
		hint="Turns Application.cfc's OnRequestStart whitespace suppression on (normal, the default) or off (verbose, for debugging) for your own admin session only.">
	<!--- returntype="string" + <cfreturn>, not "void" + <cfoutput> - see setDebugTrace's own comment on why;
	same fix applies here since this was copied from that function. --->
	<cfargument name="enabled" type="boolean" required="false" default="true">

	<cfset requireEditSiteAccess()>
	<cfset session.outputSuppressionEnabled = arguments.enabled>
	<cfreturn "Output suppression is now " & (arguments.enabled ? "ON (normal)" : "OFF (verbose/debug)") & " for this session.">
</cffunction>

<cffunction name="reloadOrm" access="remote" returntype="string" output="false" returnformat="plain"
		hint="Forces Hibernate to reload every ORM entity's mapping (a fresh SessionFactory) and, per this.ormSettings.dbcreate='update' in Application.cfc, run any pending ALTER TABLE for a newly added <cfproperty> - without a full server restart or OS-level service-restart rights. A plain .cfc file edit (e.g. adding a new PageCollection.cfc property) does NOT trigger this on its own - CFML happily recompiles the .cfc source on next reference, but the ORM mapping/schema it was built from stays cached until something explicitly reloads it. Before this method existed, the only options were ?reloadOrm (needs an admin login, which this same login already satisfies) or editing Application.cfc's this.name to force a whole fresh application scope (a bigger hammer - see the still-suffixed '_ormfix' comment there from 2026-09-27, which this method replaces going forward).">
	<cfset requireEditSiteAccess()>
	<cfset ORMReload()>
	<cfreturn "ORM reloaded - new/changed entity properties and any pending schema update should now be live.">
</cffunction>

<cffunction name="checkAndFixNullColumns" access="remote" returntype="void" output="yes"
		hint="Checks every row of a given ORM entity for a NULL value in one or more properties and optionally backfills to a type-appropriate default (false for boolean, 0 for numeric, '' otherwise). The recurring gap this generalizes: a <cfproperty default='...'> added to an already-populated entity only applies that default to NEW rows created in code - dbcreate='update' creates the column, but every pre-existing row keeps a true SQL NULL until saved once. That NULL then trips things downstream (a HQL 'SELECT new Map(...)' silently omits the key on Lucee - see checkAndFixMissingBlogRef's own BlogRef case, PageCollection.HeroGradient/HeroOverlayText/HeroOverlayTextColor from 2026-09-27, and BlogOption.HomepageShowPages/HomepageShowCollections/HomepageShowBlogPosts from the 2026-09-28 galaxieblog.org deploy - that last case is exactly why this function now picks a type-aware default instead of always using '': blindly setting a boolean property to '' silently failed to actually clear the NULL, since Hibernate can't coerce an empty string into a boolean). Defaults to a dry run - pass confirm=true to actually persist (calls ormFlush()).">
	<cfargument name="entityName" type="string" required="true" hint="e.g. 'PageCollection'.">
	<cfargument name="propertyList" type="string" required="true" hint="Comma-separated property names as declared in the entity's own <cfproperty name=...>, e.g. 'HeroGradient,HeroOverlayText,HeroOverlayTextColor'.">
	<cfargument name="confirm" type="boolean" required="false" default="false" hint="true actually applies + ormFlush(); false just reports what was found.">

	<cfset requireEditSiteAccess()>
	<cfsetting requesttimeout="60">

	<cfset var rows = entityLoad(arguments.entityName)>
	<cfset var row = "">
	<cfset var propName = "">
	<cfset var propArray = listToArray(arguments.propertyList)>
	<cfset var fixed = []>
	<cfset var rowHasNull = false>
	<cfset var idValue = "">
	<cfset var f = "">
	<cfset var entityMeta = getMetaData(entityNew(arguments.entityName))>
	<cfset var propMeta = "">
	<cfset var ormType = "">
	<cfset var fieldType = "">
	<cfset var isRelationship = false>
	<cfset var defaultForType = "">
	<cfloop array="#rows#" index="row">
		<cfset rowHasNull = false>
		<cfloop array="#propArray#" index="propName">
			<!--- Check the property's declared ormtype/fieldtype BEFORE deciding whether a NULL here even
			counts as something to fix. A relationship property (fieldtype="many-to-one" etc.) staying NULL is
			its correct, expected state when nothing has been assigned yet (eg. HeroImagePoolCarouselRef with
			no Hero Image Pool carousel configured) - there is no sensible non-null default for an optional
			reference. The original crash on gregoryalexander.com (2026-09-28) wasn't caused by this property
			being NULL at all; it was caused by an earlier version of THIS function trying to force a non-null
			value onto it anyway (a raw 0 threw ClassCastException on flush; explicit null-sets that followed
			were silent no-ops, since it was already correctly null). The real fix is simpler than any of
			that: skip relationship properties from this check entirely, same as any other property that's
			legitimately allowed to be NULL. --->
			<cfset ormType = "">
			<cfset fieldType = "">
			<cfloop array="#entityMeta.properties#" index="propMeta">
				<cfif structKeyExists(propMeta, "name") and propMeta.name eq propName>
					<cfif structKeyExists(propMeta, "ormtype")>
						<cfset ormType = lCase(propMeta.ormtype)>
					</cfif>
					<cfif structKeyExists(propMeta, "fieldtype")>
						<cfset fieldType = lCase(propMeta.fieldtype)>
					</cfif>
				</cfif>
			</cfloop>
			<cfset isRelationship = listFindNoCase("many-to-one,one-to-one,one-to-many,many-to-many", fieldType) gt 0>
			<cfif not isRelationship and isNull(invoke(row, "get" & propName))>
				<cfset rowHasNull = true>
				<cfif arguments.confirm>
					<!--- Pick a default matching this property's own declared ormtype - setting a boolean/numeric
					property to '' silently fails to clear a NULL (Hibernate can't coerce it), which is exactly
					the bug that made this function report "fixed" while HomepageShowPages stayed NULL. --->
					<cfif listFindNoCase("boolean", ormType)>
						<cfset defaultForType = false>
					<cfelseif listFindNoCase("int,integer,numeric,float,double,big_decimal,short,long", ormType)>
						<cfset defaultForType = 0>
					<cfelse>
						<cfset defaultForType = "">
					</cfif>
					<cfset invoke(row, "set" & propName, [defaultForType])>
				</cfif>
			</cfif>
		</cfloop>
		<cfif rowHasNull>
			<!--- This codebase's own convention (see PageCollectionId/ThemeId/UserId etc.) is EntityName & "Id" -
			good enough for a readable label, falls back to a plain "?" rather than throwing if some entity
			doesn't follow it. --->
			<cftry>
				<cfset idValue = invoke(row, "get" & arguments.entityName & "Id")>
				<cfcatch type="any">
					<cfset idValue = "?">
				</cfcatch>
			</cftry>
			<cfset arrayAppend(fixed, "#arguments.entityName# id=#idValue#")>
		</cfif>
	</cfloop>
	<cfif arguments.confirm and arrayLen(fixed)>
		<cfset ormFlush()>
	</cfif>

	<cfoutput>
	<h2>#(arguments.confirm ? "Fixed" : "Dry run (add confirm=true to apply)")#</h2>
	<p>Entity: #arguments.entityName#, properties checked: #arguments.propertyList#</p>
	</cfoutput>
	<ul>
	<cfloop array="#fixed#" index="f">
		<li><cfoutput>#f#</cfoutput></li>
	</cfloop>
	</ul>
	<cfoutput><p><strong>#arrayLen(fixed)#</strong> row(s) with at least one NULL property #(arguments.confirm ? "fixed." : "found.")#</p></cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	checkThemeBackgroundImages

	Loads every Theme + its ThemeSetting and makes a real HTTP request (via this same server) to every image
	path field it finds (background, header, menu, logo, footer, social-share). Reports any URL that doesn't
	come back 200.

	Why HTTP instead of fileExists()/directoryList(): on Windows, NTFS is case-insensitive, so a mismatched
	case in a stored path will always "exist" as far as CFML file functions are concerned - it silently works.
	But Tomcat/Lucee's static resource serving (via the images junction) IS case-sensitive at the
	URL-to-resource lookup layer, so a bad-case path 404s in the browser even though fileExists() would say
	true. Making the actual HTTP request is the only way to reproduce what a real visitor/theme-tester sees.
	See doc/caseSensitivityWindowsWontWarnYou for the background on this.
	*************************************************************************************************************
--->
<cffunction name="checkThemeBackgroundImages" access="remote" returntype="void" output="yes"
		hint="Checks every theme's background/header/menu/logo/footer image URL for 404s, including case-only mismatches Windows hides.">
	<cfargument name="theme" type="string" required="false" default="" hint="Limit the check to a single theme alias instead of all of them.">

	<cfset requireEditSiteAccess()>
	<cfsetting requesttimeout="120">

	<cfset var stringFields = ["BlogBackgroundImage","BlogBackgroundImageMobile","HeaderBackgroundImage","HeaderBodyDividerImage",
		"MenuBackgroundImage","LogoImageMobile","LogoImage","DefaultLogoImageForSocialMediaShare","FooterImage"]>
	<!--- application.baseUrl is often "" for a root install, which isn't a valid absolute URL for cfhttp -
	build the real request origin instead so this works on any install (root or /blog subfolder). --->
	<cfset var serverOrigin = (cgi.https eq "on" ? "https" : "http") & "://" & cgi.http_host>
	<cfset var themes = entityLoad("Theme")>
	<cfset var checks = []>
	<cfset var t = "">
	<cfset var ts = "">
	<cfset var fn = "">
	<cfset var getter = "">
	<cfset var val = "">
	<cfset var chk = "">
	<cfset var httpResult = "">
	<cfset var code = "">
	<cfset var failCount = 0>

	<cfloop array="#themes#" index="t">
		<cfif len(arguments.theme) and compareNoCase(t.getThemeAlias(), arguments.theme) neq 0>
			<cfcontinue>
		</cfif>
		<cfset ts = t.getThemeSettingRef()>
		<cfloop array="#stringFields#" index="fn">
			<cfset getter = "get" & fn>
			<cfset val = "">
			<cftry>
				<cfset val = evaluate("ts.#getter#()")>
				<cfcatch type="any">
					<cfset val = "">
				</cfcatch>
			</cftry>
			<cfif len(val)>
				<cfset arrayAppend(checks, {"theme": t.getThemeAlias(), "field": fn, "path": val})>
			</cfif>
		</cfloop>
	</cfloop>

	<cfoutput>
	<h2>Theme background/image URL check<cfif len(arguments.theme)> - #arguments.theme#</cfif></h2>
	<p>#arrayLen(checks)# paths checked against #serverOrigin#</p>
	</cfoutput>

	<table border="1" cellpadding="4" cellspacing="0">
	<tr><th>Status</th><th>Theme</th><th>Field</th><th>Path</th></tr>
	<cfloop array="#checks#" index="chk">
		<cfhttp url="#serverOrigin##application.baseUrl##chk.path#" method="head" result="httpResult" timeout="10" throwonerror="false" />
		<cfset code = isDefined("httpResult.statusCode") ? httpResult.statusCode : "ERR">
		<cfif code does not contain "200">
			<cfset failCount++>
			<tr style="background:##ffe0e0">
				<cfoutput>
				<td>#code#</td>
				<td>#chk.theme#</td>
				<td>#chk.field#</td>
				<td>#chk.path#</td>
				</cfoutput>
			</tr>
		</cfif>
	</cfloop>
	</table>
	<cfoutput><p><strong>#failCount#</strong> broken path(s) found.</p></cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	reportNonWebpEnclosures

	Lists every Post/Page whose Image-type enclosure isn't already a .webp file - the same "Swap in WebP Version"
	tool built into enclosureImageEditor.cfm applies to each of these one at a time; this is just the inventory of
	which ones still need it. Read-only, no dry-run/confirm needed.
	*************************************************************************************************************
--->
<cffunction name="reportNonWebpEnclosures" access="remote" returntype="void" output="yes"
		hint="Lists every post/page whose Image-type enclosure is not already a .webp file.">
	<cfset requireEditSiteAccess()>

	<cfset var getRows = "">
	<cfset var row = "">
	<cfset var rowCount = 0>

	<cfquery name="getRows" dbtype="hql">
		SELECT new Map (
			Post.PostId as PostId,
			Post.Title as Title,
			Post.IsPage as IsPage,
			Post.Released as Released,
			Enclosure.MediaUrl as MediaUrl
		)
		FROM Post as Post
		INNER JOIN Post.EnclosureMedia as Enclosure
		INNER JOIN Enclosure.MediaTypeRef as MediaType
		WHERE Post.Remove = 0
			AND MediaType.MediaType = 'Image'
			AND Enclosure.MediaUrl NOT LIKE '%.webp'
		ORDER BY Post.IsPage, Post.Title
	</cfquery>
	<cfset rowCount = arrayLen(getRows)>

	<cfoutput>
	<h2>Enclosure images that are not WebP</h2>
	<p><strong>#rowCount#</strong> post(s)/page(s) with a non-WebP image enclosure.</p>
	</cfoutput>

	<table border="1" cellpadding="4" cellspacing="0">
	<tr><th>PostId</th><th>Type</th><th>Released</th><th>Title</th><th>Enclosure File</th></tr>
	<cfloop array="#getRows#" index="row">
		<cfoutput>
		<tr>
			<td>#row.PostId#</td>
			<td>#row.IsPage ? "Page" : "Post"#</td>
			<td>#row.Released ? "Yes" : "No"#</td>
			<td>#row.Title#</td>
			<td>#row.MediaUrl#</td>
		</tr>
		</cfoutput>
	</cfloop>
	</table>
</cffunction>

<!---
	*************************************************************************************************************
	verifyPaginationCoverage

	Walks a paginated listing exactly the way the real pager does - startRow=1 (offset 0) for page 1, then
	firstPageSize + (page-2)*maxEntries for every page after that, fetching page by page via the real
	blog.cfc getPost() - and diffs the combined PostIds collected against a single unpaginated fetch of the
	same filter. Reports any post that never showed up on any page (a gap) or showed up on more than one (a
	duplicate). Built 2026-09-30 while verifying the homepage's column-aware page-2+ row-budget fix (see
	[[curated-homepage-page2-row-count-fix-2026-09-30]]) - pass firstPageSize/maxEntries to match whatever page
	size math you're testing:
	  - Homepage row-budget, page 1: firstPageSize = finalBlogPageSize (rows*columns from the featured-content
	    budget), maxEntries = 5*columns (15 desktop, 5 mobile/narrow-sidebar).
	  - A plain category/tag/day/full listing: firstPageSize and maxEntries are both just application.maxEntries
	    (9) - every page, including page 1, is the same flat size.
	Read-only, no dry-run/confirm needed - it only calls getPost(), never writes anything.
	*************************************************************************************************************
--->
<cffunction name="verifyPaginationCoverage" access="remote" returntype="string" output="false" returnformat="plain"
		hint="Walks a paginated getPost() listing page by page like the real pager and diffs it against an unpaginated fetch, to confirm every post is shown exactly once.">
	<cfargument name="firstPageSize" type="numeric" required="false" default="9" hint="Page 1's size - finalBlogPageSize for the homepage row-budget, or plain application.maxEntries (9) for a normal listing.">
	<cfargument name="maxEntries" type="numeric" required="false" default="9" hint="Page 2+'s size - 5*columns (15 desktop/5 mobile) for the homepage row-budget, or plain application.maxEntries (9) for a normal listing.">
	<cfargument name="showPages" type="boolean" required="false" default="false">
	<cfargument name="showBlogPosts" type="boolean" required="false" default="true">
	<cfargument name="byCat" type="string" required="false" default="" hint="Optional categoryId to scope the check to one category, matching a category archive's own pagination.">
	<cfargument name="byTag" type="string" required="false" default="" hint="Optional tagId to scope the check to one tag, matching a tag archive's own pagination.">

	<cfset requireEditSiteAccess()>

	<cfset var baseParams = structNew()>
	<cfset var fullParams = structNew()>
	<cfset var pageParams = structNew()>
	<cfset var fullList = "">
	<cfset var pageResults = "">
	<cfset var fullIds = []>
	<cfset var seenIds = []>
	<cfset var seenCounts = structNew()>
	<cfset var pageLog = []>
	<cfset var duplicates = []>
	<cfset var missing = []>
	<cfset var extra = []>
	<cfset var row = "">
	<cfset var key = "">
	<cfset var startRow = 0>
	<cfset var thisMax = 0>
	<cfset var pageNum = 1>
	<cfset var reportHtml = "">

	<cfif len(arguments.byCat)><cfset baseParams.byCat = arguments.byCat></cfif>
	<cfif len(arguments.byTag)><cfset baseParams.byTag = arguments.byTag></cfif>

	<!--- The full, unpaginated reference set - same filter, no real-world page size limit. --->
	<cfset fullParams = duplicate(baseParams)>
	<cfset fullParams.maxEntries = 99999>
	<cfset fullParams.startRow = 1>
	<cfinvoke component="#application.blog#" method="getPost" returnvariable="fullList">
		<cfinvokeargument name="params" value="#fullParams#">
		<cfinvokeargument name="showPages" value="#arguments.showPages#">
		<cfinvokeargument name="showBlogPosts" value="#arguments.showBlogPosts#">
		<cfinvokeargument name="showPromoteAtTopOfQuery" value="true">
	</cfinvoke>
	<cfloop array="#fullList#" index="row">
		<cfset arrayAppend(fullIds, row.PostId)>
	</cfloop>

	<!--- Walk it page by page, using the exact same startRow stepping formula blogContentHtml.cfm's own pager
	link generation uses, until a page comes back empty. A 200-page safety valve guards against an infinite
	loop if firstPageSize/maxEntries is passed in as 0. --->
	<cfloop condition="pageNum lte 200">
		<cfset pageParams = duplicate(baseParams)>
		<cfif pageNum eq 1>
			<cfset startRow = 1>
			<cfset thisMax = arguments.firstPageSize>
		<cfelse>
			<cfset startRow = arguments.firstPageSize + ((pageNum - 2) * arguments.maxEntries)>
			<cfset thisMax = arguments.maxEntries>
		</cfif>
		<cfif thisMax lte 0>
			<cfset arrayAppend(pageLog, "Page #pageNum#: stopped - page size is #thisMax#, would loop forever.")>
			<cfbreak>
		</cfif>
		<cfset pageParams.startRow = startRow>
		<cfset pageParams.maxEntries = thisMax>
		<cfinvoke component="#application.blog#" method="getPost" returnvariable="pageResults">
			<cfinvokeargument name="params" value="#pageParams#">
			<cfinvokeargument name="showPages" value="#arguments.showPages#">
			<cfinvokeargument name="showBlogPosts" value="#arguments.showBlogPosts#">
			<cfinvokeargument name="showPromoteAtTopOfQuery" value="true">
		</cfinvoke>
		<cfif arrayLen(pageResults) eq 0>
			<cfbreak>
		</cfif>
		<cfset arrayAppend(pageLog, "Page #pageNum#: startRow=#startRow# requested=#thisMax# fetched=#arrayLen(pageResults)#")>
		<cfloop array="#pageResults#" index="row">
			<cfif structKeyExists(seenCounts, row.PostId)>
				<cfset seenCounts[row.PostId] = seenCounts[row.PostId] + 1>
			<cfelse>
				<cfset seenCounts[row.PostId] = 1>
				<cfset arrayAppend(seenIds, row.PostId)>
			</cfif>
		</cfloop>
		<cfset pageNum = pageNum + 1>
	</cfloop>

	<!--- Diff against the unpaginated reference set. --->
	<cfloop collection="#seenCounts#" item="key">
		<cfif seenCounts[key] gt 1>
			<cfset arrayAppend(duplicates, key & " (shown " & seenCounts[key] & "x)")>
		</cfif>
	</cfloop>
	<cfloop array="#fullIds#" index="row">
		<cfif not arrayFind(seenIds, row)>
			<cfset arrayAppend(missing, row)>
		</cfif>
	</cfloop>
	<cfloop array="#seenIds#" index="row">
		<cfif not arrayFind(fullIds, row)>
			<cfset arrayAppend(extra, row)>
		</cfif>
	</cfloop>

	<cfsavecontent variable="reportHtml">
	<cfoutput>
	<h2>Pagination coverage check</h2>
	<p>firstPageSize=#arguments.firstPageSize# maxEntries=#arguments.maxEntries# showPages=#arguments.showPages# showBlogPosts=#arguments.showBlogPosts#<cfif len(arguments.byCat)> byCat=#arguments.byCat#</cfif><cfif len(arguments.byTag)> byTag=#arguments.byTag#</cfif></p>
	<p>Unpaginated total: <strong>#arrayLen(fullIds)#</strong>. Walked and collected: <strong>#arrayLen(seenIds)#</strong> unique post(s) across #(pageNum - 1)# page(s).</p>
	<cfif arrayLen(duplicates) eq 0 and arrayLen(missing) eq 0 and arrayLen(extra) eq 0>
		<p style="color:green;font-weight:bold;">OK - every post appears exactly once. Nothing missing, nothing duplicated.</p>
	<cfelse>
		<p style="color:red;font-weight:bold;">PROBLEM FOUND</p>
		<cfif arrayLen(duplicates)><p>Shown on more than one page (PostId): #arrayToList(duplicates, ", ")#</p></cfif>
		<cfif arrayLen(missing)><p>Never shown on any page (PostId): #arrayToList(missing, ", ")#</p></cfif>
		<cfif arrayLen(extra)><p>Shown by the walk but not in the unpaginated set - should not be possible, investigate the filter itself (PostId): #arrayToList(extra, ", ")#</p></cfif>
	</cfif>
	<p>Page log:<br>#arrayToList(pageLog, "<br>")#</p>
	</cfoutput>
	</cfsavecontent>
	<cfreturn reportHtml>
</cffunction>

<!---
	*************************************************************************************************************
	findReplaceThemeSettingPaths

	Generalized version of the one-off fix used 2026-09-25 to correct a batch of ThemeSetting rows that stored
	"/images/background/gregoryAlexander/..." (wrong case) instead of the real on-disk
	"/images/background/gregoryalexander/...". Useful again any time an image gets renamed/moved and a batch
	of ThemeSetting string fields need updating to match (a folder rename, a re-cased filename, a logo swap
	applied across many themes, etc).

	Defaults to a dry run - it only reports what WOULD change. Pass confirm=true to actually persist.
	Only touches the image/path-ish string fields listed below, not every ThemeSetting property, so it can't
	accidentally mangle unrelated text fields like CustomHeaderHtml.
	*************************************************************************************************************
--->
<cffunction name="findReplaceThemeSettingPaths" access="remote" returntype="void" output="yes"
		hint="Dry-run-by-default find/replace across ThemeSetting path fields (BlogBackgroundImage, HeaderBackgroundImage, etc).">
	<cfargument name="find" type="string" required="true" hint="The exact substring to look for, e.g. 'gregoryAlexander/'.">
	<cfargument name="replace" type="string" required="true" hint="What to replace it with, e.g. 'gregoryalexander/'.">
	<cfargument name="confirm" type="boolean" required="false" default="false" hint="true actually applies + ormFlush(); false just reports what would change.">
	<cfargument name="theme" type="string" required="false" default="" hint="Limit to a single theme alias.">
	<cfargument name="fields" type="string" required="false" default="" hint="Comma list of ThemeSetting fields to check; empty = the default image/path field set.">

	<cfset requireEditSiteAccess()>
	<cfsetting requesttimeout="120">

	<cfset var allStringFields = ["BlogBackgroundImage","BlogBackgroundImageMobile","HeaderBackgroundImage","HeaderBodyDividerImage",
		"MenuBackgroundImage","LogoImageMobile","LogoImage","DefaultLogoImageForSocialMediaShare","FooterImage"]>
	<cfset var stringFields = len(arguments.fields) ? listToArray(arguments.fields) : allStringFields>
	<cfset var themes = entityLoad("Theme")>
	<cfset var changes = []>
	<cfset var t = "">
	<cfset var ts = "">
	<cfset var fn = "">
	<cfset var getter = "">
	<cfset var setter = "">
	<cfset var val = "">
	<cfset var newVal = "">
	<cfset var c = "">

	<cfloop array="#themes#" index="t">
		<cfif len(arguments.theme) and compareNoCase(t.getThemeAlias(), arguments.theme) neq 0>
			<cfcontinue>
		</cfif>
		<cfset ts = t.getThemeSettingRef()>
		<cfloop array="#stringFields#" index="fn">
			<cfset getter = "get" & fn>
			<cfset setter = "set" & fn>
			<cfset val = "">
			<cftry>
				<cfset val = evaluate("ts.#getter#()")>
				<cfcatch type="any">
					<cfcontinue>
				</cfcatch>
			</cftry>
			<cfif len(val) and find(arguments.find, val)>
				<cfset newVal = replace(val, arguments.find, arguments.replace, "all")>
				<cfset arrayAppend(changes, {"theme": t.getThemeAlias(), "field": fn, "before": val, "after": newVal})>
				<cfif arguments.confirm>
					<cfset evaluate("ts.#setter#(newVal)")>
				</cfif>
			</cfif>
		</cfloop>
	</cfloop>
	<cfif arguments.confirm and arrayLen(changes)>
		<cfset ormFlush()>
	</cfif>

	<cfoutput>
	<h2>#(arguments.confirm ? "Applied" : "Dry run (add confirm=true to apply)")#</h2>
	<p>find: <code>#arguments.find#</code> &rarr; replace: <code>#arguments.replace#</code></p>
	</cfoutput>
	<table border="1" cellpadding="4" cellspacing="0">
	<tr><th>Theme</th><th>Field</th><th>Before</th><th>After</th></tr>
	<cfloop array="#changes#" index="c">
		<tr>
			<cfoutput>
			<td>#c.theme#</td>
			<td>#c.field#</td>
			<td>#c.before#</td>
			<td>#c.after#</td>
			</cfoutput>
		</tr>
	</cfloop>
	</table>
	<cfoutput><p><strong>#arrayLen(changes)#</strong> field(s) #(arguments.confirm ? "changed." : "would change.")#</p></cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	checkAndFixMissingBlogRef

	Checks the login-critical entities (Users, Role) for a NULL BlogRef and, on confirm, points them at the
	current application.BlogDbObj. Found live 2026-09-25 on Lucee's dev database: Users row 1 (the only real
	admin account) and Role row 1 ("Administrator") both had BlogRef = NULL, most likely from however row 1 of
	each table got seeded when Lucee's separate database was first created/copied - every other row was fine
	(BlogRef=1).

	Why this breaks the admin icon menu specifically: getUserBlogRoles() and getCapabilitiesByRole() (both in
	org/camden/blog/blog.cfc) filter their HQL joins with "AND User.BlogRef = application.BlogDbObj.getBlogId()"
	/ "AND Role.BlogRef = ...". A NULL BlogRef isn't an ORM crash - it's just silently excluded by that WHERE
	clause, so the query returns zero rows with no error. session.roles and session.capabilityList end up ""
	after login, every capability-gated <cfif> in includes/templates/admin/index.cfm evaluates false, and only
	the three icons that aren't capability-gated (User Profile, Refresh Site, Reload ORM Objects) render.
	Anyone who already has an open session from before the fix needs to log out and back in - session vars
	were cached at login time and won't self-correct until then.

	Other entities also carry a BlogRef (Category, Post, Theme, Page, PageCollection, etc. - any *.cfc under
	common/cfc/db/galaxieDb/ with a BlogRef property) and could in principle hit the same NULL seeding gap;
	Users/Role are checked here because they're what actually broke. Add more entity names to entityCheckList
	below if this class of bug turns up somewhere else.

	Defaults to a dry run. Pass confirm=true to actually persist (calls ormFlush()).
	*************************************************************************************************************
--->
<cffunction name="checkAndFixMissingBlogRef" access="remote" returntype="void" output="yes"
		hint="Checks Users/Role for a NULL BlogRef (the cause of the 'admin toolbar shows only 3 icons' bug) and optionally fixes it.">
	<cfargument name="confirm" type="boolean" required="false" default="false" hint="true actually applies + ormFlush(); false just reports what was found.">

	<cfset requireEditSiteAccess()>
	<cfsetting requesttimeout="60">

	<cfset var entityCheckList = ["Users","Role"]>
	<cfset var blogObj = application.BlogDbObj>
	<cfset var fixed = []>
	<cfset var entityName = "">
	<cfset var rows = "">
	<cfset var row = "">
	<cfset var label = "">
	<cfset var f = "">

	<cfloop array="#entityCheckList#" index="entityName">
		<cfset rows = entityLoad(entityName)>
		<cfloop array="#rows#" index="row">
			<cfif isNull(row.getBlogRef())>
				<cftry>
					<cfset label = entityName & ".getUserId() = " & row.getUserId()>
					<cfcatch type="any">
						<cftry>
							<cfset label = entityName & ".getRoleId() = " & row.getRoleId()>
							<cfcatch type="any">
								<cfset label = entityName & " (id lookup failed)">
							</cfcatch>
						</cftry>
					</cfcatch>
				</cftry>
				<cfif arguments.confirm>
					<cfset row.setBlogRef(blogObj)>
				</cfif>
				<cfset arrayAppend(fixed, label)>
			</cfif>
		</cfloop>
	</cfloop>
	<cfif arguments.confirm and arrayLen(fixed)>
		<cfset ormFlush()>
	</cfif>

	<cfoutput>
	<h2>#(arguments.confirm ? "Fixed" : "Dry run (add confirm=true to apply)")#</h2>
	<p>Checked: #arrayToList(entityCheckList)#</p>
	</cfoutput>
	<ul>
	<cfloop array="#fixed#" index="f">
		<li><cfoutput>#f#</cfoutput></li>
	</cfloop>
	</ul>
	<cfoutput><p><strong>#arrayLen(fixed)#</strong> row(s) with a NULL BlogRef #(arguments.confirm ? "fixed." : "found.")#</p></cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	importPostsFromRss

	Fetches a live Galaxie Blog RSS feed and imports each item as a real post on THIS installation - built to
	pull test content from https://www.gregoryalexander.com/blog/rss.cfm into a dev/test copy, but the feed URL
	is an argument so it works against any Galaxie Blog RSS feed.

	Only imports posts. Comments are never part of an RSS feed, so there's nothing to skip there. Pages and
	Page Collections aren't part of the RSS 2.0 format either (rss.cfm only ever emits <item> per post) - if
	this blog engine ever exposes a pages/collections feed, extend this method with a second fetch+loop
	following the same pattern rather than reworking the post loop below.

	Idempotent: skips any feed item whose title already exists as a Post on this blog, so it's safe to run
	repeatedly (e.g. to pick up newly-published posts) without creating duplicates. A live feed like this
	typically only carries the most recent N items, not the full history - re-running later will only ever
	pick up whatever's currently in the feed, not older posts that have since rolled off it.

	Defaults to a dry run (fetches and parses the feed, shows what would be imported/skipped, changes nothing).
	Pass confirm=true to actually create the posts.
	*************************************************************************************************************
--->
<cffunction name="importPostsFromRss" access="remote" returntype="void" output="yes"
		hint="Imports posts from a Galaxie Blog RSS feed, idempotent by title, dry-run by default.">
	<cfargument name="feedUrl" type="string" required="false" default="https://www.gregoryalexander.com/blog/rss.cfm">
	<cfargument name="confirm" type="boolean" required="false" default="false">

	<cfset requireEditSiteAccess()>
	<cfsetting requesttimeout="300">
	<cfobject component="#application.jsoupComponentPath#" name="JSoupUtil">
	<cfobject component="#application.imageComponentPath#" name="ImageObj">

	<cfset var feedHttp = "">
	<cfset var feedXml = "">
	<cfset var itemNodes = "">
	<cfset var itemNode = "">
	<cfset var catNode = "">
	<cfset var categories = "">
	<cfset var enclosureUrl = "">
	<cfset var encNodes = "">
	<cfset var items = []>
	<cfset var oneItem = "">
	<cfset var resultsLog = []>
	<cfset var existingCheck = "">
	<cfset var categoryIdList = "">
	<cfset var oneCategoryName = "">
	<cfset var oneCategoryId = "">
	<cfset var postBody = "">
	<cfset var liveDoc = "">
	<cfset var contentEls = "">
	<cfset var cleanPubDate = "">
	<cfset var postDateTime = "">
	<cfset var newPostId = "">
	<cfset var newMediaId = "">
	<cfset var enclosureImageUrl = "">
	<cfset var ogEls = "">
	<cfset var ogImagePath = "">
	<cfset var imageFileName = "">
	<cfset var localEnclosurePath = "">
	<cfset var thumbnailUrl = "">
	<cfset var oneLine = "">

	<!--- Fetch and parse the feed --->
	<cfhttp method="get" url="#arguments.feedUrl#" result="feedHttp" throwonerror="true" timeout="30" />
	<cfset feedXml = xmlParse(feedHttp.fileContent)>
	<cfset itemNodes = xmlSearch(feedXml, "//item")>

	<cfloop array="#itemNodes#" index="itemNode">
		<cfset categories = []>
		<cfloop array="#xmlSearch(itemNode, 'category')#" index="catNode">
			<cfset arrayAppend(categories, trim(catNode.xmlText))>
		</cfloop>
		<cfset enclosureUrl = "">
		<cfset encNodes = xmlSearch(itemNode, "enclosure")>
		<cfif arrayLen(encNodes) and structKeyExists(encNodes[1].xmlAttributes, "url")>
			<cfset enclosureUrl = encNodes[1].xmlAttributes.url>
		</cfif>
		<cfset arrayAppend(items, {
			title: trim(xmlSearch(itemNode, "title")[1].xmlText),
			link: trim(xmlSearch(itemNode, "link")[1].xmlText),
			description: trim(xmlSearch(itemNode, "description")[1].xmlText),
			categories: categories,
			pubDateRaw: trim(xmlSearch(itemNode, "pubDate")[1].xmlText),
			enclosureUrl: enclosureUrl
		})>
	</cfloop>

	<cfloop array="#items#" index="oneItem">
		<cftry>
			<!--- Skip if a post with this exact title already exists - keeps repeat runs safe. --->
			<cfquery name="existingCheck" dbtype="hql">
				SELECT new Map(Post.PostId as PostId)
				FROM Post as Post
				WHERE Post.Title = <cfqueryparam value="#oneItem.title#">
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
			</cfquery>
			<cfif arrayLen(existingCheck)>
				<!--- HQL "new Map(...)" results are real java.util.HashMaps - case-sensitive, so bracket
				notation with the exact alias casing is required here (dot notation looks for "POSTID" and
				fails). --->
				<cfset arrayAppend(resultsLog, "SKIP (already exists, PostId=#existingCheck[1]['PostId']#): #oneItem.title#")>
			<cfelseif not arguments.confirm>
				<cfset arrayAppend(resultsLog, "WOULD IMPORT: #oneItem.title# (categories: #arrayToList(oneItem.categories)#)")>
			<cfelse>
				<!--- Find-or-create each category, collect the resulting ids --->
				<cfset categoryIdList = "">
				<cfloop array="#oneItem.categories#" index="oneCategoryName">
					<cfset oneCategoryId = application.blog.saveCategory(category=oneCategoryName)>
					<cfset categoryIdList = listAppend(categoryIdList, oneCategoryId)>
				</cfloop>

				<!--- Fetch the live post and pull out just its real content (not the whole page - header/sidebar/footer
				aren't part of the post itself). --->
				<cfset postBody = oneItem.description>
				<cftry>
					<cfset liveDoc = JSoupUtil.loadSiteByUrl(oneItem.link)>
					<cfset contentEls = liveDoc.select(".postContent")>
					<cfif contentEls.size() gt 0>
						<cfset postBody = contentEls.get(0).html()>
					</cfif>
					<cfcatch type="any">
						<!--- Fall back to the RSS description if the live fetch fails for any reason. --->
					</cfcatch>
				</cftry>

				<!--- RSS pubDate is RFC822, e.g. "Fri, 25 Sep 2026 10:39:01 -0700" - strip the weekday prefix and
				the trailing numeric timezone offset so parseDateTime() can read it. --->
				<cfset cleanPubDate = reReplace(oneItem.pubDateRaw, "^[A-Za-z]{3},\s*", "")>
				<cfset cleanPubDate = reReplace(cleanPubDate, "\s[+-]\d{4}$", "")>
				<cfset cleanPubDate = reReplace(cleanPubDate, "\s(GMT|UTC)$", "")>
				<cfset postDateTime = parseDateTime(cleanPubDate)>

				<cfset newPostId = application.blog.insertNewPost(
					postType = "blogPost",
					author = 1,
					title = oneItem.title,
					description = oneItem.description,
					datePosted = dateFormat(postDateTime, "mm/dd/yyyy"),
					timePosted = timeFormat(postDateTime, "HH:mm:ss")
				)>

				<!--- Handle the enclosure image. If the RSS item didn't carry one, fall back to the live post's
				og:image meta tag (RSS <enclosure> is often left blank even when the post itself has a hero image). --->
				<cfset newMediaId = "">
				<cfset enclosureImageUrl = oneItem.enclosureUrl>
				<cfif not len(enclosureImageUrl) and isDefined("liveDoc")>
					<cftry>
						<cfset ogEls = liveDoc.select("meta[property=og:image]")>
						<cfif ogEls.size() gt 0>
							<cfset ogImagePath = ogEls.get(0).attr("content")>
							<cfset enclosureImageUrl = (left(ogImagePath, 4) eq "http") ? ogImagePath : ("https://www.gregoryalexander.com" & ogImagePath)>
						</cfif>
						<cfcatch type="any">
							<!--- No og:image available either - proceed without an enclosure for this post. --->
						</cfcatch>
					</cftry>
				</cfif>

				<cfif len(enclosureImageUrl)>
					<cfset imageFileName = listLast(enclosureImageUrl, "/")>
					<cfset localEnclosurePath = expandPath(application.baseUrl & "/enclosures/" & imageFileName)>
					<cfset thumbnailUrl = "">
					<cftry>
						<cfhttp method="get" url="#enclosureImageUrl#" path="#expandPath(application.baseUrl & '/enclosures/')#" file="#imageFileName#" throwonerror="true" timeout="30" />
						<!--- Generate the real card/thumbnail image (235x138) - without this, widgets that read
						MediaThumbnailUrl (e.g. the Popular Blogs carousel) show a generic placeholder icon instead
						of the post's photo. --->
						<cftry>
							<cfset ImageObj.createThumbnail(imagePath=localEnclosurePath, imageName=imageFileName)>
							<cfset thumbnailUrl = application.baseUrl & "/enclosures/thumbnails/" & imageFileName>
							<cfcatch type="any">
								<!--- Thumbnail generation failed - proceed with the full-size enclosure only. --->
							</cfcatch>
						</cftry>
						<cfset newMediaId = application.blog.insertMediaRecord(
							mediaPath = localEnclosurePath,
							mediaUrl = application.baseUrl & "/enclosures/" & imageFileName,
							mediaThumbnailUrl = thumbnailUrl,
							mediaType = "image",
							enclosure = true,
							postId = newPostId
						)>
						<cfcatch type="any">
							<!--- Couldn't download this particular image - proceed without one for this post. --->
						</cfcatch>
					</cftry>
				</cfif>

				<!--- Now save the rest: full body, categories, and the mediaId if one was set up above.
				datePosted/timePosted must be passed again here too - savePost() defaults to blogNow() when
				they're omitted, which would silently overwrite the real historical date insertNewPost() just set. --->
				<cfset application.blog.savePost(
					postId = newPostId,
					author = 1,
					title = oneItem.title,
					description = oneItem.description,
					post = postBody,
					postCategories = categoryIdList,
					mediaId = newMediaId,
					datePosted = dateFormat(postDateTime, "mm/dd/yyyy"),
					timePosted = timeFormat(postDateTime, "HH:mm:ss"),
					released = true,
					emailSubscriber = false
				)>

				<cfset arrayAppend(resultsLog, "IMPORTED: [#newPostId#] #oneItem.title# (categories: #categoryIdList#, media: #newMediaId#)")>
			</cfif>

			<cfcatch type="any">
				<cfset arrayAppend(resultsLog, "FAILED: #oneItem.title# -- #cfcatch.message#")>
			</cfcatch>
		</cftry>
	</cfloop>

	<cfoutput>
	<h3>Import results #(arguments.confirm ? "" : "(dry run - add confirm=true to actually import)")#</h3>
	<p>Feed: #arguments.feedUrl# (#arrayLen(items)# item(s) found)</p>
	<p>Pages / Page Collections: not part of the RSS format - 0 found, nothing to do.</p>
	</cfoutput>
	<cfloop array="#resultsLog#" index="oneLine">
		<cfoutput>#oneLine#</cfoutput><br>
	</cfloop>
	<hr>
	<cfoutput>Total blog post count now: #application.blog.getBlogPostCount()#</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	importDocsContent

	Creates or updates the galaxieblog.org docs Page Collections, their pages, and the homepage order, from
	common/data/docsContent.json (exported from the local Lucee copy). Matches by alias (collections) and by
	post alias (pages), so running it again updates the same rows instead of making duplicates.
	Defaults to a dry run; pass confirm=true to apply.
	/common/cfc/TestUtility.cfc?method=importDocsContent            (dry run)
	/common/cfc/TestUtility.cfc?method=importDocsContent&confirm=true
	*************************************************************************************************************
--->
<cffunction name="importDocsContent" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<cfset var filePath = getDirectoryFromPath(getCurrentTemplatePath()) & "../data/docsContent.json">
	<cfif not fileExists(filePath)>
		<cfoutput>Missing #filePath#</cfoutput>
		<cfreturn>
	</cfif>
	<cfset var docs = deserializeJSON(fileRead(filePath))>
	<cfset var log = []>
	<cfset var aliasToId = {}>
	<cfset var col = "">
	<cfset var page = "">
	<cfset var existing = "">
	<cfset var existingPost = "">
	<cfset var postId = 0>
	<cfset var pcObj = "">
	<cfset var newId = 0>
	<cfset var ids = []>
	<cfset var cur = "">

	<!--- Collections --->
	<cfloop array="#application.blog.getAllPageCollections()#" index="existing">
		<cfif len(existing["collectionAlias"])>
			<cfset aliasToId[existing["collectionAlias"]] = existing["pageCollectionId"]>
		</cfif>
	</cfloop>
	<cfloop array="#docs.collections#" index="col">
		<cfif structKeyExists(aliasToId, col.alias)>
			<cfset arrayAppend(log, "collection exists: " & col.alias)>
		<cfelse>
			<cfset arrayAppend(log, "create collection: " & col.alias)>
			<cfif arguments.confirm>
				<cfset newId = application.blog.savePageCollection(title = col.title, description = col.description)>
				<cfset pcObj = entityLoadByPK("PageCollection", newId)>
				<cfset pcObj.setCollectionAlias(col.alias)>
				<cfset entitySave(pcObj)>
				<cfset ormFlush()>
				<cfset aliasToId[col.alias] = newId>
			</cfif>
		</cfif>

		<!--- Pages in this collection --->
		<cfloop array="#col.pages#" index="page">
			<!--- ormExecuteQuery returns an array, so a missing post is an empty array rather than a null entity (which Lucee reads as an undefined variable). --->
			<cfset existingPostList = ormExecuteQuery("FROM Post WHERE PostAlias = :alias", { alias = page.postAlias })>
			<cfif arrayLen(existingPostList)>
				<cfset postId = existingPostList[1].getPostId()>
				<cfset arrayAppend(log, "update page: " & page.title)>
			<cfelse>
				<cfset postId = 0>
				<cfset arrayAppend(log, "create page: " & page.title)>
			</cfif>
			<cfif arguments.confirm and structKeyExists(aliasToId, col.alias)>
				<cfif postId eq 0>
					<!--- insertNewPost returns the id of any existing post with the same title, which would overwrite a live blog post (this happened with "Promoting a Post"). Create under the unique docs alias instead; savePost below sets the real title. --->
					<cfset postId = application.blog.insertNewPost(postType = "page", author = 1, title = page.postAlias, description = page.description)>
					<!--- insertNewPost builds the alias from the title. Set the docs alias (docs- prefixed) so it can't collide with an existing post that has the same title-based alias. --->
					<cfset newPostObj = entityLoadByPK("Post", postId)>
					<cfset newPostObj.setPostAlias(page.postAlias)>
					<cfset entitySave(newPostObj)>
					<cfset ormFlush()>
				</cfif>
				<cfset application.blog.savePost(
					postId = postId,
					author = 1,
					postType = "page",
					title = page.title,
					description = page.description,
					post = page.body,
					released = (arrayLen(existingPostList) ? existingPostList[1].getReleased() : false),
					emailSubscriber = false,
					pageCollectionIdList = aliasToId[col.alias]
				)>
				<cfset application.blog.setPageCollectionsForPost(postId = postId, pageCollectionIdList = aliasToId[col.alias])>
			</cfif>
		</cfloop>
	</cfloop>

	<!--- Homepage order --->
	<cfloop array="#docs.homepageCollectionAliases#" index="col">
		<cfif structKeyExists(aliasToId, col)>
			<cfset arrayAppend(ids, aliasToId[col])>
		</cfif>
	</cfloop>
	<cfset cur = application.blog.getHomepageSettings()>
	<cfset arrayAppend(log, "homepage collections: " & arrayToList(ids))>
	<cfif arguments.confirm>
		<cfset application.blog.saveHomepageSettings(
			showPages = cur.showPages,
			pageIdList = cur.pageIdList,
			showCollections = docs.homepageShowCollections,
			collectionIdList = arrayToList(ids),
			showBlogPosts = cur.showBlogPosts
		)>
	</cfif>

	<cfoutput>
	<h2>#(arguments.confirm ? "Applied" : "Dry run (add confirm=true to apply)")#</h2>
	<cfloop array="#log#" index="line"><div>#line#</div></cfloop>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	applyPostCleanup

	Redirects, deletes, or holds the posts listed in common/data/postCleanup.json, a JSON array keyed by postAlias:
	{ "postAlias": "old-alias", "action": "redirect", "targetAlias": "new-docs-alias" }
	{ "postAlias": "old-alias", "action": "delete" }
	{ "postAlias": "old-alias", "action": "hold" }
	A redirect removes the post and points its URL (301) at the target post's own link. A delete permanently
	removes the post, using the same path as the editor's "delete it" link. A hold changes nothing. Defaults to
	a dry run; pass confirm=true to apply.
	*************************************************************************************************************
--->
<cffunction name="applyPostCleanup" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<cfset var filePath = getDirectoryFromPath(getCurrentTemplatePath()) & "../data/postCleanup.json">
	<cfif not fileExists(filePath)>
		<cfoutput>Missing #filePath#</cfoutput>
		<cfreturn>
	</cfif>
	<cfset var items = deserializeJSON(fileRead(filePath))>
	<cfset var log = []>
	<cfset var item = "">
	<cfset var postObj = "">
	<cfset var targetObj = "">
	<cfset var targetUrl = "">
	<cfloop array="#items#" index="item">
		<cfset postList = ormExecuteQuery("FROM Post WHERE PostAlias = :alias", { alias = item.postAlias })>
		<cfif not arrayLen(postList)>
			<cfset arrayAppend(log, "not found, skipped: " & item.postAlias)>
			<cfcontinue>
		</cfif>
		<!--- Copy the values we need into plain variables, then clear the ORM session. Otherwise the entity loaded above stays managed, and deletePost changes the same row through its own copy, so the later flush tries to update a deleted row (OptimisticLockException). --->
		<cfset thisPostId = postList[1].getPostId()>
		<cfset thisTitle = postList[1].getTitle()>
		<cfset thisDescription = postList[1].getDescription()>
		<cfset thisBody = postList[1].getBody()>
		<cfset thisAuthorId = postList[1].getUserRef().getUserId()>
		<cfset thisIsPage = postList[1].getIsPage()>
		<cfset ormClearSession()>
		<cfif item.action eq "redirect">
			<cfset targetList = ormExecuteQuery("FROM Post WHERE PostAlias = :alias", { alias = item.targetAlias })>
			<cfif not arrayLen(targetList)>
				<cfset arrayAppend(log, "target not found, skipped: " & thisTitle & " -> " & item.targetAlias)>
				<cfcontinue>
			</cfif>
			<cfset targetUrl = application.blog.makeLink(postId = targetList[1].getPostId())>
			<cfset ormClearSession()>
			<cfset arrayAppend(log, "redirect: " & thisTitle & " -> " & targetUrl)>
			<cfif arguments.confirm>
				<cfset application.blog.savePost(
					postId = thisPostId,
					author = thisAuthorId,
					postType = (thisIsPage ? "page" : "blogPost"),
					title = thisTitle,
					description = thisDescription,
					post = thisBody,
					released = true,
					emailSubscriber = false,
					remove = true,
					redirectUrl = targetUrl,
					redirectType = "301"
				)>
			</cfif>
		<cfelseif item.action eq "delete">
			<cfset arrayAppend(log, "delete: " & thisTitle)>
			<cfif arguments.confirm>
				<cfset application.blog.deletePost(thisPostId)>
				<!--- deletePost loads the post again and leaves that copy dirty in the session. Clear it here, or the next lookup flushes the change to a deleted row. --->
				<cfset ormClearSession()>
			</cfif>
		<cfelse>
			<cfset arrayAppend(log, "hold, no change: " & thisTitle)>
		</cfif>
	</cfloop>

	<cfoutput>
	<h2>#(arguments.confirm ? "Applied" : "Dry run (add confirm=true to apply)")#</h2>
	<cfloop array="#log#" index="line"><div>#line#</div></cfloop>
	</cfoutput>
</cffunction>
	<!--- Sets the order of the docs collections in the Docs menu. Run once after the docs import. Lower numbers appear first. Only collections that exist are changed. --->
	<cffunction name="setDocsMenuOrder" access="remote" returntype="void" output="yes">
		<cfargument name="confirm" type="boolean" required="false" default="false">
		<cfset requireEditSiteAccess()>
		<cfset var readingOrder = ["docs-releases-and-upgrades","docs-install-and-admin","docs-homepage-and-page-collections","docs-themes-and-grids","docs-media-maps-and-animated-heroes","docs-writing-and-editing-posts","docs-visitors-and-safety","docs-credits-and-licenses"]>
		<cfloop from="1" to="#arrayLen(readingOrder)#" index="i">
			<cfset var alias = readingOrder[i]>
			<cfset var found = ormExecuteQuery("FROM PageCollection WHERE CollectionAlias = :alias", { alias = alias })>
			<cfif arrayLen(found)>
				<cfoutput>#alias# -> #i * 10#<br></cfoutput>
				<cfif arguments.confirm>
					<cfset found[1].setMenuOrder(i * 10)>
					<cfset entitySave(found[1])>
				</cfif>
			<cfelse>
				<cfoutput>#alias# not found<br></cfoutput>
			</cfif>
		</cfloop>
		<cfif arguments.confirm><cfset ormFlush()><cfoutput>Saved.</cfoutput></cfif>
	</cffunction>

<!---
	*************************************************************************************************************
	fixDocsLinks

	The docs pages' "See Also" (and other) links were written with "docs-" addresses (eg. /docs-image-optimization-
	and-webp), but on galaxieblog.org some pages were saved without that prefix (eg. /media-and-maps-start-to-finish),
	so those links fall through to the blog listing or "No Entries". This checks every "docs-..." link in every
	post/page body (absolute, root-relative, or /index.cfm/ form) and:
	- leaves it alone when it already works: a Page Collection alias (collections really do use "docs-") or a
	  released, non-removed page;
	- rewrites it to the plain alias when no live page has the "docs-" alias but a live page has the same alias
	  without "docs-";
	- only reports it when the "docs-" page exists but isn't released yet (it starts working once released), or
	  when nothing matches at all.
	Only the alias inside the link is changed - the rest of the URL (domain, /index.cfm/) is kept. Defaults to a
	dry run; pass confirm=true to save. Clears the page caches after saving.
	e.g.  /common/cfc/TestUtility.cfc?method=fixDocsLinks
	      /common/cfc/TestUtility.cfc?method=fixDocsLinks&confirm=true
	*************************************************************************************************************
--->
<cffunction name="fixDocsLinks" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<!--- Send this as an HTML page. On Lucee a remote method's output can otherwise go out as XML, where a bare & (or
	any other non-XML character) stops the browser rendering it ("EntityRef: expecting ';'"). --->
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<cfset var livePages = {}>
	<cfset var draftPages = {}>
	<cfset var collections = {}>
	<cfset var row = "">
	<cfset var posts = []>
	<cfset var post = "">
	<cfset var body = "">
	<cfset var newBody = "">
	<cfset var hrefs = []>
	<cfset var href = "">
	<cfset var docsAlias = "">
	<cfset var plainAlias = "">
	<cfset var newHref = "">
	<cfset var changes = []>
	<cfset var report = []>
	<cfset var postsChanged = 0>
	<cfset var linksFixed = 0>

	<!--- The database does the bit comparisons and hands back plain 1/0 integers, so the result reads the same on any
	engine/driver (MySQL or SQL Server, Lucee or Adobe ColdFusion). --->
	<cfset var aliasRows = queryExecute("SELECT PostAlias, Title, CASE WHEN Released = 1 THEN 1 ELSE 0 END AS Released, CASE WHEN Remove = 1 THEN 1 ELSE 0 END AS Remove FROM Post WHERE BlogRef = :blogId", { blogId = blogId })>
	<!--- Live aliases keyed by title, and the original docs- addresses keyed to their titles (from the docs import file),
	for pages whose new address isn't just the old one without docs- (2026-10-09): eg. /docs-an-installer-that-updates-itself
	is "Updating Galaxie Blog", now at /updating-galaxie-blog. --->
	<cfset var liveAliasByTitle = {}>
	<cfset var docsTitleByAlias = {}>
	<cfset var docsContentPath = expandPath(application.baseUrl & "/common/data/docsContent.json")>
	<cfset var docsContentData = "">
	<cfset var docsCollection = "">
	<cfset var docsPage = "">
	<cfif fileExists(docsContentPath)>
		<cftry>
			<cfset docsContentData = deserializeJson(fileRead(docsContentPath, "utf-8"))>
			<cfloop array="#docsContentData.COLLECTIONS#" item="docsCollection">
				<cfloop array="#docsCollection.PAGES#" item="docsPage">
					<cfset docsTitleByAlias[lCase(docsPage.POSTALIAS)] = lCase(trim(docsPage.TITLE))>
				</cfloop>
			</cfloop>
			<cfcatch type="any"><!--- No import file, or an older format - fall back to the alias matching below. ---></cfcatch>
		</cftry>
	</cfif>
	<cfset var collectionRows = queryExecute("SELECT CollectionAlias FROM PageCollection WHERE BlogRef = :blogId", { blogId = blogId })>

	<!--- Every post/page alias, split into live (released, not removed) and not-yet-live. Released/Remove are bit
	columns: Adobe ColdFusion returns them as 1/0, but Lucee with MySQL returns true/false - and val("true") is 0,
	which made every page look unreleased on galaxieblog.org. bitIsTrue() handles both. --->
	<cfloop query="aliasRows">
		<cfif len(aliasRows.PostAlias)>
			<cfif bitIsTrue(aliasRows.Released) and not bitIsTrue(aliasRows.Remove)>
				<cfset livePages[lCase(aliasRows.PostAlias)] = true>
				<cfset liveAliasByTitle[lCase(trim(aliasRows.Title))] = lCase(aliasRows.PostAlias)>
			<cfelseif not bitIsTrue(aliasRows.Remove)>
				<cfset draftPages[lCase(aliasRows.PostAlias)] = true>
			</cfif>
		</cfif>
	</cfloop>
	<cfloop query="collectionRows">
		<cfif len(collectionRows.CollectionAlias)><cfset collections[lCase(collectionRows.CollectionAlias)] = true></cfif>
	</cfloop>
	<!--- Live aliases keyed by their letters/digits only, for links whose alias differs just by hyphens - eg. a link to
	/docs-advanced-xml-post-directives-and-json-ld when the editor rebuilt the page's alias from its title as
	advanced-xml-post-directives-and-jsonld ("JSON-LD" loses its hyphen). --->
	<cfset var livePagesByLetters = {}>
	<cfloop collection="#livePages#" item="row">
		<cfset livePagesByLetters[reReplace(row, "[^a-z0-9]", "", "all")] = row>
	</cfloop>
	<cfset var lettersOnly = "">
	<cfset var targetAlias = "">

	<cfset posts = ormExecuteQuery("FROM Post WHERE BlogRef = :blogId AND Remove = 0 AND Body LIKE :pattern", { blogId = application.BlogDbObj, pattern = "%docs-%" })>
	<cfloop array="#posts#" index="post">
		<cfset body = post.getBody()>
		<cfif isNull(body) or not len(body)><cfcontinue></cfif>
		<cfset newBody = body>
		<cfset changes = []>
		<!--- href="..." or href='...' whose last path segment starts with docs- (optionally with #anchor). --->
		<cfset hrefs = reMatchNoCase("href=[""'][^""']*/docs-[a-z0-9-]+(##[^""']*)?[""']", body)>
		<cfloop array="#hrefs#" index="href">
			<cfset docsAlias = lCase(reReplaceNoCase(href, "^.*/(docs-[a-z0-9-]+)(##[^""']*)?[""']$", "\1"))>
			<cfset plainAlias = mid(docsAlias, 6, len(docsAlias))>
			<cfset lettersOnly = reReplace(plainAlias, "[^a-z0-9]", "", "all")>
			<cfset targetAlias = "">
			<cfif structKeyExists(collections, docsAlias) or structKeyExists(livePages, docsAlias)>
				<cfcontinue>
			<cfelseif structKeyExists(livePages, plainAlias)>
				<cfset targetAlias = plainAlias>
			<cfelseif structKeyExists(livePagesByLetters, lettersOnly)>
				<cfset targetAlias = livePagesByLetters[lettersOnly]>
			<cfelseif structKeyExists(docsTitleByAlias, docsAlias) and structKeyExists(liveAliasByTitle, docsTitleByAlias[docsAlias])>
				<!--- Renamed page: follow it by its title. --->
				<cfset targetAlias = liveAliasByTitle[docsTitleByAlias[docsAlias]]>
			</cfif>
			<cfif len(targetAlias)>
				<cfset newHref = reReplaceNoCase(href, "/" & docsAlias & "(##[^""']*)?([""'])$", "/" & targetAlias & "\1\2")>
				<!--- The same link can appear more than once in a body - replace every copy, list it once. --->
				<cfif newHref neq href and find(href, newBody)>
					<cfset newBody = replace(newBody, href, newHref, "all")>
					<cfset arrayAppend(changes, "/" & docsAlias & " -> /" & targetAlias)>
				</cfif>
			<cfelseif structKeyExists(draftPages, docsAlias)>
				<!--- Saving a page that isn't released yet rebuilds its alias from the title (postDetail.cfm's
				changeTitleAndLink), which drops the docs- prefix - so this link will break when the page is released. --->
				<cfset arrayAppend(report, post.getTitle() & ": /" & docsAlias & " - page not released yet. Releasing it will drop the docs- from its address, so run this tool again afterwards")>
			<cfelseif structKeyExists(draftPages, plainAlias)>
				<cfset arrayAppend(report, post.getTitle() & ": /" & docsAlias & " - page /" & plainAlias & " exists but is not released yet; release it, then run this again")>
			<cfelse>
				<cfset arrayAppend(report, post.getTitle() & ": /" & docsAlias & " - no page found with or without docs-")>
			</cfif>
		</cfloop>
		<cfif newBody neq body>
			<cfset postsChanged = postsChanged + 1>
			<cfset linksFixed = linksFixed + arrayLen(changes)>
			<cfoutput><div><strong>#encodeForHtml(post.getTitle())#</strong>: #encodeForHtml(arrayToList(changes, ", "))#</div></cfoutput>
			<cfif arguments.confirm>
				<cfset post.setBody(newBody)>
				<cfset entitySave(post)>
			</cfif>
		</cfif>
	</cfloop>

	<cfif arguments.confirm and postsChanged>
		<cfset ormFlush()>
		<cfset application.blog.flushGalaxieCache('all')>
	</cfif>
	<cfoutput>
	<h2>#(arguments.confirm ? "Saved" : "Dry run (add &amp;confirm=true to the address to save)")#: #linksFixed# link(s) to fix in #postsChanged# post(s)</h2>
	<cfif arrayLen(report)>
		<h3>Not changed - needs a look (#arrayLen(report)#)</h3>
		<cfloop array="#report#" index="row"><div>#encodeForHtml(row)#</div></cfloop>
	</cfif>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	fixContentOutputIdentity (2026-10-11) - SQL Server only. The ContentOutput table (saved content templates: the
	Composite Footer, a custom Navigation Menu, pods...) was originally created by hand (see ContentOutput.cfc), and on
	gregoryalexander.com its ContentOutputId column ended up without IDENTITY, so saving a content template for the first
	time failed with "Cannot insert the value NULL into column 'ContentOutputId'" (Hibernate's native generator leaves the
	id to the database). SQL Server can't add IDENTITY to an existing column, so this rebuilds the table:
	  - a new ContentOutput with an IDENTITY id, every row copied with its existing id, then swapped in;
	  - the foreign keys from ContentOutputTheme and to ContentTemplate dropped and recreated (WITH NOCHECK, so an old
	    orphan row can't stop it);
	  - the old table kept as ContentOutput_old_noidentity, as a backup (drop it yourself once you're happy);
	  - all in one transaction: any error rolls everything back.
	Dry run by default (reports whether the id is already IDENTITY, the row count and the foreign keys); add
	&confirm=true to rebuild. Does nothing if the column is already IDENTITY.
	Usage: /common/cfc/TestUtility.cfc?method=fixContentOutputIdentity  (then &confirm=true)
	*************************************************************************************************************
--->
<cffunction name="buildContentOutputIdentityFixSql" access="public" returntype="string" output="false"
		hint="The T-SQL batch fixContentOutputIdentity runs. Table names are parameters only so the batch can be tested against scratch copies; fixContentOutputIdentity always uses the real ones.">
	<cfargument name="tableName" type="string" required="false" default="ContentOutput">
	<cfargument name="childTableName" type="string" required="false" default="ContentOutputTheme">
	<cfargument name="templateTableName" type="string" required="false" default="ContentTemplate">
	<cfset var t = arguments.tableName>
	<cfset var c = arguments.childTableName>
	<cfset var p = arguments.templateTableName>
	<cfset var cols = "ContentOutputId, PageRef, ThemeRef, ContentOutput, ContentOutputMobile, Active, LastCached, [Date], ContentTemplateRef">
	<cfset var sqlText = "">
	<cfsavecontent variable="sqlText"><cfoutput>
SET XACT_ABORT ON;
BEGIN TRY
	BEGIN TRANSACTION;
	DECLARE @dropFks NVARCHAR(MAX) = N'';
	SELECT @dropFks = @dropFks + N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(parent_object_id)) + N' DROP CONSTRAINT ' + QUOTENAME(name) + N'; '
	FROM sys.foreign_keys WHERE referenced_object_id = OBJECT_ID(N'dbo.#t#') OR parent_object_id = OBJECT_ID(N'dbo.#t#');
	EXEC sp_executesql @dropFks;
	CREATE TABLE dbo.#t#_identityfix (
		ContentOutputId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
		PageRef INT NULL,
		ThemeRef INT NULL,
		ContentOutput VARCHAR(MAX) NULL,
		ContentOutputMobile VARCHAR(MAX) NULL,
		Active BIT NULL,
		LastCached DATE NULL,
		[Date] DATETIME2 NULL,
		ContentTemplateRef INT NULL
	);
	SET IDENTITY_INSERT dbo.#t#_identityfix ON;
	INSERT INTO dbo.#t#_identityfix (#cols#) SELECT #cols# FROM dbo.#t#;
	SET IDENTITY_INSERT dbo.#t#_identityfix OFF;
	EXEC sp_rename N'dbo.#t#', N'#t#_old_noidentity';
	EXEC sp_rename N'dbo.#t#_identityfix', N'#t#';
	IF OBJECT_ID(N'dbo.#c#') IS NOT NULL
		ALTER TABLE dbo.#c# WITH NOCHECK ADD CONSTRAINT FK_#c#_#t#Ref FOREIGN KEY (ContentOutputRef) REFERENCES dbo.#t#(ContentOutputId);
	IF OBJECT_ID(N'dbo.#p#') IS NOT NULL
		ALTER TABLE dbo.#t# WITH NOCHECK ADD CONSTRAINT FK_#t#_#p#Ref FOREIGN KEY (ContentTemplateRef) REFERENCES dbo.#p#(ContentTemplateId);
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	THROW;
END CATCH;
</cfoutput></cfsavecontent>
	<cfreturn sqlText>
</cffunction>

<cffunction name="fixContentOutputIdentity" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var status = "">
	<cfset var fks = "">
	<cfset var rowCount = "">
	<cftry>
		<cfset status = queryExecute("SELECT c.is_identity FROM sys.columns c WHERE c.object_id = OBJECT_ID(N'dbo.ContentOutput') AND c.name = 'ContentOutputId'", {}, { datasource: application.dsn })>
		<cfcatch type="any">
			<cfoutput><h2>Not run</h2><p>This tool only works on SQL Server (#encodeForHtml(cfcatch.message)#).</p></cfoutput>
			<cfreturn>
		</cfcatch>
	</cftry>
	<cfif not status.recordCount>
		<cfoutput><h2>Not run</h2><p>Couldn't find dbo.ContentOutput.ContentOutputId.</p></cfoutput>
		<cfreturn>
	</cfif>
	<cfset rowCount = queryExecute("SELECT COUNT(*) AS n FROM dbo.ContentOutput", {}, { datasource: application.dsn }).n>
	<cfset fks = queryExecute("SELECT name, OBJECT_NAME(parent_object_id) AS child, OBJECT_NAME(referenced_object_id) AS parent FROM sys.foreign_keys WHERE referenced_object_id = OBJECT_ID(N'dbo.ContentOutput') OR parent_object_id = OBJECT_ID(N'dbo.ContentOutput')", {}, { datasource: application.dsn })>
	<cfoutput>
	<h2>ContentOutput.ContentOutputId is <cfif status.is_identity>already</cfif><cfif not status.is_identity>NOT</cfif> IDENTITY - #rowCount# row(s)</h2>
	<p>Foreign keys: <cfloop query="fks">#encodeForHtml(fks.name)# (#encodeForHtml(fks.child)# -> #encodeForHtml(fks.parent)#); </cfloop><cfif not fks.recordCount>none</cfif></p>
	</cfoutput>
	<cfif status.is_identity>
		<cfoutput><p>Nothing to do.</p></cfoutput>
		<cfreturn>
	</cfif>
	<cfif not arguments.confirm>
		<cfoutput><p>Dry run (add &amp;confirm=true to the address to rebuild the table). The old table will be kept as ContentOutput_old_noidentity.</p></cfoutput>
		<cfreturn>
	</cfif>
	<cfset queryExecute(buildContentOutputIdentityFixSql(), {}, { datasource: application.dsn })>
	<cfset status = queryExecute("SELECT c.is_identity FROM sys.columns c WHERE c.object_id = OBJECT_ID(N'dbo.ContentOutput') AND c.name = 'ContentOutputId'", {}, { datasource: application.dsn })>
	<cfset var newCount = queryExecute("SELECT COUNT(*) AS n FROM dbo.ContentOutput", {}, { datasource: application.dsn }).n>
	<cfoutput><h2>Rebuilt: ContentOutputId is now <cfif not status.is_identity>STILL NOT</cfif> IDENTITY - #newCount# of #rowCount# row(s) copied</h2>
	<p>The old table is kept as ContentOutput_old_noidentity. Restart the ORM next (?reloadOrm=1 while logged in), then save the footer again.</p></cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	inspectContentOutput (2026-10-11) - read only. Shows why a saved content template (Composite Footer, Navigation Menu,
	a pod...) does or doesn't show on the site: the ContentTemplate row(s) with that name, whether each is linked to page 2
	in PageContentTemplate (getContentOutputByContentTemplate joins through it), every ContentOutput row for the template,
	and what getContentOutputData actually returns for desktop and mobile.
	Usage: /common/cfc/TestUtility.cfc?method=inspectContentOutput&contentTemplate=compositeFooter
	*************************************************************************************************************
--->
<cffunction name="inspectContentOutput" access="remote" returntype="void" output="yes">
	<cfargument name="contentTemplate" type="string" required="false" default="compositeFooter">
	<cfset requireEditSiteAccess()>
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var ds = { datasource: application.dsn }>
	<cfset var templates = queryExecute("SELECT ContentTemplateId, ContentTemplateName, Active FROM ContentTemplate WHERE ContentTemplateName = :n", { n: arguments.contentTemplate }, ds)>
	<cfset var links = queryExecute("SELECT PageRef, ContentTemplateRef FROM PageContentTemplate WHERE ContentTemplateRef IN (SELECT ContentTemplateId FROM ContentTemplate WHERE ContentTemplateName = :n)", { n: arguments.contentTemplate }, ds)>
	<cfset var outputs = queryExecute("SELECT ContentOutputId, ContentTemplateRef, PageRef, ThemeRef, Active, [Date], LEN(ContentOutput) AS DesktopLength, LEN(ContentOutputMobile) AS MobileLength, SUBSTRING(ContentOutput, 1, 120) AS DesktopStart FROM ContentOutput WHERE ContentTemplateRef IN (SELECT ContentTemplateId FROM ContentTemplate WHERE ContentTemplateName = :n) ORDER BY ContentOutputId", { n: arguments.contentTemplate }, ds)>
	<cfset var viaOrm = application.blog.getContentOutputByContentTemplate(pageId=2, contentTemplate=arguments.contentTemplate)>
	<cfset var desktop = application.blog.getContentOutputData(contentTemplate=arguments.contentTemplate, isMobile=false)>
	<cfset var mobile = application.blog.getContentOutputData(contentTemplate=arguments.contentTemplate, isMobile=true)>
	<cfset var i = "">
	<cfoutput>
	<h2>#encodeForHtml(arguments.contentTemplate)#</h2>
	<p><b>ContentTemplate rows:</b> <cfloop query="templates">id #templates.ContentTemplateId# (active #templates.Active#); </cfloop><cfif not templates.recordCount>none</cfif></p>
	<p><b>PageContentTemplate links:</b> <cfloop query="links">page #links.PageRef# -> template #links.ContentTemplateRef#; </cfloop><cfif not links.recordCount>none (so the lookup, which joins through page 2, finds nothing)</cfif></p>
	<p><b>ContentOutput rows:</b></p>
	<table border="1" cellpadding="4"><tr><th>id</th><th>template</th><th>page</th><th>theme</th><th>active</th><th>date</th><th>desktop length</th><th>mobile length</th><th>desktop starts with</th></tr>
	<cfloop query="outputs"><tr><td>#outputs.ContentOutputId#</td><td>#outputs.ContentTemplateRef#</td><td>#outputs.PageRef#</td><td>#outputs.ThemeRef#</td><td>#outputs.Active#</td><td>#outputs.Date#</td><td>#outputs.DesktopLength#</td><td>#outputs.MobileLength#</td><td>#encodeForHtml(outputs.DesktopStart)#</td></tr></cfloop>
	</table>
	<p><b>getContentOutputByContentTemplate(page 2) returned #arrayLen(viaOrm)# row(s), in this order:</b> <cfloop from="1" to="#arrayLen(viaOrm)#" index="i">ContentOutputId #viaOrm[i]["ContentOutputId"]# (theme #structKeyExists(viaOrm[i], "ContentOutputThemeId") ? viaOrm[i]["ContentOutputThemeId"] : "null"#); </cfloop></p>
	<p><b>getContentOutputData:</b> desktop #len(desktop)# characters, mobile #len(mobile)# characters. The site uses the first row in that list.</p>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	migrateMenuFor48 (2026-10-10) - one-time move to the 4.8 top menu, for a site that already has content. Run it
	after uploading the 4.8 menu files and restarting the ORM (so the MenuLink table and the new columns exist).
	Dry run by default; add &confirm=true to save. Safe to run more than once - it only fills in what is missing:
	  1. Menu links: if there are none yet, copies the old single "parent site" link from Blog Settings, plus the link
	     the old menu hard-coded on this site (galaxieblog.org -> Gregory's Blog, gregoryalexander.com -> Galaxie Blog
	     Documentation), so the Menu dropdown looks the same as before.
	  2. Collections: ticks Show in Menu on every collection whose address starts with "docs-", which the old menu
	     listed automatically.
	  3. Label: names the collections menu "Docs" when those docs- collections exist and no name has been set.
	Usage: /common/cfc/TestUtility.cfc?method=migrateMenuFor48  (then &confirm=true)
	*************************************************************************************************************
--->
<cffunction name="migrateMenuFor48" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<cfset var actions = []>
	<cfset var newLinks = []>
	<cfset var existingLinkCount = arrayLen(ormExecuteQuery("FROM MenuLink WHERE BlogRef = :blogId", { blogId = blogId }))>
	<cfset var parentName = isNull(application.BlogDbObj.getBlogParentSiteName()) ? "" : trim(application.BlogDbObj.getBlogParentSiteName())>
	<cfset var parentLink = isNull(application.BlogDbObj.getBlogParentSiteUrl()) ? "" : trim(application.BlogDbObj.getBlogParentSiteUrl())>
	<cfset var docsCollections = ormExecuteQuery("FROM PageCollection WHERE BlogRef = :blogRef AND CollectionAlias LIKE 'docs-%'", { blogRef = application.BlogDbObj })>
	<cfset var oneCollection = "">
	<cfset var oneLink = "">
	<cfset var position = 0>
	<cfset var newMenuLink = "">
	<cfset var savedLabel = isNull(application.BlogOptionDbObj.getCollectionsMenuLabel()) ? "" : trim(application.BlogOptionDbObj.getCollectionsMenuLabel())>
	<cfset var freshBlogOption = "">

	<!--- 1. Menu links --->
	<cfif existingLinkCount eq 0>
		<cfif len(parentName) and len(parentLink)>
			<cfset arrayAppend(newLinks, { label: parentName, linkUrl: parentLink, newWindow: false })>
		</cfif>
		<cfif cgi.http_host contains "galaxieblog.org">
			<cfset arrayAppend(newLinks, { label: "Gregory's Blog", linkUrl: "https://gregoryalexander.com/blog/", newWindow: false })>
		<cfelseif cgi.http_host contains "gregoryalexander.com">
			<cfset arrayAppend(newLinks, { label: "Galaxie Blog Documentation", linkUrl: "https://galaxieblog.org/", newWindow: false })>
		</cfif>
		<cfloop array="#newLinks#" index="oneLink">
			<cfset arrayAppend(actions, "Add Menu link: " & oneLink.label & " -> " & oneLink.linkUrl)>
		</cfloop>
	<cfelse>
		<cfset arrayAppend(actions, "Menu links: " & existingLinkCount & " already saved - left as they are.")>
	</cfif>

	<!--- 2. Collections --->
	<cfloop array="#docsCollections#" index="oneCollection">
		<cfif isNull(oneCollection.getShowInMenu()) or not oneCollection.getShowInMenu()>
			<cfset arrayAppend(actions, "Show in menu: " & oneCollection.getTitle())>
		</cfif>
	</cfloop>

	<!--- 3. Label --->
	<cfif arrayLen(docsCollections) and not len(savedLabel)>
		<cfset arrayAppend(actions, "Name the collections menu ""Docs""")>
	</cfif>

	<cfif arguments.confirm>
		<cftransaction>
			<cfloop array="#newLinks#" index="oneLink">
				<cfset position = position + 1>
				<cfset newMenuLink = entityNew("MenuLink")>
				<cfset newMenuLink.setBlogRef(blogId)>
				<cfset newMenuLink.setLabel(oneLink.label)>
				<cfset newMenuLink.setLinkUrl(oneLink.linkUrl)>
				<cfset newMenuLink.setNewWindow(oneLink.newWindow)>
				<cfset newMenuLink.setSortOrder(position)>
				<cfset newMenuLink.setDate(now())>
				<cfset entitySave(newMenuLink)>
			</cfloop>
			<cfloop array="#docsCollections#" index="oneCollection">
				<cfif isNull(oneCollection.getShowInMenu()) or not oneCollection.getShowInMenu()>
					<cfset oneCollection.setShowInMenu(true)>
					<cfset entitySave(oneCollection)>
				</cfif>
			</cfloop>
			<cfif arrayLen(docsCollections) and not len(savedLabel)>
				<cfset freshBlogOption = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
				<cfset freshBlogOption.setCollectionsMenuLabel("Docs")>
				<cfset entitySave(freshBlogOption)>
			</cfif>
		</cftransaction>
		<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
		<cfset application.blog.flushGalaxieCache('menu')>
	</cfif>

	<cfoutput>
	<h2>#(arguments.confirm ? "Saved" : "Dry run (add &amp;confirm=true to the address to save)")#: #arrayLen(actions)# change(s)</h2>
	<cfloop array="#actions#" index="oneLink"><div>#encodeForHtml(oneLink)#</div></cfloop>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	listUnreleasedPages

	Read-only - lists every Page (not blog post) that exists but isn't released yet (and isn't removed), grouped by
	the Page Collection(s) it belongs to, with its current address and last-changed date - so the docs pages still
	waiting to be released can be seen at a glance instead of opening each one. Pages in no collection are listed
	under "Not in any collection".
	e.g.  /common/cfc/TestUtility.cfc?method=listUnreleasedPages
	*************************************************************************************************************
--->
<cffunction name="listUnreleasedPages" access="remote" returntype="void" output="yes">
	<cfset requireEditSiteAccess()>
	<!--- Send this as an HTML page - see fixDocsLinks for why (Lucee can send a remote method's output as XML). --->
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<!--- The database does the bit comparisons (CASE ... THEN 1 ELSE 0) so this reads the same on any engine/driver. --->
	<cfset var pages = queryExecute("
		SELECT p.PostId, p.Title, p.PostAlias, p.DatePosted,
			COALESCE(pc.Title, '') AS CollectionTitle
		FROM Post p
		LEFT JOIN PageCollectionMemberLookup pcm ON pcm.PostRef = p.PostId
		LEFT JOIN PageCollection pc ON pc.PageCollectionId = pcm.PageCollectionRef
		WHERE p.BlogRef = :blogId
			AND (CASE WHEN p.IsPage = 1 THEN 1 ELSE 0 END) = 1
			AND (CASE WHEN p.Released = 1 THEN 1 ELSE 0 END) = 0
			AND (CASE WHEN p.Remove = 1 THEN 1 ELSE 0 END) = 0
		ORDER BY CASE WHEN pc.Title IS NULL THEN 1 ELSE 0 END, pc.Title, p.Title
	", { blogId = blogId })>
	<cfset var uniquePages = {}>
	<cfset var lastGroup = "##none##">
	<cfset var thisGroup = "">
	<cfloop query="pages"><cfset uniquePages[pages.PostId] = true></cfloop>
	<cfoutput>
	<h2>#structCount(uniquePages)# page(s) not released yet</h2>
	<p>A page in more than one collection is listed under each. Releasing a page rebuilds its address from its title
	(dropping any "docs-" prefix), so run fixDocsLinks again after releasing.</p>
	<cfloop query="pages">
		<cfset thisGroup = len(pages.CollectionTitle) ? pages.CollectionTitle : "Not in any collection">
		<cfif thisGroup neq lastGroup>
			<cfif lastGroup neq "##none##"></ol></cfif>
			<h3>#encodeForHtml(thisGroup)#</h3><ol>
			<cfset lastGroup = thisGroup>
		</cfif>
		<li>#encodeForHtml(pages.Title)# &nbsp; <small>/#encodeForHtml(pages.PostAlias)#<cfif isDate(pages.DatePosted)> &middot; #dateFormat(pages.DatePosted, "mmm d, yyyy")#</cfif></small></li>
	</cfloop>
	<cfif pages.recordCount></ol><cfelse><p>Every page is released.</p></cfif>
	</cfoutput>
</cffunction>

<!---
	*************************************************************************************************************
	exportDocsContent (2026-10-12) - read-only. Downloads every Page Collection and its pages, with each page's body exactly
	as it is stored in the database, as a JSON file in the same format as common/data/docsContent.json (the file
	importDocsContent reads), plus each page's POSTID and RELEASED. Use it:
	  - after editing the docs on galaxieblog.org, to refresh common/data/docsContent.json so a new install's docs match
	    the live site (do NOT run importDocsContent on galaxieblog.org afterwards - the live site is already the source);
	  - before writing find/replace edits for applyDocsEdits, so the "find" text matches the stored HTML exactly (the
	    rendered page differs from the stored body).
	Pages are listed in each collection's own order (SortOrder, then title). Nothing is changed.
	Usage: /common/cfc/TestUtility.cfc?method=exportDocsContent   (downloads docsContent-export-yyyy-mm-dd.json)
	       add &view=true to show it in the browser instead of downloading it.
	*************************************************************************************************************
--->
<cffunction name="exportDocsContent" access="remote" returntype="void" output="yes">
	<cfargument name="view" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<cfset var collectionRows = queryExecute("SELECT PageCollectionId, Title, CollectionAlias, Description FROM PageCollection WHERE BlogRef = :blogId ORDER BY COALESCE(MenuOrder, 0), Title", { blogId = blogId })>
	<cfset var memberRows = "">
	<cfset var collections = []>
	<cfset var aliasById = {}>
	<cfset var homepageAliases = []>
	<cfset var pages = []>
	<cfset var post = "">
	<cfset var body = "">
	<cfset var description = "">
	<cfset var settings = "">
	<cfset var collectionId = "">
	<cfset var pageCount = 0>
	<cfset var json = "">

	<cfloop query="collectionRows">
		<cfset aliasById[collectionRows.PageCollectionId] = collectionRows.CollectionAlias>
		<cfset memberRows = queryExecute("
			SELECT pcm.PostRef
			FROM PageCollectionMemberLookup pcm
			INNER JOIN Post p ON p.PostId = pcm.PostRef
			WHERE pcm.PageCollectionRef = :collectionId
				AND (CASE WHEN p.Remove = 1 THEN 1 ELSE 0 END) = 0
			ORDER BY COALESCE(pcm.SortOrder, 0), p.Title
		", { collectionId = collectionRows.PageCollectionId })>
		<cfset pages = []>
		<cfloop query="memberRows">
			<!--- The body comes from the entity, not the query: a long text column can come back truncated or as a CLOB
			object from a plain query, depending on the datasource settings. --->
			<cfset post = entityLoadByPK("Post", memberRows.PostRef)>
			<cfif isNull(post)><cfcontinue></cfif>
			<cfset body = post.getBody()>
			<cfset description = post.getDescription()>
			<cfset arrayAppend(pages, [
				"TITLE": post.getTitle(),
				"POSTALIAS": post.getPostAlias(),
				"DESCRIPTION": isNull(description) ? "" : description,
				"BODY": isNull(body) ? "" : body,
				"POSTID": post.getPostId(),
				"RELEASED": bitIsTrue(post.getReleased())
			])>
			<cfset pageCount = pageCount + 1>
		</cfloop>
		<cfset arrayAppend(collections, [
			"TITLE": collectionRows.Title,
			"ALIAS": collectionRows.CollectionAlias,
			"DESCRIPTION": collectionRows.Description,
			"PAGES": pages
		])>
	</cfloop>

	<cfset settings = application.blog.getHomepageSettings()>
	<cfloop list="#settings.collectionIdList#" index="collectionId">
		<cfif structKeyExists(aliasById, collectionId)><cfset arrayAppend(homepageAliases, aliasById[collectionId])></cfif>
	</cfloop>

	<!--- Ordered structs ([ "key": value ] literals) keep the keys in this order and in upper case, matching docsContent.json. --->
	<cfset json = serializeJSON([
		"HOMEPAGECOLLECTIONALIASES": homepageAliases,
		"HOMEPAGESHOWCOLLECTIONS": bitIsTrue(settings.showCollections),
		"COLLECTIONS": collections,
		"EXPORTED": dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm") & " from " & cgi.server_name & " (" & arrayLen(collections) & " collections, " & pageCount & " pages)"
	])>
	<cfif not arguments.view>
		<cfheader name="Content-Disposition" value="attachment; filename=docsContent-export-#dateFormat(now(), 'yyyy-mm-dd')#.json">
	</cfif>
	<cfcontent type="application/json; charset=utf-8" reset="true">
	<cfoutput>#json#</cfoutput>
	<cfabort>
</cffunction>

<!---
	*************************************************************************************************************
	applyDocsEdits (2026-10-12) - applies a list of documentation changes to the docs pages in one go, instead of opening
	each page in the editor. The list is common/data/docsEdits.json:
	  ALLPAGES  - find/replace pairs applied to every page and post that contains the text (eg. a link's text);
	  PAGES     - per page (by POSTALIAS): find/replace EDITS, and an optional NEWTITLE and NEWDESCRIPTION. The address
	              (alias) is never changed, so links to the page keep working;
	  NEWPAGES  - pages to create, as drafts (not released), in the collection named by COLLECTIONALIAS. A page whose
	              alias already exists is left alone, so your own changes to it are never overwritten.
	Each FIND must match the stored HTML exactly (get it with exportDocsContent). For every edit the dry run says:
	  will change          - the text was found once (ALLPAGES: anywhere) and will be replaced;
	  already done         - the replacement is already in the page, so it is skipped (running this twice is safe);
	  NOT FOUND / FOUND n TIMES - the page was edited since the list was written; nothing is changed for that edit,
	                         the other edits still apply. Make that change by hand, or fix the list and run again.
	Dry run by default (shows every change); add &confirm=true to save. Saving clears the page caches.
	Usage: /common/cfc/TestUtility.cfc?method=applyDocsEdits            (dry run)
	       /common/cfc/TestUtility.cfc?method=applyDocsEdits&confirm=true
	*************************************************************************************************************
--->
<cffunction name="applyDocsEdits" access="remote" returntype="void" output="yes">
	<cfargument name="confirm" type="boolean" required="false" default="false">
	<cfset requireEditSiteAccess()>
	<!--- Send this as an HTML page - see fixDocsLinks for why (Lucee can send a remote method's output as XML). --->
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var filePath = getDirectoryFromPath(getCurrentTemplatePath()) & "../data/docsEdits.json">
	<cfif not fileExists(filePath)>
		<cfoutput>Missing #encodeForHtml(filePath)#</cfoutput>
		<cfreturn>
	</cfif>
	<cfset var docsEditList = deserializeJSON(fileRead(filePath, "utf-8"))>
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<!--- Every changed post, keyed by id: the entity, its body as it is now and as it was, and what changed. Page edits and
	ALLPAGES edits can touch the same post, so both work on this one copy and each post is saved once. --->
	<cfset var work = {}>
	<cfset var warnings = []>
	<cfset var pageEntry = "">
	<cfset var edit = "">
	<cfset var found = "">
	<cfset var post = "">
	<cfset var key = "">
	<cfset var item = "">
	<cfset var result = "">
	<cfset var editNumber = 0>
	<cfset var postsChanged = 0>
	<cfset var editsMade = 0>
	<cfset var created = 0>
	<cfset var newPage = "">
	<cfset var collectionList = "">
	<cfset var newPostId = 0>
	<cfset var newPostObj = "">

	<!--- Page edits --->
	<cfloop array="#structKeyExists(docsEditList, 'PAGES') ? docsEditList.PAGES : []#" index="pageEntry">
		<cfset found = ormExecuteQuery("FROM Post WHERE BlogRef = :blog AND PostAlias = :alias AND Remove = 0", { blog = application.BlogDbObj, alias = pageEntry.POSTALIAS })>
		<cfif not arrayLen(found)>
			<cfset arrayAppend(warnings, "/" & pageEntry.POSTALIAS & ": no page with this address - all of its edits skipped")>
			<cfcontinue>
		</cfif>
		<cfset item = docsEditsWorkItem(work, found[1])>
		<cfif structKeyExists(pageEntry, "NEWTITLE") and len(pageEntry.NEWTITLE)>
			<cfif item.post.getTitle() eq pageEntry.NEWTITLE>
				<cfset arrayAppend(item.changes, { status = "already done", note = "title", find = "", replace = pageEntry.NEWTITLE })>
			<cfelse>
				<cfset item.newTitle = pageEntry.NEWTITLE>
				<cfset arrayAppend(item.changes, { status = "will change", note = "title", find = item.post.getTitle(), replace = pageEntry.NEWTITLE })>
			</cfif>
		</cfif>
		<cfif structKeyExists(pageEntry, "NEWDESCRIPTION") and len(pageEntry.NEWDESCRIPTION)>
			<cfif (isNull(item.post.getDescription()) ? "" : item.post.getDescription()) eq pageEntry.NEWDESCRIPTION>
				<cfset arrayAppend(item.changes, { status = "already done", note = "description", find = "", replace = pageEntry.NEWDESCRIPTION })>
			<cfelse>
				<cfset item.newDescription = pageEntry.NEWDESCRIPTION>
				<cfset arrayAppend(item.changes, { status = "will change", note = "description", find = (isNull(item.post.getDescription()) ? "" : item.post.getDescription()), replace = pageEntry.NEWDESCRIPTION })>
			</cfif>
		</cfif>
		<cfset editNumber = 0>
		<cfloop array="#pageEntry.EDITS#" index="edit">
			<cfset editNumber = editNumber + 1>
			<cfset result = docsEditsApplyOne(item, edit, true)>
			<cfif result neq "will change" and result neq "already done">
				<cfset arrayAppend(warnings, item.post.getTitle() & ", edit " & editNumber & ": " & result)>
			</cfif>
		</cfloop>
	</cfloop>

	<!--- Edits for every page that contains the text --->
	<cfloop array="#structKeyExists(docsEditList, 'ALLPAGES') ? docsEditList.ALLPAGES : []#" index="edit">
		<cfset found = ormExecuteQuery("FROM Post WHERE BlogRef = :blog AND Remove = 0 AND Body LIKE :pattern", { blog = application.BlogDbObj, pattern = "%" & edit.FIND & "%" })>
		<cfloop array="#found#" index="post">
			<cfset item = docsEditsWorkItem(work, post)>
			<cfset docsEditsApplyOne(item, edit, false)>
		</cfloop>
	</cfloop>

	<!--- Report, and save --->
	<cfoutput><h2>#(arguments.confirm ? "Saved" : "Dry run (add &amp;confirm=true to the address to save)")#</h2></cfoutput>
	<cfloop collection="#work#" item="key">
		<cfset item = work[key]>
		<cfif item.body neq item.originalBody or len(item.newTitle) or len(item.newDescription)>
			<cfset postsChanged = postsChanged + 1>
			<cfif arguments.confirm>
				<cfset item.post.setBody(item.body)>
				<cfif len(item.newTitle)><cfset item.post.setTitle(item.newTitle)></cfif>
				<cfif len(item.newDescription)><cfset item.post.setDescription(item.newDescription)></cfif>
				<cfset entitySave(item.post)>
			</cfif>
		</cfif>
		<cfoutput><h3>#encodeForHtml(item.post.getTitle())# <small>/#encodeForHtml(item.post.getPostAlias())#</small></h3></cfoutput>
		<cfloop array="#item.changes#" index="edit">
			<cfif edit.status eq "will change"><cfset editsMade = editsMade + 1></cfif>
			<cfoutput>
			<details>
				<summary><b>#encodeForHtml(edit.status eq "will change" and arguments.confirm ? "changed" : edit.status)#</b><cfif len(edit.note)> - #encodeForHtml(edit.note)#</cfif></summary>
				<cfif len(edit.find)><div>Before:</div><pre style="white-space: pre-wrap;">#encodeForHtml(edit.find)#</pre></cfif>
				<div>After:</div><pre style="white-space: pre-wrap;">#encodeForHtml(edit.replace)#</pre>
			</details>
			</cfoutput>
		</cfloop>
	</cfloop>

	<!--- New pages, created as drafts --->
	<cfloop array="#structKeyExists(docsEditList, 'NEWPAGES') ? docsEditList.NEWPAGES : []#" index="newPage">
		<cfset found = ormExecuteQuery("FROM Post WHERE BlogRef = :blog AND PostAlias = :alias", { blog = application.BlogDbObj, alias = newPage.POSTALIAS })>
		<cfset collectionList = ormExecuteQuery("FROM PageCollection WHERE BlogRef = :blog AND CollectionAlias = :alias", { blog = application.BlogDbObj, alias = newPage.COLLECTIONALIAS })>
		<cfoutput><h3>New page: #encodeForHtml(newPage.TITLE)# <small>/#encodeForHtml(newPage.POSTALIAS)#</small></h3></cfoutput>
		<cfif arrayLen(found)>
			<cfoutput><div><b>already exists</b> - left alone</div></cfoutput>
			<cfcontinue>
		</cfif>
		<cfif not arrayLen(collectionList)>
			<cfset arrayAppend(warnings, "New page " & newPage.TITLE & ": no collection /" & newPage.COLLECTIONALIAS & " - not created")>
			<cfcontinue>
		</cfif>
		<cfoutput>
		<details>
			<summary><b>#(arguments.confirm ? "created as a draft" : "will be created as a draft")#</b> in #encodeForHtml(collectionList[1].getTitle())#</summary>
			<pre style="white-space: pre-wrap;">#encodeForHtml(newPage.BODY)#</pre>
		</details>
		</cfoutput>
		<cfif arguments.confirm>
			<!--- The same steps as importDocsContent: create it under its unique alias (insertNewPost returns the id of any
			existing post with the same title, which would overwrite it), set the alias, then save the real content. --->
			<cfset newPostId = application.blog.insertNewPost(postType = "page", author = 1, title = newPage.POSTALIAS, description = newPage.DESCRIPTION)>
			<cfset newPostObj = entityLoadByPK("Post", newPostId)>
			<cfset newPostObj.setPostAlias(newPage.POSTALIAS)>
			<cfset entitySave(newPostObj)>
			<cfset ormFlush()>
			<cfset application.blog.savePost(
				postId = newPostId,
				author = 1,
				postType = "page",
				title = newPage.TITLE,
				description = newPage.DESCRIPTION,
				post = newPage.BODY,
				released = false,
				emailSubscriber = false,
				pageCollectionIdList = collectionList[1].getPageCollectionId()
			)>
			<cfset application.blog.setPageCollectionsForPost(postId = newPostId, pageCollectionIdList = collectionList[1].getPageCollectionId())>
		</cfif>
		<cfset created = created + 1>
	</cfloop>

	<cfif arguments.confirm and (postsChanged or created)>
		<cfset ormFlush()>
		<cfset application.blog.flushGalaxieCache('all')>
	</cfif>
	<cfoutput>
	<h2>#editsMade# change(s) in #postsChanged# page(s)#(created ? ", " & created & " new draft page(s)" : "")##(arguments.confirm ? " saved, caches cleared" : "")#</h2>
	<cfif arrayLen(warnings)>
		<h3>Not changed - needs a look (#arrayLen(warnings)#)</h3>
		<cfloop array="#warnings#" index="item"><div>#encodeForHtml(item)#</div></cfloop>
	<cfelse>
		<p>Every edit matched.</p>
	</cfif>
	</cfoutput>
</cffunction>

<cffunction name="docsEditsWorkItem" access="private" returntype="struct" output="false"
		hint="applyDocsEdits: the working copy for one post, created the first time the post is touched. Structs are passed by reference, so the caller's changes land in work.">
	<cfargument name="work" type="struct" required="true">
	<cfargument name="post" required="true">
	<cfset var key = arguments.post.getPostId()>
	<cfset var body = "">
	<cfif not structKeyExists(arguments.work, key)>
		<cfset body = arguments.post.getBody()>
		<cfif isNull(body)><cfset body = ""></cfif>
		<cfset arguments.work[key] = { post = arguments.post, body = body, originalBody = body, newTitle = "", newDescription = "", changes = [] }>
	</cfif>
	<cfreturn arguments.work[key]>
</cffunction>

<cffunction name="docsEditsApplyOne" access="private" returntype="string" output="false"
		hint="applyDocsEdits: applies one find/replace to a working copy and records it. Returns 'will change', 'already done', or why it could not be applied. single=true needs the text exactly once; false replaces every copy.">
	<cfargument name="item" type="struct" required="true">
	<cfargument name="edit" type="struct" required="true">
	<cfargument name="single" type="boolean" required="true">
	<cfset var note = structKeyExists(arguments.edit, "NOTE") ? arguments.edit.NOTE : "">
	<cfset var count = docsEditsCount(arguments.item.body, arguments.edit.FIND)>
	<cfset var status = "">
	<!--- Already done: the replacement is in the page. Checked first because an insert's replacement contains its own find
	text, which would otherwise be found again and inserted twice on a second run. --->
	<cfif len(arguments.edit.REPLACE) and find(arguments.edit.REPLACE, arguments.item.body) and (count eq 0 or find(arguments.edit.FIND, arguments.edit.REPLACE))>
		<cfset status = "already done">
	<cfelseif count eq 0>
		<cfset status = "NOT FOUND - the page's text has changed since this edit was written">
	<cfelseif arguments.single and count gt 1>
		<cfset status = "FOUND " & count & " TIMES - not sure which one to change">
	<cfelse>
		<cfset arguments.item.body = replace(arguments.item.body, arguments.edit.FIND, arguments.edit.REPLACE, "all")>
		<cfset status = "will change">
	</cfif>
	<cfset arrayAppend(arguments.item.changes, { status = status, note = note, find = arguments.edit.FIND, replace = arguments.edit.REPLACE })>
	<cfreturn status>
</cffunction>

<cffunction name="docsEditsCount" access="private" returntype="numeric" output="false"
		hint="How many times text appears in body (case-sensitive, literal).">
	<cfargument name="body" type="string" required="true">
	<cfargument name="text" type="string" required="true">
	<cfset var count = 0>
	<cfset var position = find(arguments.text, arguments.body)>
	<cfloop condition="position gt 0">
		<cfset count = count + 1>
		<cfset position = find(arguments.text, arguments.body, position + len(arguments.text))>
	</cfloop>
	<cfreturn count>
</cffunction>

<!---
	*************************************************************************************************************
	checkContentTemplates (2026-10-13) - read-only. Lists content templates (the Themes content: navigation menu, windows, pods,
	Composite Footer...) whose name appears on more than one ContentTemplate row, with what is attached to each row, plus the
	Composite Footer's own row(s). Written for gregoryalexander.com, whose database was repaired from a backup on 2026-10-12:
	the Composite Footer's Enable checkbox wouldn't stay checked, and a duplicate row is the likely reason. Run it from a
	browser when SQL Server Management Studio isn't available. Nothing is changed.
	Usage: /common/cfc/TestUtility.cfc?method=checkContentTemplates
	*************************************************************************************************************
--->
<cffunction name="checkContentTemplates" access="remote" returntype="void" output="yes">
	<cfset requireEditSiteAccess()>
	<!--- Send this as an HTML page - see fixDocsLinks for why (Lucee can send a remote method's output as XML). --->
	<cfcontent type="text/html; charset=utf-8" reset="true">
	<cfset var duplicates = queryExecute("SELECT ContentTemplateName, COUNT(*) AS Copies FROM ContentTemplate GROUP BY ContentTemplateName HAVING COUNT(*) > 1 ORDER BY ContentTemplateName")>
	<cfset var names = valueList(duplicates.ContentTemplateName)>
	<cfset var rows = "">
	<cfset var name = "">
	<cfif not listFindNoCase(names, "compositeFooter")>
		<cfset names = listAppend(names, "compositeFooter")>
	</cfif>
	<cfoutput>
	<h2>#duplicates.recordCount# template name(s) on more than one row</h2>
	<cfloop query="duplicates"><div>#encodeForHtml(duplicates.ContentTemplateName)#: #duplicates.Copies# rows</div></cfloop>
	<p>Each row below shows what is attached to it: saved content (ContentOutput) and page links (PageContentTemplate). The row with the content and links is the one in use; a copy with nothing attached is safe to remove.</p>
	</cfoutput>
	<cfloop list="#names#" index="name">
		<cfset rows = queryExecute("
			SELECT ct.ContentTemplateId, ct.ContentTemplateName, CASE WHEN ct.Active = 1 THEN 1 ELSE 0 END AS Active,
				(SELECT COUNT(*) FROM ContentOutput co WHERE co.ContentTemplateRef = ct.ContentTemplateId) AS ContentOutputRows,
				(SELECT COUNT(*) FROM PageContentTemplate pct WHERE pct.ContentTemplateRef = ct.ContentTemplateId) AS PageLinks
			FROM ContentTemplate ct
			WHERE ct.ContentTemplateName = :name
			ORDER BY ct.ContentTemplateId
		", { name = name })>
		<cfoutput>
		<h3>#encodeForHtml(name)#</h3>
		<table border="1" cellpadding="4" cellspacing="0">
		<tr><th>ContentTemplateId</th><th>Enable (Active)</th><th>Saved content rows</th><th>Page links</th></tr>
		<cfloop query="rows"><tr><td>#rows.ContentTemplateId#</td><td>#(rows.Active ? "checked" : "not checked")#</td><td>#rows.ContentOutputRows#</td><td>#rows.PageLinks#</td></tr></cfloop>
		</table>
		</cfoutput>
	</cfloop>
</cffunction>

<cffunction name="bitIsTrue" access="private" returntype="boolean" output="false"
		hint="True for a database bit/boolean value however the engine returns it: true/false (Lucee + MySQL), 1/0 (Adobe ColdFusion), or 'yes'/'no'. Empty or null is false.">
	<cfargument name="value" required="false" default="">
	<cfif isNull(arguments.value) or not isSimpleValue(arguments.value) or not len(arguments.value)>
		<cfreturn false>
	</cfif>
	<cfif isBoolean(arguments.value)>
		<cfreturn arguments.value>
	</cfif>
	<cfreturn isNumeric(arguments.value) and arguments.value neq 0>
</cffunction>
</cfcomponent>

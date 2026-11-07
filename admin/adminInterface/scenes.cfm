<!--- Scenes window (window 106, 2026-10-19, Galaxie 5), the Scenes icon on the admin home page: every scene, the scrolling
heroes built by common/js/galaxieScene.js. New scene and Edit open the Scene editor (window 107). A post shows a scene with
<galaxieScene>name</galaxieScene> in its header. The work is done by application.blog.getScenes() (common/cfc/Scenes.cfc)
through ProxyController.cfc. See doc/aiDraftArticles/parallaxScenesDesign.cfm. --->
<cfset sceneAll = application.blog.getScenes().listScenes()>
<!--- Two kinds (11-07, owner): scrolling scenes, and moving heroes (alias post-hero-{postId}, made in a post's Moving hero window, one
per post). Radio buttons above the list pick which kind it shows. A moving hero is changed in its post's Moving hero window, never
here, so it can't be turned into a scrolling scene or end up on another post. --->
<cfset sceneList = queryFilter(sceneAll, function (row) { return not reFindNoCase("^post-hero-[0-9]+$", row.Alias); })>
<cfset heroList = queryFilter(sceneAll, function (row) { return reFindNoCase("^post-hero-[0-9]+$", row.Alias); })>
<cfset heroPostTitles = {}>
<cfif heroList.recordCount>
	<cfquery name="heroPostRows" datasource="#application.dsn#">
		SELECT PostId, Title, IsPage FROM Post
		WHERE BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
		AND PostId IN (<cfqueryparam value="#arrayToList(arrayMap(listToArray(valueList(heroList.Alias)), function (a) { return val(listLast(a, '-')); }))#" cfsqltype="cf_sql_integer" list="true">)
	</cfquery>
	<cfloop query="heroPostRows"><cfset heroPostTitles[heroPostRows.PostId] = (heroPostRows.IsPage eq 1 ? "Page: " : "") & heroPostRows.Title></cfloop>
</cfif>
<!--- Where the animation library (GSAP) comes from (2026-10-19). "This server only" needs the files in common/libs/gsap3/. --->
<cfset sceneLibrarySource = application.blog.getScenes().getSetting("librarySource", "cdn")>
<cfset sceneLocalFiles = application.blog.getScenes().getLocalLibraryFiles()>
<cfset sceneHasLocal = arrayFind(sceneLocalFiles, "gsap.min.js") and arrayFind(sceneLocalFiles, "ScrollTrigger.min.js")>

<script>
	<!--- The two kinds (11-07): the radio buttons show one list or the other, and the choice is kept for the next time. --->
	$(document).off("change.sceneKind").on("change.sceneKind", "input[name=sceneKind]", function () { showSceneKind($(this).val()); });
	function showSceneKind(kind) {
		$(".sceneKindScrolling").toggle(kind !== "hero"); $(".sceneKindHero").toggle(kind === "hero");
		try { localStorage.setItem("galaxieSceneKind", kind); } catch (e) {}
	}
	$(function () {
		var kind = "scrolling";
		try { kind = localStorage.getItem("galaxieSceneKind") || "scrolling"; } catch (e) {}
		$("input[name=sceneKind][value=" + (kind === "hero" ? "hero" : "scrolling") + "]").prop("checked", true);
		showSceneKind(kind);
	});
	<!--- Called by the Scene editor after a save, so the list stays current. --->
	function refreshScenesWindow() {
		try {
			$("#scenesWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}

	function saveSceneLibrarySource() {
		jQuery.ajax({
			type: "post",
			url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveSceneSettings",
			data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", librarySource: $("input[name=sceneLibrarySource]:checked").val() },
			dataType: "json",
			success: function(response) {
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				$("#sceneLibrarySaved").text(response && response.success ? "Saved." : ((response && response.errorMessage) || "Could not save."));
			},
			error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
		});
	}

	function deleteScene(sceneId, sceneName, usedBy) {
		<!--- The name is shown as text, never as HTML. --->
		var safeName = $("<div/>").text(sceneName).html();
		var used = usedBy > 0 ? (usedBy === 1 ? "1 post shows this scene. It will show nothing in its place. " : usedBy + " posts show this scene. They will show nothing in its place. ") : "No posts show this scene. ";
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete " + safeName + "?", message: used + "This can't be undone.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
			if (answer['button'] !== 'Yes') { return; }
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteScene",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", sceneId: sceneId },
				dataType: "json",
				success: function(response) {
					if (response && response.success) {
						refreshScenesWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		});
	}
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">There are two kinds of scenes. A <strong>scrolling scene</strong> tells a story as the reader scrolls: a moving picture at the top, then text, pictures and forms that come in one after another. A <strong>moving hero</strong> is just the moving picture at the top of one post, made in that post's Hero window.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Scenes look best with a modern theme and the sidebar hidden.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">
		<div id="sceneKinds" role="radiogroup" aria-label="Which scenes to show" style="display: flex; flex-wrap: wrap; gap: 6px 18px; margin-bottom: 10px;">
			<label><input type="radio" name="sceneKind" value="scrolling" class="k-radio" checked> Scrolling scenes (#sceneList.recordCount#)</label>
			<label><input type="radio" name="sceneKind" value="hero" class="k-radio"> Moving heroes (#heroList.recordCount#)</label>
		</div>
		<div class="sceneKindScrolling"><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(121, 0);">New scrolling scene</button></div>
		<div class="sceneKindHero" style="display: none;">To make a moving hero, open a post's Hero window and choose Moving hero. Each post has its own.</div>
	</td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<div class="sceneKindHero" style="display: none;">
		<cfif not heroList.recordCount>
			No moving heroes yet.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead><tr><th align="left">Moving hero</th><th align="left">On</th><th align="left">Status</th><th></th></tr></thead>
				</cfif>
				<tbody>
				<cfloop query="heroList">
					<cfset thisHeroPostId = val(listLast(heroList.Alias, "-"))>
					<cfset thisHeroOn = structKeyExists(heroPostTitles, thisHeroPostId) ? heroPostTitles[thisHeroPostId] : "A post that was deleted">
					<!--- The picture's name, without the post's title in brackets that the list's On column shows. --->
					<cfset thisHeroName = reReplace(heroList.Name, "\s*\(.*\)$", "")>
					<tr>
						<td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisHeroName)#<cfif session.isMobile><br>On #encodeForHtml(thisHeroOn)#</cfif></td>
						<cfif not session.isMobile><td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisHeroOn)#</td></cfif>
						<td style="border-top: 1px solid ##ddd;">#heroList.Active eq 1 ? "Active" : "Inactive"#</td>
						<td style="border-top: 1px solid ##ddd;" align="right" nowrap="nowrap">
							<cfif structKeyExists(heroPostTitles, thisHeroPostId)>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(119, #thisHeroPostId#);" title="Opens this post's Moving hero window">Edit</button>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(107, #heroList.SceneId#);" title="The layers, fades and other fine details, in the advanced editor">Advanced</button>
							<cfelse>
							<button type="button" class="k-button" onclick="deleteScene(#heroList.SceneId#, '#encodeForHtmlAttribute(encodeForJavaScript(thisHeroName))#', 0);">Delete</button>
							</cfif>
						</td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		</cfif>
		</div>
		<div class="sceneKindScrolling">
		<cfif not sceneList.recordCount>
			No scrolling scenes yet. Click New scrolling scene to make one.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Scene</th>
						<th align="left">Name in posts</th>
						<th align="left">Shown on</th>
						<th align="left">Status</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody>
				<cfloop query="sceneList">
					<cfset thisUsedBy = arrayLen(application.blog.getScenes().getPostIdsUsing(sceneList.Alias))>
					<cfset thisUsedText = thisUsedBy eq 0 ? "No posts yet" : thisUsedBy & (thisUsedBy eq 1 ? " post" : " posts")>
					<cfset thisStatus = sceneList.Active eq 1 ? "Active" : "Inactive">
					<cfset thisJsName = encodeForJavaScript(sceneList.Name)>
					<cfif session.isMobile>
					<tr>
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							<a href="javascript:createAdminInterfaceWindow(107, #sceneList.SceneId#);">#encodeForHtml(sceneList.Name)#</a><br>
							#encodeForHtml(sceneList.Alias)#. #thisUsedText#. #thisStatus#<br>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(107, #sceneList.SceneId#);">Edit</button>
							<button type="button" class="k-button" onclick="deleteScene(#sceneList.SceneId#, '#encodeForHtmlAttribute(thisJsName)#', #thisUsedBy#);">Delete</button>
						</td>
					</tr>
					<cfelse>
					<tr>
						<td style="border-top: 1px solid ##ddd;"><a href="javascript:createAdminInterfaceWindow(107, #sceneList.SceneId#);">#encodeForHtml(sceneList.Name)#</a></td>
						<td style="border-top: 1px solid ##ddd;">#encodeForHtml(sceneList.Alias)#</td>
						<td style="border-top: 1px solid ##ddd;">#thisUsedText#</td>
						<td style="border-top: 1px solid ##ddd;">#thisStatus#</td>
						<td style="border-top: 1px solid ##ddd;" align="right" nowrap="nowrap">
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(107, #sceneList.SceneId#);">Edit</button>
							<button type="button" class="k-button" onclick="deleteScene(#sceneList.SceneId#, '#encodeForHtmlAttribute(thisJsName)#', #thisUsedBy#);">Delete</button>
						</td>
					</tr>
					</cfif>
				</cfloop>
				</tbody>
			</table>
		</cfif>
		</div>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Animation library</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<!--- Moved to Blog Options (2026-10-20): GreenSock on or off, and where it loads from, are set in one place. --->
	<tr><td colspan="2" class="#blockClass#">Scenes move with GreenSock (GSAP), a free animation library. Whether it is on, and whether it loads from Cloudflare or from this server, is set in <a href="javascript:createAdminInterfaceWindow(38, 'greensockanimationlibrary');">Blog Options</a>.</td></tr>
</table>
</cfoutput>

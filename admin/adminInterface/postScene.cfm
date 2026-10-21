<!--- A post's Scene (window 108, 2026-10-19, Galaxie 5), opened with the Scene button in the post editor:
createAdminInterfaceWindow(108, postId). Picks the scene shown at the top of the post's own page; Remove the scene (only when the
post has one, owner 2026-10-20) takes it off. Saving changes only
the <galaxieScene> line of the post's header (Scenes.cfc setPostScene, through ProxyController.cfc setPostScene). New scene and
Edit open the Scene editor (107); when it saves, this window reloads with that scene picked. --->
<cfset postSceneId = val(URL.optArgs)>
<cfset postSceneScenes = application.blog.getScenes()>
<cfset postSceneCurrent = postSceneScenes.getPostScene(postSceneId)>
<cfset postSceneList = postSceneScenes.listScenes()>
<!--- Each scene with its own data, for the cards. Put together as text so the keys keep their case on Adobe ColdFusion. --->
<cfset postSceneParts = []>
<cfloop query="postSceneList">
	<cfset thisJson = postSceneScenes.getSceneJson(postSceneList.Alias, false)>
	<cfset arrayAppend(postSceneParts, '{"id":' & postSceneList.SceneId & ',"name":' & serializeJSON(toString(postSceneList.Name)) & ',"alias":' & serializeJSON(toString(postSceneList.Alias))
		& ',"active":' & (postSceneList.Active eq 1 ? 'true' : 'false') & ',"json":' & (isJSON(thisJson) ? thisJson : '{}') & '}')>
</cfloop>
<!--- Nothing in the data can end the script ("</") or open an HTML comment in it ("<!--"). --->
<cfset postSceneJson = replace(replace("[" & arrayToList(postSceneParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")>

<!--- The card styles and thumbnails, shared with the Scene editor's gallery. --->
<cfinclude template="sceneCards.cfm">

<script>
$(document).ready(function () {
	var postId = <cfoutput>#postSceneId#</cfoutput>;
	var scenes = <cfoutput>#postSceneJson#</cfoutput>;
	var baseUrl = "<cfoutput>#jsStringFormat(application.baseUrl)#</cfoutput>";
	<!--- A scene just made or changed in the Scene editor from here is picked; otherwise the post's own scene. --->
	var current = "<cfoutput>#jsStringFormat(postSceneCurrent)#</cfoutput>";
	var picked = window.galaxiePostScenePick || current;
	window.galaxiePostScenePick = null;

	function sceneByAlias(alias) { for (var i = 0; i < scenes.length; i++) { if (scenes[i].alias === alias) { return scenes[i]; } } return null; }

	function render() {
		var cards = $("#postSceneCards").empty();
		$.each(scenes, function (i, sc) {
			var text = $('<div class="sceneCardText"></div>').append($('<strong></strong>').text(sc.name), $('<span></span>').text(sc.active ? "" : "Inactive: it won't show until it is made active."));
			var card = $('<button type="button" class="sceneCard"></button>').toggleClass("selected", sc.alias === picked).attr("aria-pressed", sc.alias === picked)
				.append(galaxieSceneCardThumb(sc.json, baseUrl), text);
			card.on("click", function () { picked = sc.alias; render(); });
			cards.append(card);
		});
		$("#postSceneEdit").toggle(!!sceneByAlias(picked));
		<!--- Save waits for a pick; Remove shows only when the post has a scene now. --->
		$("#postSceneSave").prop("disabled", !sceneByAlias(picked)).toggleClass("k-state-disabled", !sceneByAlias(picked));
		$("#postSceneRemove").toggle(!!current);
	}

	function reloadWithPick(alias) {
		window.galaxiePostScenePick = alias;
		try { $("#postSceneWindow").data("kendoWindow").refresh(); } catch (e) {}
	}
	<!--- The Scene editor announces each save; this window then lists that scene and picks it. --->
	$(document).off("galaxieSceneSaved.postScene").on("galaxieSceneSaved.postScene", function (event, saved) {
		if ($("#postSceneWindow").length) { reloadWithPick(saved && saved.alias ? saved.alias : picked); }
	});

	$("#postSceneNew").on("click", function () { createAdminInterfaceWindow(107, 0); });
	$("#postSceneEdit").on("click", function () { var sc = sceneByAlias(picked); if (sc) { createAdminInterfaceWindow(107, sc.id); } });

	$("#postSceneRemove").on("click", function () { saveScene(""); });
	$("#postSceneSave").on("click", function () { if (sceneByAlias(picked)) { saveScene(picked); } });

	function saveScene(alias) {
		$("#postSceneSave, #postSceneRemove").prop("disabled", true);
		jQuery.ajax({
			type: "post",
			url: baseUrl + "/common/cfc/ProxyController.cfc?method=setPostScene",
			data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: postId, alias: alias },
			dataType: "json",
			success: function (response) {
				$("#postSceneSave, #postSceneRemove").prop("disabled", false);
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) {
					var sc = sceneByAlias(alias);
					if (typeof galaxieHeroSummaryRefresh === "function") { galaxieHeroSummaryRefresh(); }
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: sc ? "The post shows " + $("<div/>").text(sc.name).html() + " at the top of its page." : "The scene was removed. The post shows its picture and text as usual.", icon: "k-ext-information" })).done(function () {
						$("#postSceneWindow").kendoWindow("destroy");
					});
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The scene could not be set.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			},
			error: function (jqXHR, textStatus, error) {
				$("#postSceneSave, #postSceneRemove").prop("disabled", false);
				if (jqXHR.status === 403) { createLoginWindow(); }
				else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
			}
		});
	}

	render();
});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<tr><td class="#blockClass#">A scene is shown at the top of this post's own page, above its text. Lists of posts still show the post's picture. Scenes look best with a modern theme and the sidebar hidden.</td></tr>
	<tr class="blockSpacer"><td class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
	<tr><td class="#blockClass#"><h4 class="adminBlockHeading">Pick a scene</h4></td></tr>
	<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#">
		<cfif not postSceneList.recordCount>
			<div>You haven't made a scene yet. Click New scene to make one from a ready-made scene; it is picked here when you save it.</div>
		</cfif>
			<div id="postSceneCards" class="sceneCards"></div>
		</td>
	</tr>
	<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#">
			<button id="postSceneSave" type="button" class="k-button k-primary">Save</button>
			<button id="postSceneNew" type="button" class="k-button">New scene</button>
			<button id="postSceneEdit" type="button" class="k-button" style="display: none;">Edit this scene</button>
			<button id="postSceneRemove" type="button" class="k-button" style="display: none;">Remove the scene</button>
		</td>
	</tr>
</table>
</cfoutput>

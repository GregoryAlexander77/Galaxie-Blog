<!--- Insert Scene window (window 122, 11-07, owner: "insert a scene using a post or a page", from the post's side, as Insert Form does).
Opened by the post editor's Insert > Scene. Picks one of the blog's scrolling scenes (never a moving hero, which belongs to its own
post) and puts it in the text (2026-11-08: a scene at the top is the Layout choice now, postKindRows.cfm), as a placeholder the post's own page swaps for the scene
(<div class="galaxieScene" data-scene="alias">[Scene: Name]</div>, Renderer.cfc renderInlineScenes; a link in feeds and emails,
WebForms.cfc replacePlaceholders). Make a new one opens the Scene wizard (window 121, "insert:{postId}"), which hands the new scene
back here (galaxieInsertSceneChosen) when it finishes. optArgs is the postId. --->
<cfsilent>
<cfset isPostId = val(URL.optArgs)>
<cfset isScenes = application.blog.getScenes()>
<cfset isList = queryFilter(isScenes.listScenes(), function (row) { return row.Active eq 1 and not reFindNoCase("^post-hero-[0-9]+$", row.Alias); })>
<cfset isParts = []>
<cfloop query="isList">
	<cfset isJson = isScenes.getSceneJson(isList.Alias, false)>
	<cfset arrayAppend(isParts, '{"alias":' & serializeJSON(toString(isList.Alias)) & ',"name":' & serializeJSON(toString(isList.Name)) & ',"json":' & (isJSON(isJson) ? isJson : '{}') & '}')>
</cfloop>
<cfset isScenesJson = replace(replace("[" & arrayToList(isParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")>
<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
</cfsilent>
<cfinclude template="sceneCards.cfm">
<style>
	#insertSceneWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
	.isNewCard .sceneCardThumb { display: flex; align-items: center; justify-content: center; font-size: 40px; background: transparent; border-bottom: 1px dashed rgba(128,128,128,.5); }
</style>
<cfoutput>
<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="#blockClass#">
		<strong>Goes in the text, where the cursor is.</strong> To make a scene the whole post, use the Layout choice at the top of this window.
		<div class="k-form-hint">One or two scenes in a post is plenty: each one adds to what the page has to load.</div>
	</td></tr>
	<tr><td class="#blockClass#">
		<strong>Which scene</strong>
		<div id="isCards" class="sceneCards"></div>
	</td></tr>
</table>
</cfoutput>
<script>
(function () {
	var BASE = "<cfoutput>#application.baseUrl#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	var POST_ID = <cfoutput>#isPostId#</cfoutput>;
	var SCENES = <cfoutput>#isScenesJson#</cfoutput>;
	var editor = window.tinymce ? tinymce.activeEditor : null;
	function esc(s) { return $("<div/>").text(String(s || "")).html(); }
	function closeWindow() { var w = $("#insertSceneWindow").data("kendoWindow"); if (w) { w.close(); } }
	function alertBox(title, message, icon) { $.when(kendo.ui.ExtAlertDialog.show({ title: title, message: message, icon: icon || "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }

	<!--- Put a scene in the text. Also called by the Scene wizard for a scene it just made. --->
	function place(alias, name) {
		if (!editor) { alertBox("No text to put it in", "Open the post's text first, then choose Insert, Scene."); return; }
		editor.insertContent('<div class="galaxieScene" data-scene="' + esc(alias) + '">[Scene: ' + esc(name) + ']</div><p>&nbsp;</p>');
		closeWindow();
	}
	window.galaxieInsertSceneChosen = function (alias, name) { place(alias, name); };

	var box = $("#isCards");
	var make = $('<button type="button" class="sceneCard isNewCard"></button>')
		.append('<div class="sceneCardThumb"><i class="fontAwesomeIcon fas fa-plus"></i></div>', $('<div class="sceneCardText"></div>').append("<strong>Make a new one</strong>", "<span>Opens the Scene wizard. When it's done, the new scene goes in the text.</span>"))
		.on("click", function () { createAdminInterfaceWindow(121, "insert:" + POST_ID); });
	box.append(make);
	$.each(SCENES, function (i, sc) {
		var card = $('<button type="button" class="sceneCard"></button>');
		card.append(galaxieSceneCardThumb(sc.json, BASE), $('<div class="sceneCardText"></div>').append($("<strong></strong>").text(sc.name), $("<span></span>").text("Click to put it in the post.")));
		card.on("click", function () { place(sc.alias, sc.name); });
		box.append(card);
	});
})();
</script>

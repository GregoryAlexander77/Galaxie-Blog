<!--- Themes (window 110, 2026-10-20, Galaxie 5): the old Themes & Content screen (themeSettings.cfm, 13 sections in one long
panel) split into five tabs - Themes (pick the theme in use), Customize (a theme's look, with a live preview of the site beside
it), Branding (the site's own pictures, the same in every theme), Content (the windows, menu, footer and sidebar pods) and Custom
code. Saved through ProxyController.cfc saveThemeEditor -> common/cfc/ThemeEditor.cfc. The preview is the real site in a frame:
each change is sent as a draft (kept in the session) and the frame reloads with ?previewTheme=<alias>&previewLook=1, so what the
owner sees is exactly what visitors will see once saved. The old screen (window 30) stays for settings not moved here yet. --->
<cfset themeEditorObj = application.blog.getThemeEditor()>
<cfset editorThemes = themeEditorObj.getThemeList()>
<cfset editorContent = themeEditorObj.getContentList()>
<cfset editorCode = themeEditorObj.getCustomCode()>
<cfset editorFonts = application.blog.getFont()>
<cfquery name="editorKendoThemes" datasource="#application.dsn#">
	SELECT KendoThemeId, KendoTheme, DarkTheme FROM KendoTheme ORDER BY KendoTheme
</cfquery>

<!--- The data for the script, with bracket keys so Adobe ColdFusion keeps their case. --->
<cfset themeKeys = "ThemeId,ThemeAlias,ThemeName,SelectedTheme,KendoThemeId,Breakpoint,ContentWidth,MainContainerWidth,SideBarContainerWidth,SiteOpacity,AlignBlogMenuWithBlogContent,StretchHeaderAcrossPage,FontId,FontSize,FontSizeMobile,MenuFontId,BlogNameFontId,BlogNameFontSize,BlogNameFontSizeMobile,BlogNameTextColor,DisplayBlogName,IncludeBackgroundImages,BlogBackgroundImage,BlogBackgroundImageMobile,BlogBackgroundColor,BlogBackgroundImagePosition,BlogBackgroundImageRepeat,HeaderBackgroundImage,HeaderBodyDividerImage,MenuBackgroundImage,TopMenuAlign,CoverKendoMenuWithMenuBackgroundImage,LogoImage,LogoImageMobile,DefaultLogoImageForSocialMediaShare,FooterImage,Font,FontType,MenuFont,MenuFontType,BlogNameFont,BlogNameFontType,DarkTheme">
<cfset themeData = []>
<cfloop array="#editorThemes#" index="thisTheme">
	<cfset row = {}>
	<cfloop list="#themeKeys#" index="thisKey">
		<cfset thisValue = thisTheme[thisKey] ?: "">
		<cfif isBoolean(thisValue) and not isNumeric(thisValue)><cfset thisValue = thisValue ? "1" : "0"></cfif>
		<cfset row[thisKey] = toString(thisValue)>
	</cfloop>
	<cfset arrayAppend(themeData, row)>
</cfloop>
<cfset kendoData = []>
<cfloop query="editorKendoThemes">
	<cfset arrayAppend(kendoData, { "id" = toString(editorKendoThemes.KendoThemeId), "name" = toString(editorKendoThemes.KendoTheme), "dark" = editorKendoThemes.DarkTheme eq 1 })>
</cfloop>
<!--- The fonts the themes use, so each card shows its own site name, menu and text fonts. --->
<cfset cardRenderer = createObject("component", application.rendererComponentPath)>
<cfset cardFontFaces = "">
<cfset cardFontsDone = {}>
<cfloop array="#editorThemes#" index="thisTheme">
	<cfloop list="Font,MenuFont,BlogNameFont" index="thisKey">
		<cfset thisValue = thisTheme[thisKey] ?: "">
		<cfif len(thisValue) and not structKeyExists(cardFontsDone, thisValue)>
			<cfset cardFontsDone[thisValue] = true>
			<cfset cardFontFaces = cardFontFaces & cardRenderer.getOverlayFontFaceStyle(thisValue)>
		</cfif>
	</cfloop>
</cfloop>
<cfset fontData = []>
<cfloop array="#editorFonts#" index="thisFont">
	<cfset arrayAppend(fontData, { "id" = toString(thisFont["FontId"]), "name" = toString(thisFont["Font"]) })>
</cfloop>
<cfset contentData = []>
<cfloop array="#editorContent#" index="thisContent">
	<cfset arrayAppend(contentData, { "name" = thisContent.name, "shown" = thisContent.shown ? true : false, "everyTheme" = thisContent.everyTheme ? true : false, "themeCount" = thisContent.themeCount })>
</cfloop>

<style>
	#themeEditor { display: flex; flex-direction: column; height: 100%; }
	#themeEditorTabs { flex: 0 0 auto; display: flex; flex-wrap: wrap; gap: 6px; padding: 8px 10px; }
	.themeEditorView { flex: 1 1 auto; min-height: 0; overflow: auto; padding: 12px 14px; display: none; }
	.themeEditorView.selected { display: block; }
	#themeEditorView-customize.selected { display: flex; overflow: hidden; padding: 0; }
	.themeEditorLead { margin: 0 0 12px; max-width: 900px; }
	.themeEditorNote { border: 1px solid rgba(128,128,128,.5); border-radius: 6px; padding: 8px 12px; margin: 0 0 14px; max-width: 900px; }
	.themeEditorGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(<cfif session.isMobile>220<cfelse>280</cfif>px, 1fr)); gap: 14px; }
	.themeCard { border: 1px solid rgba(128,128,128,.35); border-radius: 8px; overflow: hidden; display: flex; flex-direction: column; }
	.themeCard.inUse { border: 3px solid currentColor; }
	.themeCardPicture { height: 230px; background-size: cover; background-position: center; position: relative; background-color: #888; overflow: hidden; }
	.themeCardHeader { box-sizing: border-box; height: 34px; margin: 0 auto; background-size: cover; background-position: center; display: flex; align-items: center; gap: 6px; padding: 0 8px; overflow: hidden; white-space: nowrap; }
	.themeCardHeader img { max-height: 24px; max-width: 30%; }
	.themeCardName { font-size: 15px; line-height: 1; overflow: hidden; text-overflow: ellipsis; }
	.themeCardMenu { margin-left: auto; font-size: 10px; opacity: .9; }
	.themeCardBody { position: absolute; top: 34px; bottom: 0; display: flex; }
	.themeCardPosts, .themeCardSide { background: #fff; color: #222; padding: 7px 8px; overflow: hidden; }
	.themeCard.dark .themeCardPosts, .themeCard.dark .themeCardSide { background: #24262a; color: #e6e6e6; }
	.themeCardPosts { flex: 1 1 auto; }
	.themeCardSide { flex: 0 0 auto; border-left: 1px solid rgba(128,128,128,.25); }
	.themeCardFonts { margin-top: -4px; }
	.themeCardTitle { font-weight: bold; font-size: 13px; line-height: 1.2; margin-bottom: 4px; }
	.themeCardText1 { font-size: 10px; line-height: 1.4; }
	.themeCardPod { font-size: 9px; line-height: 1.35; margin-bottom: 6px; }
	.themeCardPod b { display: block; font-size: 10px; margin-bottom: 2px; }
	.themeCardPill { position: absolute; top: 40px; right: 8px; z-index: 2; padding: 2px 8px; border-radius: 10px; background: rgba(0,0,0,.65); color: #fff; font-size: 12px; font-weight: bold; }
	.themeCardText { padding: 8px 10px 10px; display: flex; flex-direction: column; gap: 8px; }
	.themeCardButtons { display: flex; gap: 6px; }
	.themeCardButtons .k-button { flex: 1 1 auto; min-width: 0; white-space: nowrap; padding-left: 6px; padding-right: 6px; }
	#themeLookPanel { flex: 0 0 <cfif session.isMobile>100%<cfelse>40%</cfif>; display: flex; flex-direction: column; min-width: 0; border-right: 1px solid rgba(128,128,128,.35); }
	#themeLookTop { flex: 0 0 auto; padding: 8px 10px; display: flex; flex-wrap: wrap; gap: 6px 10px; align-items: center; }
	#themeLookFields { flex: 1 1 auto; overflow-y: auto; overflow-x: hidden; }
	#themeLookFoot { flex: 0 0 auto; padding: 8px 10px; display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
	#themeLookPreview { flex: 1 1 auto; position: relative; min-width: 0; background: #2b2b2b; }
	#themeLookFrame { border: 0; width: 100%; height: 100%; background: #fff; }
	#themeLookLoading { position: absolute; top: 10px; right: 14px; padding: 3px 10px; border-radius: 10px; background: rgba(0,0,0,.65); color: #fff; font-size: 12px; display: none; }
	.themePicturePick { display: flex; flex-wrap: wrap; gap: 6px; }
	.themePicturePick button { width: 64px; height: 40px; padding: 0; border: 2px solid rgba(128,128,128,.35); border-radius: 4px; background-size: cover; background-position: center; background-color: transparent; cursor: pointer; font-size: 12px; }
	.themePicturePick button[aria-pressed="true"] { border-color: currentColor; border-width: 3px; }
	.brandCard { border: 1px solid rgba(128,128,128,.35); border-radius: 8px; padding: 12px; display: flex; flex-direction: column; gap: 8px; }
	.brandCardArt { height: 110px; display: flex; align-items: center; justify-content: center; border-radius: 6px; background: repeating-conic-gradient(#e6e8eb 0% 25%, #ffffff 0% 50%) 50% / 16px 16px; }
	.brandCardArt img { max-width: 90%; max-height: 96px; }
	.brandCardTitle { font-weight: bold; }
	.brandCardButtons { display: flex; flex-wrap: wrap; gap: 6px; }
	.contentStatus { font-weight: bold; }
	#themeEditorView-code textarea { width: 95%; font-family: Consolas, monospace; }
	@media (max-width: 900px) {
		#themeEditorView-customize.selected { flex-direction: column; overflow: auto; }
		#themeLookPanel { flex: 0 0 auto; border-right: 0; }
		#themeLookFields { overflow: visible; }
		#themeLookPreview { flex: 0 0 70vh; }
	}
</style>
<cfoutput>#cardFontFaces#</cfoutput>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfset altClass = HtmlUtilsObj.getKendoClass(blockClass)>
<cfoutput>
<div id="themeEditor">
	<div id="themeEditorTabs" class="#blockClass#" role="tablist">
		<button type="button" class="k-button themeEditorTab" data-view="themes">Themes</button>
		<button type="button" class="k-button themeEditorTab" data-view="customize">Customize</button>
		<button type="button" class="k-button themeEditorTab" data-view="branding">Branding</button>
		<button type="button" class="k-button themeEditorTab" data-view="content">Content</button>
		<button type="button" class="k-button themeEditorTab" data-view="code">Custom code</button>
		<span style="flex: 1 1 auto;"></span>
		<a href="##" id="themeEditorClassic" title="Every setting, in the old Themes screen">All settings (classic screen)</a>
	</div>

	<!--- Themes --->
	<div class="themeEditorView #altClass#" id="themeEditorView-themes">
		<p class="themeEditorLead">Pick how your site looks. Every theme uses your logo, your pictures and your content; Customize changes only that theme's look.</p>
		<div class="themeEditorNote" id="themeNoneNote" style="display: none;">No theme is chosen, so your site shows a different theme each day. Pick one with <b>Use this theme</b>.</div>
		<div class="themeEditorNote" id="themeOneNote" style="display: none;"><span id="themeOneNoteText"></span> <a href="##" id="themeUseNone">Show a different theme each day instead</a></div>
		<div class="themeEditorGrid" id="themeGallery"></div>
	</div>

	<!--- Customize: the settings on the left, the site on the right. --->
	<div class="themeEditorView" id="themeEditorView-customize">
		<div id="themeLookPanel" class="#altClass#">
			<div id="themeLookTop">
				<label for="themeLookTheme">Theme:</label>
				<select id="themeLookTheme" style="width: 220px;"></select>
				<span id="themeLookSections"></span>
			</div>
			<div id="themeLookFields"></div>
			<div id="themeLookFoot">
				<button type="button" class="k-button k-primary" id="themeLookSave">Save</button>
				<button type="button" class="k-button" id="themeLookUndo" title="Go back to this theme's saved look">Undo changes</button>
				<span class="k-form-hint" id="themeLookStatus"></span>
			</div>
		</div>
		<div id="themeLookPreview">
			<iframe id="themeLookFrame" title="Preview of your site"></iframe>
			<span id="themeLookLoading">Updating the preview...</span>
		</div>
	</div>

	<!--- Branding --->
	<div class="themeEditorView #altClass#" id="themeEditorView-branding">
		<p class="themeEditorLead">Your site's own pictures. They are the same in every theme, so you set them once.</p>
		<div class="themeEditorNote" id="brandMixedNote" style="display: none;">Your themes have different logos at the moment. A logo set here is used in every theme.</div>
		<div class="themeEditorGrid" id="brandGallery"></div>
	</div>

	<!--- Content --->
	<div class="themeEditorView #altClass#" id="themeEditorView-content">
		<p class="themeEditorLead">The words around your posts: the About and Bio windows, the footer, the menu and the boxes in the sidebar. Show or hide each one, and edit its text (for every theme, or only some).</p>
		<div class="themeEditorGrid" id="contentGallery"></div>
	</div>

	<!--- Custom code --->
	<div class="themeEditorView #altClass#" id="themeEditorView-code">
		<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
			<colgroup><col style="width: 20%"><col></colgroup>
			<tr><td colspan="2" class="#blockClass#"><b>For advanced use.</b> This code is added to every page of your site, in every theme. A mistake can break your site, so only add code you trust, such as an analytics, verification or chat snippet. It isn't added to the admin pages or to the preview here.</td></tr>
			<cfif not editorCode.same>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr><td colspan="2" class="#blockClass#">Your themes have different code at the moment. This shows the code of the theme in use; saving puts it in every theme.</td></tr>
			</cfif>
			<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
			<cfset codeClass = HtmlUtilsObj.getKendoClass(blockClass)>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr><td colspan="2" class="#codeClass#">In the page header, such as analytics or site verification tags.</td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr>
				<td class="#codeClass#" align="right"><label for="codeHead">Header:</label></td>
				<td class="#codeClass#"><textarea id="codeHead" class="k-textbox" rows="7" spellcheck="false" placeholder="<script>...</script>">#encodeForHtml(editorCode.head)#</textarea></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr><td colspan="2" class="#codeClass#">At the end of the page, such as a chat widget or a tracking pixel.</td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr>
				<td class="#codeClass#" align="right"><label for="codeTail">End of page:</label></td>
				<td class="#codeClass#"><textarea id="codeTail" class="k-textbox" rows="7" spellcheck="false" placeholder="<script>...</script>">#encodeForHtml(editorCode.tail)#</textarea></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="#codeClass#"></td></tr>
			<cfset codeClass = HtmlUtilsObj.getKendoClass(codeClass)>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr><td colspan="2" class="#codeClass#">The tags for the small icon in the browser tab (favicon). Upload the icon files on the Branding tab first; most favicon makers give you these tags.</td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr>
				<td class="#codeClass#" align="right"><label for="codeFavicon">Browser icon:</label></td>
				<td class="#codeClass#"><textarea id="codeFavicon" class="k-textbox" rows="5" spellcheck="false" placeholder="<link rel=&quot;icon&quot; ...>">#encodeForHtml(editorCode.favicon)#</textarea></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #codeClass#"></td></tr>
			<tr>
				<td class="#codeClass#"></td>
				<td class="#codeClass#"><button type="button" class="k-button k-primary" id="codeSave">Save</button></td>
			</tr>
		</table>
	</div>
</div>
</cfoutput>

<script>
$(function () {
	var BASE = "<cfoutput>#jsStringFormat(application.baseUrl)#</cfoutput>";
	var CSRF = "<cfoutput>#jsStringFormat(csrfToken)#</cfoutput>";
	var ALERT_WIDTH = "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>";
	var THEMES = <cfoutput>#serializeJSON(themeData)#</cfoutput>;
	var KENDO = <cfoutput>#serializeJSON(kendoData)#</cfoutput>;
	var FONTS = <cfoutput>#serializeJSON(fontData)#</cfoutput>;
	var CONTENT = <cfoutput>#serializeJSON(contentData)#</cfoutput>;
	var BLOCK = "<cfoutput>#blockClass#</cfoutput>", ALT = "<cfoutput>#altClass#</cfoutput>";

	function img(p) { return p ? (/^(https?:)?\/\//.test(p) || (BASE && p.indexOf(BASE + "/") === 0) ? p : BASE + p) : ""; }
	function bool(v) { return v === true || v === "1" || v === 1 || v === "true" || v === "YES" || v === "yes"; }
	function themeById(id) { return $.grep(THEMES, function (t) { return String(t.ThemeId) === String(id); })[0]; }
	function inUse() { return $.grep(THEMES, function (t) { return bool(t.SelectedTheme); })[0]; }
	function say(title, message, icon) { return $.when(kendo.ui.ExtAlertDialog.show({ title: title, message: message, icon: icon || "k-ext-information", width: ALERT_WIDTH })); }
	function post(action, data, done, fail) {
		jQuery.ajax({
			type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=saveThemeEditor",
			data: $.extend({ csrfToken: CSRF, action: action }, data), dataType: "json",
			success: function (response) {
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) { done(response); }
				else { if (fail) { fail(); } say("Could not save", (response && response.errorMessage) || "This could not be saved.", "k-ext-warning"); }
			},
			error: function (jqXHR, textStatus, error) {
				if (fail) { fail(); }
				if (jqXHR.status === 403) { createLoginWindow(); } else { say("Error while saving", error, "k-ext-error"); }
			}
		});
	}
	function readFile(input, done) {
		var file = input.files && input.files[0];
		input.value = "";
		if (!file) { return; }
		if (!/^image\/(png|gif|jpeg|webp|svg\+xml)$/.test(file.type)) { say("Not a picture", "Please pick a PNG, GIF, JPG, WebP or SVG picture.", "k-ext-warning"); return; }
		var reader = new FileReader();
		reader.onload = function () { done(reader.result); };
		reader.readAsDataURL(file);
	}

	// ---------- tabs ----------
	function showView(name) {
		$(".themeEditorView").removeClass("selected");
		$("#themeEditorView-" + name).addClass("selected");
		$(".themeEditorTab").removeClass("k-primary").attr("aria-pressed", "false").filter("[data-view=" + name + "]").addClass("k-primary").attr("aria-pressed", "true");
		if (name === "customize" && !current) { startCustomize((inUse() || THEMES[0]).ThemeId); }
	}
	$(".themeEditorTab").on("click", function () { showView($(this).data("view")); });
	$("#themeEditorClassic").on("click", function (e) { e.preventDefault(); createAdminInterfaceWindow(29); });

	// ---------- Themes ----------
	function drawGallery() {
		var used = inUse(), box = $("#themeGallery").empty();
		$("#themeNoneNote").toggle(!used);
		$("#themeOneNote").toggle(!!used);
		if (used) { $("#themeOneNoteText").text(used.ThemeName + " is your site's theme."); }
		$.each(THEMES, function (i, t) {
			var isUsed = used && used.ThemeId === t.ThemeId, kendoTheme = kendoById(t.KendoThemeId);
			var card = $('<div class="themeCard"></div>').toggleClass("inUse", !!isUsed).toggleClass("dark", !!(kendoTheme && kendoTheme.dark));
			var picture = $('<div class="themeCardPicture"></div>').css("background-image", bool(t.IncludeBackgroundImages) && t.BlogBackgroundImage ? 'url("' + img(t.BlogBackgroundImage) + '")' : "none")
				.css("background-color", t.BlogBackgroundColor || "#888").append(themeCardPage(t));
			if (isUsed) { picture.append('<span class="themeCardPill">In use</span>'); }
			var buttons = $('<div class="themeCardButtons"></div>');
			buttons.append($('<button type="button" class="k-button"></button>').text(isUsed ? "In use" : "Use this theme").prop("disabled", !!isUsed).on("click", function () { useTheme(t); }));
			buttons.append($('<button type="button" class="k-button">Customize</button>').on("click", function () { startCustomize(t.ThemeId); showView("customize"); }));
			var fonts = $('<div class="themeCardFonts k-form-hint"></div>').append(
				$("<span></span>").text("Header: " + (t.BlogNameFont || "default")).css("font-family", fontCss(t.BlogNameFont, t.BlogNameFontType)), " · ",
				$("<span></span>").text("Body: " + (t.Font || "default")).css("font-family", fontCss(t.Font, t.FontType)));
			card.append(picture, $('<div class="themeCardText"></div>').append($("<b></b>").text(t.ThemeName), fonts, buttons));
			box.append(card);
		});
	}
	// A small picture of a page in the theme: the header ribbon with the logo, site name (in its font and color) and menu, then
	// the content box straight under it - a post in the text font, and the sidebar on a classic (not modern) theme.
	var SITE_NAME = "<cfoutput>#jsStringFormat(application.BlogDbObj.getBlogTitle())#</cfoutput>";
	function fontCss(name, type) { return name ? "'" + name.replace(/'/g, "") + "'" + (type ? ", " + type : "") : "inherit"; }
	function themeCardPage(t) {
		var width = Math.max(40, Math.min(100, parseInt(t.ContentWidth, 10) || 60)), classic = String(t.Breakpoint) !== "0";
		if (classic) { width = Math.max(width, 80); }
		var left = (100 - width) / 2, opacity = Math.max(0.5, Math.min(1, (parseInt(t.SiteOpacity, 10) || 99) / 100));
		var header = $('<div class="themeCardHeader"></div>').css({ "background-image": t.HeaderBackgroundImage ? 'url("' + img(t.HeaderBackgroundImage) + '")' : "none", width: width + "%" });
		if (t.LogoImage) { header.append($('<img alt="">').attr("src", img(t.LogoImage))); }
		if (bool(t.DisplayBlogName)) { header.append($('<span class="themeCardName"></span>').text(SITE_NAME).css({ "font-family": fontCss(t.BlogNameFont, t.BlogNameFontType), color: t.BlogNameTextColor || "#fff" })); }
		header.append($('<span class="themeCardMenu">Menu &nbsp; About &nbsp; Themes</span>').css({ "font-family": fontCss(t.MenuFont, t.MenuFontType), color: t.BlogNameTextColor || "#fff" }));
		var body = $('<div class="themeCardBody"></div>').css({ left: left + "%", right: left + "%", opacity: opacity, "font-family": fontCss(t.Font, t.FontType) });
		body.append($('<div class="themeCardPosts"></div>').append(
			$('<div class="themeCardTitle">Lorem ipsum dolor sit amet</div>').css("font-family", fontCss(t.BlogNameFont, t.BlogNameFontType)),
			$('<div class="themeCardText1">Consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</div>')));
		if (classic) {
			var side = Math.max(20, Math.min(45, parseInt(t.SideBarContainerWidth, 10) || 35));
			body.append($('<div class="themeCardSide"></div>').css("width", side + "%").append(
				'<div class="themeCardPod"><b>Categories</b>Lorem<br>Ipsum<br>Dolor</div>',
				'<div class="themeCardPod"><b>Recent posts</b>Sit amet<br>Consectetur</div>'));
		}
		return [header, body];
	}
	function setInUse(themeId) { $.each(THEMES, function (i, t) { t.SelectedTheme = String(t.ThemeId) === String(themeId) ? "1" : "0"; }); drawGallery(); drawBranding(); }
	function useTheme(t) {
		post("use", { themeId: t.ThemeId }, function () { setInUse(t.ThemeId); say("Theme changed", t.ThemeName + " is now your site's theme."); });
	}
	$("#themeUseNone").on("click", function (e) {
		e.preventDefault();
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Change theme each day?", message: "Your site will show a different theme each day until you pick one again.", icon: "k-ext-question", width: ALERT_WIDTH })).done(function (answer) {
			if (answer['button'] === 'Yes') { post("use", { themeId: 0 }, function () { setInUse(0); }); }
		});
	});
	function kendoById(id) { return $.grep(KENDO, function (k) { return String(k.id) === String(id); })[0]; }
	function kendoLabel(k) {
		var names = { black: "Black", blueopal: "Blue Opal", bootstrap: "Bootstrap", "default": "Default", flat: "Flat", highcontrast: "High Contrast", material: "Material", materialblack: "Material Black", metro: "Metro", metroblack: "Metro Black", moonlight: "Moonlight", nova: "Nova", office365: "Office 365", silver: "Silver", uniform: "Uniform", fiori: "Fiori" };
		return (names[k.name] || k.name) + (k.dark ? " (dark)" : "");
	}

	// ---------- Customize ----------
	var current = null, saved = null, unsaved = false, draftTimer = null, frameScroll = 0;
	var SECTIONS = [["layout", "Layout"], ["fonts", "Fonts and name"], ["backgrounds", "Background"], ["header", "Header and menu"]];
	var section = "layout";
	// Pictures already used by any theme, offered for each picture setting.
	function picturesFor(keys) {
		var list = [];
		$.each(THEMES, function (i, t) { $.each(keys, function (j, k) { if (t[k] && list.indexOf(t[k]) < 0) { list.push(t[k]); } }); });
		return list;
	}
	var PICTURES = {
		BlogBackgroundImage: picturesFor(["BlogBackgroundImage", "BlogBackgroundImageMobile"]),
		BlogBackgroundImageMobile: picturesFor(["BlogBackgroundImageMobile", "BlogBackgroundImage"]),
		HeaderBackgroundImage: picturesFor(["HeaderBackgroundImage"]),
		MenuBackgroundImage: picturesFor(["MenuBackgroundImage"]),
		HeaderBodyDividerImage: picturesFor(["HeaderBodyDividerImage"])
	};

	var themePicker = $("#themeLookTheme").kendoDropDownList({
		dataTextField: "ThemeName", dataValueField: "ThemeId", dataSource: THEMES,
		change: function () { var id = this.value(); if (current && String(id) !== String(current.ThemeId)) { switchTheme(id); } }
	}).data("kendoDropDownList");
	$.each(SECTIONS, function (i, s) {
		$("#themeLookSections").append($('<button type="button" class="k-button themeLookSection"></button>').attr("data-section", s[0]).text(s[1]).on("click", function () { section = s[0]; drawFields(); }));
	});
	function switchTheme(id) {
		if (!unsaved) { startCustomize(id); return; }
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Leave without saving?", message: "Your changes to " + current.ThemeName + " haven't been saved.", icon: "k-ext-question", width: ALERT_WIDTH })).done(function (answer) {
			if (answer['button'] === 'Yes') { startCustomize(id); } else { themePicker.value(current.ThemeId); }
		});
	}
	function startCustomize(id) {
		var t = themeById(id) || THEMES[0];
		saved = $.extend({}, t);
		current = $.extend({}, t);
		setUnsaved(false);
		themePicker.value(t.ThemeId);
		drawFields();
		sendDraft(true);
	}
	function setUnsaved(on) {
		unsaved = on;
		$("#themeLookStatus").text(on ? "Not saved yet. The preview shows your changes; visitors still see the saved look." : "");
		$("#themeLookUndo").prop("disabled", !on);
	}
	function change(key, value) {
		current[key] = value;
		setUnsaved(true);
		clearTimeout(draftTimer);
		draftTimer = setTimeout(function () { sendDraft(false); }, 500);
	}
	// The look as the server takes it: only the editable settings.
	var LOOK_KEYS = ["KendoThemeId", "Breakpoint", "ContentWidth", "MainContainerWidth", "SideBarContainerWidth", "SiteOpacity", "AlignBlogMenuWithBlogContent", "StretchHeaderAcrossPage", "FontId", "FontSize", "FontSizeMobile", "MenuFontId", "BlogNameFontId", "BlogNameFontSize", "BlogNameFontSizeMobile", "BlogNameTextColor", "DisplayBlogName", "IncludeBackgroundImages", "BlogBackgroundImage", "BlogBackgroundImageMobile", "BlogBackgroundColor", "BlogBackgroundImagePosition", "BlogBackgroundImageRepeat", "HeaderBackgroundImage", "HeaderBodyDividerImage", "MenuBackgroundImage", "TopMenuAlign", "CoverKendoMenuWithMenuBackgroundImage"];
	function lookJson() {
		var look = {};
		$.each(LOOK_KEYS, function (i, k) { var v = current[k]; look[k] = (v === undefined || v === null) ? "" : String(v); });
		return JSON.stringify(look);
	}
	function sendDraft(fresh) {
		$("#themeLookLoading").show();
		post("draft", { themeId: current.ThemeId, look: lookJson() }, function () { loadPreview(fresh); }, function () { $("#themeLookLoading").hide(); });
	}
	var frame = document.getElementById("themeLookFrame");
	function loadPreview(fresh) {
		try { frameScroll = fresh ? 0 : (frame.contentWindow.scrollY || 0); } catch (e) { frameScroll = 0; }
		$("#themeLookLoading").show();
		frame.src = BASE + "/index.cfm?previewTheme=" + encodeURIComponent(current.ThemeAlias) + "&previewLook=1&t=" + Date.now();
	}
	frame.addEventListener("load", function () {
		$("#themeLookLoading").hide();
		try { if (frameScroll) { frame.contentWindow.scrollTo(0, frameScroll); } } catch (e) {}
	});

	// Field builders: a row in the owner's admin table layout - label on the left, the control, an optional hint.
	var table, rowClass;
	function startTable() {
		rowClass = BLOCK;   // the first block k-content, then k-alt (owner, 10-20)
		table = $('<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed"><colgroup><col style="width: 30%"><col></colgroup></table>');
		$("#themeLookFields").empty().append(table);
	}
	function spacer(border) { table.append($('<tr class="blockSpacer"><td colspan="2"></td></tr>').find("td").addClass((border ? "border " : "") + rowClass).end()); }
	function heading(text) {
		if (table.find("tr").length) { spacer(false); rowClass = rowClass === ALT ? BLOCK : ALT; }
		spacer(true);
		table.append($("<tr></tr>").append($('<td colspan="2"></td>').addClass(rowClass).append($('<h4 class="adminBlockHeading"></h4>').text(text))));
	}
	function note(text) { spacer(true); table.append($("<tr></tr>").append($('<td colspan="2"></td>').addClass(rowClass).text(text))); }
	function row(label, control, hint, rowId) {
		spacer(true);
		var cell = $("<td></td>").addClass(rowClass).append(control);
		if (hint) { cell.append(" ", $('<span class="k-form-hint"></span>').text(hint)); }
		var tr = $("<tr></tr>").append($('<td align="right"></td>').addClass(rowClass).append(label ? $("<label></label>").text(label + ":") : ""), cell);
		if (rowId) { tr.addClass(rowId); table.find("tr.blockSpacer:last").addClass(rowId); }
		table.append(tr);
		return tr;
	}
	function number(key, min, max, unit) {
		return $("<span></span>").append($('<input type="number" class="k-textbox" style="width: 80px;">').attr({ min: min, max: max, step: 1 }).val(current[key]).on("change", function () {
			var v = parseInt(this.value, 10);
			if (isNaN(v)) { v = parseInt(saved[key], 10) || min; }
			v = Math.max(min, Math.min(max, v));
			this.value = v;
			change(key, String(v));
			if (key === "MainContainerWidth" || key === "SideBarContainerWidth") {
				var other = key === "MainContainerWidth" ? "SideBarContainerWidth" : "MainContainerWidth";
				current[other] = String(100 - v);
				$("input[data-key=" + other + "]").val(current[other]);
			}
		}).attr("data-key", key), unit ? " " + unit : "");
	}
	function checkbox(key, text) {
		var id = "themeLook" + key;
		return $("<span></span>").append($('<input type="checkbox" class="k-checkbox">').attr("id", id).prop("checked", bool(current[key])).on("change", function () { change(key, this.checked ? "1" : "0"); }),
			$("<label></label>").attr("for", id).addClass("k-checkbox-label").text(" " + text));
	}
	function choice(key, options, onChange) {
		var s = $('<select style="width: 95%;"></select>');
		$.each(options, function (i, o) { s.append($("<option></option>").attr("value", o[0]).text(o[1])); });
		s.val(current[key] || options[0][0]);
		setTimeout(function () { s.kendoDropDownList({ change: function () { change(key, this.value()); if (onChange) { onChange(this.value()); } } }); }, 0);
		return s;
	}
	function fontChoice(key) {
		var s = $('<select style="width: 95%;"></select>');
		setTimeout(function () { s.kendoDropDownList({ dataTextField: "name", dataValueField: "id", dataSource: FONTS, filter: "contains", value: current[key], change: function () { change(key, this.value()); } }); }, 0);
		return s;
	}
	function colour(key, allowNone) {
		var box = $("<span></span>"), input = $("<input>");
		box.append(input);
		setTimeout(function () {
			var picker = input.kendoColorPicker({ value: current[key] || null, buttons: false, preview: true, input: true, change: function () { change(key, this.value() || ""); } }).data("kendoColorPicker");
			if (allowNone) { box.append(" ", $('<a href="#">None</a>').on("click", function (e) { e.preventDefault(); picker.value(null); change(key, ""); })); }
		}, 0);
		return box;
	}
	function pictures(key, allowNone) {
		var box = $('<div class="themePicturePick"></div>'), showAll = false;
		function draw() {
			box.empty();
			if (allowNone) {
				box.append($('<button type="button">None</button>').attr("aria-pressed", current[key] ? "false" : "true").on("click", function () { change(key, ""); draw(); }));
			}
			// The picture in use first, then the rest; a long list shows a dozen until Show all.
			var list = PICTURES[key].slice(0);
			if (current[key] && list.indexOf(current[key]) > 0) { list.splice(list.indexOf(current[key]), 1); list.unshift(current[key]); }
			$.each(showAll ? list : list.slice(0, 12), function (i, p) {
				box.append($('<button type="button"></button>').css("background-image", 'url("' + img(p) + '")').attr({ "aria-pressed": p === current[key] ? "true" : "false", title: p.split("/").pop() })
					.on("click", function () { change(key, p); draw(); }));
			});
			if (!showAll && list.length > 12) {
				box.append($('<button type="button"></button>').text("Show all " + list.length).on("click", function () { showAll = true; draw(); }));
			}
		}
		draw();
		var file = $('<input type="file" accept="image/png,image/gif,image/jpeg,image/webp,image/svg+xml" style="display: none;">').on("change", function () {
			readFile(this, function (dataUrl) {
				$("#themeLookLoading").text("Uploading...").show();
				post("picture", { field: key, dataUrl: dataUrl }, function (response) {
					$("#themeLookLoading").text("Updating the preview...");
					if (PICTURES[key].indexOf(response.path) < 0) { PICTURES[key].push(response.path); }
					change(key, response.path); draw();
				}, function () { $("#themeLookLoading").text("Updating the preview...").hide(); });
			});
		});
		var upload = $('<button type="button" class="k-button k-primary" style="margin-top: 6px;">Upload your own...</button>').on("click", function () { file.trigger("click"); });
		return $("<div></div>").append(box, file, upload);
	}

	function drawFields() {
		$(".themeLookSection").removeClass("k-primary").filter("[data-section=" + section + "]").addClass("k-primary");
		startTable();
		if (section === "layout") {
			heading("Style");
			row("Kendo style", choice("KendoThemeId", $.map(KENDO, function (k) { return [[k.id, kendoLabel(k)]]; })));
			note("The colors of the buttons, windows and menus. A dark style suits a dark background.");
			heading("Layout");
			row("Layout", choice("Breakpoint", [["0", "Modern: no sidebar (it opens from the menu)"], ["1300", "Classic: a sidebar on the right"]], function (v) { $(".themeLookColumns").toggle(v !== "0"); }));
			row("Content width", number("ContentWidth", 30, 100, "%"), "Aimed at screens 1700 to 1920 pixels wide.");
			row("Posts column", number("MainContainerWidth", 40, 85, "%"), "", "themeLookColumns");
			row("Sidebar column", number("SideBarContainerWidth", 15, 60, "%"), "", "themeLookColumns");
			$(".themeLookColumns").toggle(String(current.Breakpoint) !== "0");
			row("Opacity", number("SiteOpacity", 75, 100, "%"), "100 is solid. Lower lets the background show through.");
			row("", checkbox("AlignBlogMenuWithBlogContent", "Line the menu up with the posts"));
		} else if (section === "fonts") {
			heading("Text");
			row("Font", fontChoice("FontId"));
			row("Size", number("FontSize", 8, 24, "pt"));
			row("Size on mobile", number("FontSizeMobile", 8, 24, "pt"));
			heading("Menu");
			row("Font", fontChoice("MenuFontId"));
			heading("Site name");
			row("", checkbox("DisplayBlogName", "Show the site name beside the logo"));
			row("Font", fontChoice("BlogNameFontId"));
			row("Size", number("BlogNameFontSize", 12, 80, "px"));
			row("Size on mobile", number("BlogNameFontSizeMobile", 10, 60, "px"));
			row("Color", colour("BlogNameTextColor", false), "The menu text uses it too.");
		} else if (section === "backgrounds") {
			heading("Background");
			row("", checkbox("IncludeBackgroundImages", "Show a background picture"));
			row("Picture", pictures("BlogBackgroundImage", false));
			row("On mobile", pictures("BlogBackgroundImageMobile", false));
			row("Position", choice("BlogBackgroundImagePosition", [["center center", "Centre"], ["50% 25%", "A little above the centre"], ["center top", "Top"], ["center bottom", "Bottom"], ["left top", "Top left"], ["left bottom", "Bottom left"]]));
			row("Repeat", choice("BlogBackgroundImageRepeat", [["no-repeat", "Don't repeat (fill the page)"], ["repeat", "Tile it"], ["repeat-x", "Repeat across"], ["repeat-y", "Repeat down"]]));
			row("Color", colour("BlogBackgroundColor", true), "Used when there's no background picture.");
		} else {
			heading("Header");
			row("Picture", pictures("HeaderBackgroundImage", true));
			row("Divider", pictures("HeaderBodyDividerImage", true), "The line under the header.");
			row("", checkbox("StretchHeaderAcrossPage", "Stretch the header across the page"));
			heading("Menu");
			row("Picture", pictures("MenuBackgroundImage", true));
			row("", checkbox("CoverKendoMenuWithMenuBackgroundImage", "Cover the whole menu with the menu picture"));
			row("Position", choice("TopMenuAlign", [["left", "Left"], ["center", "Centre"], ["right", "Right"]]));
		}
		spacer(false);
	}
	$("#themeLookSave").on("click", function () {
		var button = $(this).prop("disabled", true);
		post("look", { themeId: current.ThemeId, look: lookJson() }, function () {
			button.prop("disabled", false);
			var t = themeById(current.ThemeId);
			$.extend(t, current);
			saved = $.extend({}, current);
			setUnsaved(false);
			$("#themeLookStatus").text("Saved.");
			drawGallery();
			loadPreview(false);
		}, function () { button.prop("disabled", false); });
	});
	$("#themeLookUndo").on("click", function () {
		current = $.extend({}, saved);
		setUnsaved(false);
		drawFields();
		sendDraft(false);
	});

	// ---------- Branding ----------
	var BRAND = [
		["logo", "LogoImage", "Logo", "At the top of every page. A wide picture works best, about 300 by 80 pixels."],
		["logoMobile", "LogoImageMobile", "Logo on mobile", "A smaller or square version for small screens."],
		["social", "DefaultLogoImageForSocialMediaShare", "Picture for social media", "Shown when a post without its own picture is shared: 1200 by 630 pixels."],
		["footer", "FooterImage", "Footer picture", "At the bottom of every page."]
	];
	function drawBranding() {
		var source = inUse() || THEMES[0], box = $("#brandGallery").empty();
		var logos = {};
		$.each(THEMES, function (i, t) { logos[t.LogoImage] = true; });
		$("#brandMixedNote").toggle(Object.keys(logos).length > 1);
		$.each(BRAND, function (i, b) {
			var art = $('<div class="brandCardArt"></div>'), value = source[b[1]];
			if (value) { art.append($('<img alt="">').attr("src", img(value))); } else { art.append($('<span class="k-form-hint">None</span>')); }
			var file = $('<input type="file" accept="image/png,image/gif,image/jpeg,image/webp,image/svg+xml" style="display: none;">').on("change", function () {
				readFile(this, function (dataUrl) { saveBrand(b, dataUrl); });
			});
			var buttons = $('<div class="brandCardButtons"></div>').append(file,
				$('<button type="button" class="k-button">Change</button>').on("click", function () { file.trigger("click"); }));
			if (value) { buttons.append($('<button type="button" class="k-button">Remove</button>').on("click", function () { saveBrand(b, ""); })); }
			if (b[0] === "logo") { buttons.append($('<button type="button" class="k-button" title="The Site Setup wizard\'s logo maker">Make one from my site name</button>').on("click", function () { window.location.href = BASE + "/admin/setup.cfm"; })); }
			box.append($('<div class="brandCard"></div>').append(art, $('<div class="brandCardTitle"></div>').text(b[2]), $("<div></div>").text(b[3]), buttons));
		});
		var iconFile = $('<div class="brandCard"></div>').append($('<div class="brandCardArt"></div>').append($('<img alt="" style="width: 48px; height: 48px;">').attr("src", BASE + "/favicon.ico").on("error", function () { $(this).replaceWith('<span class="k-form-hint">None</span>'); })),
			$('<div class="brandCardTitle">Browser icon (favicon)</div>'), $("<div></div>").text("The small icon in the browser tab. Upload the files a favicon maker gives you, then add its tags on the Custom code tab."),
			$('<div class="brandCardButtons"></div>').append($('<button type="button" class="k-button">Upload icon files</button>').on("click", function () { createAdminInterfaceWindow(36, 'favIconUploader'); }),
				$('<button type="button" class="k-button">Icon tags</button>').on("click", function () { showView("code"); $("#codeFavicon").trigger("focus"); })));
		box.append(iconFile);
	}
	function saveBrand(b, dataUrl) {
		post("brand", { kind: b[0], dataUrl: dataUrl }, function (response) {
			var path = response.url ? response.url.replace(new RegExp("^" + BASE.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")), "") : "";
			$.each(THEMES, function (i, t) { t[b[1]] = path; });
			drawBranding(); drawGallery();
			say("Saved", dataUrl ? "The new " + b[2].toLowerCase() + " is used in every theme." : "The " + b[2].toLowerCase() + " was removed from every theme.");
		});
	}

	// ---------- Content ----------
	var CONTENT_NAMES = {
		aboutWindow: ["About window", "Who you are and what the site is about."],
		bioWindow: ["Bio window", "Your photo, links and a few lines about you."],
		downloadWindow: ["Download window", "The Download page in the menu."],
		compositeFooter: ["Footer", "The bottom of every page."],
		navigationMenu: ["Menu", "The links in the top menu. Their order is in Configure Menu."],
		subscribePod: ["Sidebar: Subscribe", ""], recentPostsPod: ["Sidebar: Recent posts", ""], recentCommentsPod: ["Sidebar: Recent comments", ""],
		categoriesPod: ["Sidebar: Categories", ""], monthlyArchivesPod: ["Sidebar: Monthly archives", ""], blogPostCalendarPod: ["Sidebar: Calendar", "Nothing to edit; show or hide it."],
		upcomingEventsPod: ["Sidebar: Upcoming events", ""], downloadPod: ["Sidebar: Download", ""], cfblogsFeedPod: ["Sidebar: CfBlogs feed", "Posts from other ColdFusion blogs."]
	};
	function drawContent() {
		var box = $("#contentGallery").empty(), themeForEdit = (inUse() || THEMES[0]).ThemeId;
		$.each(CONTENT, function (i, c) {
			var label = CONTENT_NAMES[c.name] || [c.name, ""], id = "contentShown" + c.name;
			var status = c.everyTheme ? "Your own text, every theme" : (c.themeCount ? "Your own text in " + c.themeCount + (c.themeCount > 1 ? " themes" : " theme") : "Built-in text");
			var card = $('<div class="brandCard"></div>').append($('<div class="brandCardTitle"></div>').text(label[0]));
			if (label[1]) { card.append($("<div></div>").text(label[1])); }
			if (c.name !== "blogPostCalendarPod") { card.append($('<div class="contentStatus"></div>').text(status)); }
			var shown = $('<input type="checkbox" class="k-checkbox">').attr("id", id).prop("checked", c.shown).on("change", function () {
				var box = this, on = this.checked;
				post("shown", { name: c.name, shown: on }, function () { c.shown = on; }, function () { box.checked = !on; });
			});
			var buttons = $('<div class="brandCardButtons" style="align-items: center;"></div>').append(shown, $('<label class="k-checkbox-label"></label>').attr("for", id).text(" Show"));
			if (c.name !== "blogPostCalendarPod") {
				buttons.append($('<button type="button" class="k-button">Edit</button>').on("click", function () { createAdminInterfaceWindow(53, themeForEdit, c.name + 'Desktop', false); }));
				buttons.append($('<button type="button" class="k-button">Mobile version</button>').on("click", function () { createAdminInterfaceWindow(53, themeForEdit, c.name + 'Mobile', true); }));
			}
			box.append(card.append(buttons));
		});
	}

	// ---------- Custom code ----------
	$("#codeSave").on("click", function () {
		var button = $(this).prop("disabled", true);
		post("code", { head: bypassScriptProtection($("#codeHead").val()), tail: bypassScriptProtection($("#codeTail").val()), favicon: bypassScriptProtection($("#codeFavicon").val()) },
			function () { button.prop("disabled", false); say("Saved", "Your custom code is saved in every theme."); }, function () { button.prop("disabled", false); });
	});

	// ---------- start ----------
	drawGallery();
	drawBranding();
	drawContent();
	showView("themes");

	// The window fills its Kendo window; closing with unsaved look changes asks first (as the scene editor does).
	function fit() { var content = $("#themeEditorWindow"); if (content.length) { $("#themeEditor").height(content.height()); } }
	fit();
	var kendoWindow = $("#themeEditorWindow").data("kendoWindow");
	if (kendoWindow) {
		kendoWindow.bind("resize", fit);
		kendoWindow.unbind("close");
		kendoWindow.bind("close", function (e) {
			if (unsaved) {
				e.preventDefault();
				$.when(kendo.ui.ExtYesNoDialog.show({ title: "Close without saving?", message: "Your changes to " + current.ThemeName + " haven't been saved.", icon: "k-ext-question", width: ALERT_WIDTH })).done(function (answer) {
					if (answer['button'] === 'Yes') { unsaved = false; kendoWindow.close(); }
				});
				return;
			}
			setTimeout(function () { var w = $("#themeEditorWindow").data("kendoWindow"); if (w) { w.destroy(); } }, 0);
		});
	}
});
</script>

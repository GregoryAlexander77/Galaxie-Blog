<!--- A post's hero text (window 109, 2026-10-19, Galaxie 5): the heading and second line over the post's image, gradient or
animated hero, with its color, font, sizes and a shadow or glow. Opened with the Hero text button in the post editor:
createAdminInterfaceWindow(109, postId). Saved by ProxyController.cfc savePostHeroText -> blog.cfc savePostHeroText. The same
text shows in both post hero styles (Blog Options: classic or scene). Carousels have their own text (carousel window); maps
and videos have none. --->
<cfset heroTextPost = application.blog.getPostByPostId(val(URL.optArgs), true, true)>
<cfif not arrayLen(heroTextPost)>
	<p>This post no longer exists.</p>
	<cfexit>
</cfif>
<cfset p = heroTextPost[1]>
<!--- Which hero the post shows, in the order the post page picks it (Renderer.cfc renderEnclosure). --->
<cfset heroKind = "none">
<cfif len(p["MediaUrl"] ?: "")><cfset heroKind = (p["MediaType"] ?: "") eq "Video" ? "video" : "image">
<cfelseif val(p["EnclosureCarouselId"] ?: 0)><cfset heroKind = "carousel">
<cfelseif val(p["EnclosureMapId"] ?: 0)><cfset heroKind = "map">
<cfelseif len(p["HeroGradient"] ?: "")><cfset heroKind = "gradient">
<cfelseif len(p["HeroAnimationEffect"] ?: "")><cfset heroKind = "animation">
</cfif>
<!--- The preview's background: the post's own picture or gradient, or a plain dark one. --->
<cfset previewBackground = heroKind eq "image" ? "url('" & encodeForCss(p["MediaUrl"]) & "') center / cover" : (heroKind eq "gradient" ? p["HeroGradient"] : "linear-gradient(135deg, ##1d4350 0%, ##392630 100%)")>
<cfset heroFonts = application.blog.getFont()>
<cfset heroFontCss = "">
<cfset heroFontExt = application.serverSupportsWoff2 ? "woff2" : "woff">
<cfloop array="#heroFonts#" index="thisFont">
	<cfif not (isBoolean(thisFont["WebSafeFont"] ?: "") and thisFont["WebSafeFont"]) and len(thisFont["FileName"] ?: "")>
		<cfset heroFontCss = heroFontCss & '@font-face{font-family:"' & replace(thisFont["Font"], '"', '', 'all') & '";src:url(' & application.baseUrl & '/common/fonts/' & thisFont["FileName"] & '.' & heroFontExt & ') format("' & heroFontExt & '");font-display:swap;}'>
	</cfif>
</cfloop>

<style>
	<cfoutput>#heroFontCss#</cfoutput>
	#heroTextPreview { position: relative; height: 220px; border-radius: 6px; overflow: hidden; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 16px; box-sizing: border-box; }
	#heroTextPreviewHeading { font-weight: bold; line-height: 1.15; }
	#heroTextPreviewSub { margin-top: .4em; }
</style>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">
	<cfswitch expression="#heroKind#">
		<cfcase value="carousel">This post's hero is a carousel. Its text (titles, fonts, colors and shadow) is set in the carousel window instead; the text below is kept for if the hero changes.</cfcase>
		<cfcase value="map">This post's hero is a map, which doesn't show text. The text below is kept for if the hero changes.</cfcase>
		<cfcase value="video">This post's hero is a video, which doesn't show text. The text below is kept for if the hero changes.</cfcase>
		<cfcase value="none">This post has no hero picture, gradient or animation yet. The text shows once it has one (or over the generated hero, when Blog Options shows one).</cfcase>
		<cfdefaultcase>The heading and second line over this post's #heroKind eq "animation" ? "animated" : heroKind# hero. Leave the heading empty for no text.</cfdefaultcase>
	</cfswitch>
	How the whole hero shows (classic, full screen, tall band or magazine) is chosen in the Hero editor.
	</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">
		<div id="heroTextPreview" style="background: #encodeForHtmlAttribute(previewBackground)#">
			<div id="heroTextPreviewHeading"></div>
			<div id="heroTextPreviewSub"></div>
		</div>
	</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<!--- The hero's style (classic, full screen, tall band, magazine) moved to the Hero editor (2026-10-24, owner): it is the whole
	hero's style, not only its text. enclosureImageEditor.cfm, saved by ProxyController.cfc savePostHeroStyle. --->
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Text</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextHeading">Heading:</label></td>
		<td class="#blockClass#"><input type="text" id="heroTextHeading" class="k-textbox heroTextInput" maxlength="500" style="width: 95%;" value="#encodeForHtmlAttribute(p["HeroOverlayText"] ?: "")#"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextSub">Second line:</label></td>
		<td class="#blockClass#"><input type="text" id="heroTextSub" class="k-textbox heroTextInput" maxlength="500" style="width: 95%;" placeholder="Optional" value="#encodeForHtmlAttribute(p["HeroOverlaySubText"] ?: "")#"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Look</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextColour">Color:</label></td>
		<td class="#blockClass#"><input id="heroTextColour" value="#encodeForHtmlAttribute(len(p["HeroOverlayTextColor"] ?: "") ? p["HeroOverlayTextColor"] : "##ffffff")#"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextFont">Font:</label></td>
		<td class="#blockClass#"><input id="heroTextFont" style="width: 60%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextSize">Heading size:</label></td>
		<td class="#blockClass#"><input type="range" id="heroTextSize" min="16" max="96" step="1" value="#val(p["HeroOverlayFontSize"] ?: "") ? val(p["HeroOverlayFontSize"]) : 40#" style="width: 60%;"> <span id="heroTextSizeValue"></span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextSizePhone">On mobile:</label></td>
		<td class="#blockClass#"><input type="range" id="heroTextSizePhone" min="14" max="64" step="1" value="#val(p["HeroOverlayFontSizePhone"] ?: "") ? val(p["HeroOverlayFontSizePhone"]) : 28#" style="width: 60%;"> <span id="heroTextSizePhoneValue"></span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Shadow and glow</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextShadow">Shadow:</label></td>
		<td class="#blockClass#">
			<select id="heroTextShadow" style="width: 220px;">
				<cfloop list="none:None,soft:Soft,strong:Strong" index="opt">
					<option value="#listFirst(opt, ':')#"<cfif (len(p["HeroOverlayShadow"] ?: "") ? p["HeroOverlayShadow"] : "soft") eq listFirst(opt, ':')> selected</cfif>>#listLast(opt, ':')#</option>
				</cfloop>
			</select>
			<input id="heroTextShadowColour" value="#encodeForHtmlAttribute(len(p["HeroOverlayShadowColor"] ?: "") ? p["HeroOverlayShadowColor"] : "##000000")#">
			<div class="k-form-hint">Makes the text stand out on a busy picture.</div>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<!--- The glow (owner, 10-19): on its own or with the shadow. An older "glow" shadow opens here as a glow in the shadow's color. --->
	<cfset glowColour = p["HeroOverlayGlowColor"] ?: "">
	<cfif not len(glowColour) and (p["HeroOverlayShadow"] ?: "") eq "glow"><cfset glowColour = len(p["HeroOverlayShadowColor"] ?: "") ? p["HeroOverlayShadowColor"] : "##ffffff"></cfif>
	<tr>
		<td class="#blockClass#" align="right"><label for="heroTextGlowOn">Glow:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" id="heroTextGlowOn" class="k-checkbox"<cfif len(glowColour)> checked</cfif>> <label for="heroTextGlowOn" class="k-checkbox-label">Glow around the text</label>
			<input id="heroTextGlowColour" value="#encodeForHtmlAttribute(len(glowColour) ? glowColour : "##ffd27a")#">
			<div class="k-form-hint">A halo in a color of its own; try a light or bright color on a dark hero.</div>
		</td>
	</tr>
	<tr class="blockSpacer heroTextGlowRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="heroTextGlowRow">
		<td class="#blockClass#" align="right"><label for="heroTextGlowOpacity">Glow opacity:</label></td>
		<td class="#blockClass#"><input type="range" id="heroTextGlowOpacity" min="10" max="100" step="5" value="#val(p["HeroOverlayGlowOpacity"] ?: "") ? val(p["HeroOverlayGlowOpacity"]) : 80#" style="width: 60%;"> <span id="heroTextGlowOpacityValue"></span></td>
	</tr>
	<tr class="blockSpacer heroTextGlowRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="heroTextGlowRow">
		<td class="#blockClass#" align="right"><label for="heroTextGlowSoftness">Glow softness:</label></td>
		<td class="#blockClass#"><input type="range" id="heroTextGlowSoftness" min="4" max="60" step="1" value="#val(p["HeroOverlayGlowSoftness"] ?: "") ? val(p["HeroOverlayGlowSoftness"]) : 24#" style="width: 60%;"> <span id="heroTextGlowSoftnessValue"></span>
			<div class="k-form-hint">Low is a tight, crisp glow; high spreads it wide and soft.</div></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="heroTextSave" type="button" class="k-button k-primary">Save</button></td>
	</tr>
</table>
</cfoutput>

<script>
$(document).ready(function () {
	var fonts = $.map(<cfoutput>#serializeJSON(heroFonts)#</cfoutput>, function (f) { return { name: f.Font || f.FONT }; });
	var shadows = {
		soft: function (c) { return "0 2px 6px " + rgba(c, 0.65); },
		strong: function (c) { return "0 3px 12px " + rgba(c, 0.85) + ", 0 0 2px " + rgba(c, 0.9); },
		glow: function (c) { return "0 0 10px " + rgba(c, 0.9) + ", 0 0 26px " + rgba(c, 0.7); }
	};
	function rgba(hex, a) {
		var m = /^#?([0-9a-f]{6})$/i.exec(hex || ""); var n = m ? parseInt(m[1], 16) : 0;
		return "rgba(" + ((n >> 16) & 255) + "," + ((n >> 8) & 255) + "," + (n & 255) + "," + a + ")";
	}
	$("#heroTextColour").kendoColorPicker({ opacity: false, buttons: false, preview: true, input: true, change: preview });
	$("#heroTextShadowColour").kendoColorPicker({ opacity: false, buttons: false, preview: true, input: true, change: preview });
	$("#heroTextShadow").kendoDropDownList({ change: preview });
	$("#heroTextGlowColour").kendoColorPicker({ opacity: false, buttons: false, preview: true, input: true, change: preview });
	$("#heroTextGlowOn").on("change", preview);
	$("#heroTextGlowOpacity, #heroTextGlowSoftness").on("input", preview);
	// The glow, the same as Renderer.cfc getGlowCss: a tight core and a wider, fainter halo.
	function glowCss() {
		if (!$("#heroTextGlowOn").is(":checked")) return "";
		var c = $("#heroTextGlowColour").data("kendoColorPicker").value() || "#ffffff", a = $("#heroTextGlowOpacity").val() / 100, s = +$("#heroTextGlowSoftness").val();
		return "0 0 " + Math.max(2, Math.round(s / 2.5)) + "px " + rgba(c, a) + ", 0 0 " + s + "px " + rgba(c, Math.round(a * 70) / 100);
	}
	// The window's preview is 60% of the real size, so the shadow and glow are scaled to match.
	function scaled(css) { return css.replace(/(\d+)px/g, function (m, n) { return Math.round(n * 0.6 * 10) / 10 + "px"; }); }
	$("#heroTextFont").kendoDropDownList({
		dataSource: fonts, dataTextField: "name", dataValueField: "name", optionLabel: "Theme default",
		template: '<span style="font-family:&quot;#: data.name #&quot;">#: data.name #</span>',
		value: "<cfoutput>#jsStringFormat(p["HeroOverlayFont"] ?: "")#</cfoutput>", change: preview
	});
	function preview() {
		var colour = $("#heroTextColour").data("kendoColorPicker").value() || "#ffffff";
		var shadow = $("#heroTextShadow").val(), shadowColour = $("#heroTextShadowColour").data("kendoColorPicker").value() || "#000000";
		var font = $("#heroTextFont").data("kendoDropDownList").value();
		var textShadow = [shadows[shadow] ? shadows[shadow](shadowColour) : "", glowCss()].filter(Boolean).join(", ");
		textShadow = textShadow ? scaled(textShadow) : "none";
		$(".heroTextGlowRow").toggle($("#heroTextGlowOn").is(":checked"));
		$("#heroTextGlowOpacityValue").text($("#heroTextGlowOpacity").val() + "%");
		$("#heroTextGlowSoftnessValue").text($("#heroTextGlowSoftness").val() + "px");
		$("#heroTextSizeValue").text($("#heroTextSize").val() + "px");
		$("#heroTextSizePhoneValue").text($("#heroTextSizePhone").val() + "px");
		$("#heroTextPreviewHeading").text($("#heroTextHeading").val() || "Your heading").css({ color: colour, fontSize: $("#heroTextSize").val() * 0.6 + "px", fontFamily: font ? '"' + font + '", sans-serif' : "", textShadow: textShadow });
		$("#heroTextPreviewSub").text($("#heroTextSub").val()).css({ color: colour, fontSize: $("#heroTextSize").val() * 0.3 + "px", fontFamily: font ? '"' + font + '", sans-serif' : "", textShadow: textShadow });
	}
	$(".heroTextInput, #heroTextSize, #heroTextSizePhone").on("input", preview);
	preview();

	$("#heroTextSave").on("click", function () {
		$("#heroTextSave").prop("disabled", true);
		jQuery.ajax({
			type: "post",
			url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeroText",
			data: {
				csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#val(URL.optArgs)#</cfoutput>,
				heading: $.trim($("#heroTextHeading").val()), subText: $.trim($("#heroTextSub").val()),
				colour: $("#heroTextColour").data("kendoColorPicker").value() || "", font: $("#heroTextFont").data("kendoDropDownList").value(),
				size: $("#heroTextSize").val(), sizePhone: $("#heroTextSizePhone").val(),
				shadow: $("#heroTextShadow").val(), shadowColour: $("#heroTextShadowColour").data("kendoColorPicker").value() || "",
				glowColour: $("#heroTextGlowOn").is(":checked") ? ($("#heroTextGlowColour").data("kendoColorPicker").value() || "#ffffff") : "",
				glowOpacity: $("#heroTextGlowOpacity").val(), glowSoftness: $("#heroTextGlowSoftness").val()
			},
			dataType: "json",
			success: function (response) {
				$("#heroTextSave").prop("disabled", false);
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) {
					if (typeof galaxieHeroSummaryRefresh === "function") { galaxieHeroSummaryRefresh(); }
					// The Hero editor redraws its hero text layer (enclosureImageEditor.cfm).
					$(document).trigger("galaxieHeroTextSaved");
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The hero text was saved.", icon: "k-ext-information" })).done(function () { $("#postHeroTextWindow").kendoWindow("destroy"); });
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The hero text could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			},
			error: function (jqXHR, textStatus, error) {
				$("#heroTextSave").prop("disabled", false);
				if (jqXHR.status === 403) { createLoginWindow(); } else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
			}
		});
	});
});
</script>

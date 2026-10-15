<!--- Insert/Edit Gradient popup (window id 77 - see includes/templates/blogJsContent.cfm and
includes/windows/adminInterface.cfm's cfcase value=77). Builds a CSS linear/radial gradient with Grapick
(drag-handle stops/direction) + Pickr (per-stop color, incl. alpha) - common/libs/grapick and common/libs/pickr -
plus an optional centered overlay text field, all live-previewed together in one box.

Same Page-Collection-vs-TinyMCE switch as azureMap.cfm/bingMap.cfm (see their own comment) - URL.entityType is set
automatically via window.currentEnclosureEntityType, no otherArgs needed for this window. For a Page Collection's
hero (URL.entityType eq 'pageCollection', URL.optArgs is the pageCollectionId), Submit AJAX-saves directly to
PageCollection.HeroGradient/HeroOverlayText/HeroOverlayTextColor via savePageCollectionHeroGradient and refreshes
the hero preview behind this window, same as the Carousel/Map/Video buttons next to it. Otherwise (opened from
TinyMCE's own Insert > Gradient / toolbar button, URL.optArgs is the postId), Submit sets the active editor's
content to a styled <div>. CORRECTION 2026-09-27 (was wrong here originally): includeGradient is only ever set
true inside enclosureImageEditor.cfm's own toolbarString setup (never in postDetail.cfm's separate main-body
editor - see tinyMce.cfm's cfparam default="false" and how the two calling contexts differ), so this TinyMCE path
is ALWAYS the Post/Page enclosure editor's own mini-TinyMCE instance (#enclosureEditor5544), never a "insert
decorative content into the post body" path. An enclosure is a single-item slot exactly like the image/map/
carousel enclosure types, so this needs setContent() (full replace) same as those, not insertContent() (which
left the enclosure editor's existing placeholder content - e.g. the hardcoded refreshOrm.gif default - sitting
underneath the new gradient, a real bug the user hit live).

v1 scope note: Grapick has no "parse this CSS gradient string back into handlers" API, so re-opening this editor on
an existing HeroGradient shows that gradient as the initial preview background, but Grapick itself always starts
fresh with two default stops - dragging/adding a stop takes over the live preview from there. The overlay text and
its color ARE correctly restored. --->
<cfparam name="URL.optArgs" default="">
<cfparam name="URL.otherArgs" default="">
<cfparam name="URL.entityType" default="">

<cfset isPageCollectionEnclosure = (isDefined("URL.entityType") and URL.entityType eq 'pageCollection')>
<cfset existingGradient = "linear-gradient(90deg, ##4facfe 0%, ##00f2fe 100%)">
<cfset existingOverlayText = "">
<cfset existingOverlayTextColor = "##ffffff">
<cfset existingOverlayFont = "">
<!--- 2026-10-03: default matches the fixed size this overlay text already rendered at everywhere before this
control existed (Renderer.cfc's own "16" fallback) - except the admin preview box below, which has always
shown overlay text at a larger 26px (#gradientOverlayText's own CSS) purely because that preview box is much
bigger than the real rendered output. Seeding the slider from the REAL render size (16), not the preview box's
own unrelated 26px, so a fresh post's slider position matches what it'll actually look like once saved. --->
<cfset existingOverlayFontSize = "16">

<cfif isPageCollectionEnclosure and len(URL.optArgs)>
	<cfset allCollectionsForGradientEdit = application.blog.getAllPageCollections()>
	<cfloop array="#allCollectionsForGradientEdit#" index="thisGradientCollection">
		<cfif thisGradientCollection.pageCollectionId eq val(URL.optArgs)>
			<cfif len(thisGradientCollection.heroGradient)>
				<cfset existingGradient = thisGradientCollection.heroGradient>
			</cfif>
			<cfset existingOverlayText = thisGradientCollection.heroOverlayText>
			<cfif len(thisGradientCollection.heroOverlayTextColor)>
				<cfset existingOverlayTextColor = thisGradientCollection.heroOverlayTextColor>
			</cfif>
			<!--- No HeroOverlayFont on PageCollection.cfc - the font picker is per-post only for now, see the
			2026-10-01 font-picker block below. --->
		</cfif>
	</cfloop>
<!--- 2026-10-01: the font picker is Post-only (same scope the animation feature itself originally shipped with) - load the
post's own existing HeroOverlayFont so re-opening this editor shows what was actually picked last time,
same intent as the PageCollection block above for its own fields. Note this doesn't currently load the
post's existing HeroGradient/HeroOverlayText/HeroOverlayTextColor either (a pre-existing gap, not something
this change is fixing) - only the new font field gets real restoration here. --->
<cfelseif not isPageCollectionEnclosure and len(URL.optArgs) and val(URL.optArgs) gt 0>
	<cfset editingGradientPost = entityLoadByPK("Post", val(URL.optArgs))>
	<cfif isObject(editingGradientPost) and len(editingGradientPost.getHeroOverlayFont())>
		<cfset existingOverlayFont = editingGradientPost.getHeroOverlayFont()>
	</cfif>
	<cfif isObject(editingGradientPost) and len(editingGradientPost.getHeroOverlayFontSize())>
		<cfset existingOverlayFontSize = editingGradientPost.getHeroOverlayFontSize()>
	</cfif>
</cfif>

<!--- Theme-scoped font list (only certain fonts are valid per theme) - same application.blog.getThemeFonts()
call tinyMce.cfm's own font picker already uses. themeId is already in scope here, set by
includes/windows/adminInterface.cfm before dispatching to this window. font.cfm emits the matching
@font-face CSS for self-hosted fonts of this theme so the live preview can actually render the choice, not
just store a name. --->
<cfinvoke component="#application.blog#" method="getThemeFonts" returnvariable="gradientThemeFonts">
	<cfinvokeargument name="themeId" value="#themeId#">
	<cfinvokeargument name="selfHosted" value="1">
	<cfinvokeargument name="includeWebSafeFonts" value="1">
</cfinvoke>
<cfinclude template="#application.baseUrl#/includes/templates/font.cfm">

<cfoutput>
<script>
	<!--- addCss()/getScript() are PRIVATE to galaxieLoader's own closure (see head.cfm, right next to
	fancyBox/plyr/prism) - calling them directly from here as if they were global functions was the actual bug
	behind an earlier "Uncaught ReferenceError: addCss is not defined" - it only ever appeared to work in an
	isolated test harness that happened to define its own same-named stand-in globals, never on a real page. Every
	caller goes through galaxieLoader's own named method instead - see head.cfm's grapickPickr() for the loading
	itself. --->
	var gradientLibsLoaded = false;
	galaxieLoader.grapickPickr(function() {
		gradientLibsLoaded = true;
		initGradientEditor();
	});
	<!--- whenReady() (head.cfm) has no failure callback of its own - a blocked/404'd script just leaves its
	"ready" callback never firing, silently. Surfacing that here with a generous timeout instead of leaving the
	Type dropdown as unexplained plain HTML and every stop non-interactive with no indication why - this was
	genuinely hard to diagnose from a bug report alone before this existed. --->
	setTimeout(function() {
		if (!gradientLibsLoaded) {
			$('##gradientPickerContainer').html('<p style="color:##d9534f;">Grapick/Pickr did not finish loading (common/libs/grapick or common/libs/pickr) - the gradient stop editor and Type dropdown won\'t work until they do. Check the browser console\'s Network tab for the actual error (404, blocked, etc.).</p>');
		}
	}, 8000);
</script>
</cfoutput>

<style>
	#gradientPreviewWrap {
		position: relative;
		width: 100%;
		height: 220px;
		border: 1px solid #ccc;
		margin-bottom: 12px;
		overflow: hidden;
		box-sizing: border-box;
	}
	#gradientPreviewBg {
		position: absolute;
		top: 0; left: 0; right: 0; bottom: 0;
	}
	<!--- 2026-10-03: kendoTextBox() isn't part of Kendo Core (confirmed - not in the admin bundle,
	kendo.galaxie.admin.min.js, which only Kendo's free/Core widgets ship in), so this stays a plain <input>
	styled with the k-textbox CSS class instead - same bundle-independent, class-only convention
	themeSettings.cfm's own plain text inputs already use (no JS widget call needed to look like Kendo). The
	positioning that makes this double as the live overlay-on-gradient preview stays directly on the input
	itself, same as it was when this was a <textarea>. --->
	#gradientOverlayText {
		position: absolute;
		top: 0; left: 0; right: 0; bottom: 0;
		width: 100%;
		height: 100%;
		border: none;
		background: transparent;
		text-align: center;
		font-size: 26px;
		font-weight: bold;
		padding: 20px;
		box-sizing: border-box;
		outline: none;
		font-family: inherit;
	}
	#gradientPickerContainer {
		height: 40px;
		margin-bottom: 12px;
	}
	<!--- 2026-09-27, superseded the per-handle Pickr approach below (kept as gradientEditor.cfm.bak-per-handle-
	pickr-2026-09-27) - embedding a fresh Pickr instance inside each Grapick handle turned out to be unstable:
	handler.setColor() (called from Pickr's own 'change' event) triggers Grapick to re-render that handle's whole
	DOM, which re-runs the colorEl/setColorPicker setup and creates a SECOND independent Pickr instance on top of
	the first - a real duplicate-button bug the user hit live, not just a cosmetic one. It also meant the popup's
	trigger element kept getting recreated/repositioned, so Pickr's popup had nowhere stable to anchor from.
	Grapick's own per-handle color-picker trigger area is hidden entirely now - color editing happens through the
	one persistent, external "Stop Color" swatch below instead (bound to whichever handle is selected). --->
	#gradientPickerContainer .grp-handler-cp-c {
		display: none !important;
	}
	<!--- Pickr's own CSS hardcodes .pcr-app{z-index:10000}. This admin interface's ambient z-index scale runs well
	above that already (head.cfm sets .tox-tinymce-inline{z-index:30050}, .modal{z-index:30040},
	.modal-backdrop{z-index:30030}), and a real Kendo Window (confirmed live: computed z-index 10003) sits just
	above Pickr's own default too. Without this, Pickr's popup renders correctly (visibility:visible, right
	position) but sits invisibly BEHIND the surrounding Kendo Window - no console error, since nothing failed, it's
	just hidden under something else. --->
	.pcr-app {
		z-index: 30100 !important;
	}
	<!--- The one persistent color-editing trigger - a plain rectangular swatch (not Grapick's own tiny per-handle
	circle) so it's obviously clickable and has a stable position for Pickr's popup to anchor from. --->
	#gradientStopColorSwatch {
		width: 60px;
		height: 26px;
		border: 1px solid #999;
		border-radius: 3px;
		cursor: pointer;
	}
</style>

<table align="left" class="k-content" width="100%" cellpadding="8" cellspacing="0" border="0">
	<tr>
		<td>
			<div id="gradientPreviewWrap">
				<div id="gradientPreviewBg" style="background: <cfoutput>#existingGradient#</cfoutput>;"></div>
				<input type="text" id="gradientOverlayText" class="k-textbox" placeholder="Optional overlay text" value="<cfoutput>#encodeForHTMLAttribute(existingOverlayText)#</cfoutput>">
			</div>
		</td>
	</tr>
	<tr>
		<td>
			<div id="gradientPickerContainer"></div>
		</td>
	</tr>
	<tr>
		<td>
			<button id="gradientPasteButton" class="k-button normalFontWeight" type="button" onclick="javascript:createAdminInterfaceWindow(78,0);">Paste Custom Gradient</button>
			<button id="gradientClearButton" class="k-button normalFontWeight" type="button" onclick="javascript:clearCustomGradient();">Clear</button>
			<span id="gradientCustomModeNotice" style="display:none; margin-left: 10px; font-style: italic;">Using a pasted gradient - the stop editor above is disabled. Click Clear to build one instead.</span>
		</td>
	</tr>
	<tr>
		<td>
			<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="0">
				<tr>
					<td align="right" style="width: 20%">
						<label for="gradientStopColorSwatch">Stop Color:</label>
					</td>
					<td colspan="3">
						<div id="gradientStopColorSwatch"></div>
					</td>
				</tr>
				<tr>
					<td align="right" style="width: 20%">
						<label for="gradientType">Type:</label>
					</td>
					<td style="width: 25%">
						<select id="gradientType">
							<option value="linear">Linear</option>
							<option value="radial">Radial</option>
						</select>
					</td>
					<td align="right" style="width: 20%">
						<label for="gradientAngle">Angle:</label>
					</td>
					<td style="width: 25%">
						<input type="range" id="gradientAngle" min="0" max="360" value="90" style="width: 100%;">
					</td>
				</tr>
				<tr>
					<td align="right" style="width: 20%">
						<label for="gradientOverlayTextColor">Text Color:</label>
					</td>
					<td colspan="3">
						<script>
							$("#gradientOverlayTextColor").kendoColorPicker({
								input: false,
								preview: false,
								value: "<cfoutput>#existingOverlayTextColor#</cfoutput>",
								buttons: false,
								views: ["gradient"]
							});
						</script>
						<input id="gradientOverlayTextColor" name="gradientOverlayTextColor">
					</td>
				</tr>
				<!--- 2026-10-01: Post-only, same scope the animation feature's own overlay fields are - a Page Collection's hero
				has no HeroOverlayFont column (see the load block above). --->
				<cfif not isPageCollectionEnclosure>
				<tr>
					<td align="right" style="width: 20%">
						<label for="gradientOverlayFont">Text Font:</label>
					</td>
					<td colspan="3">
						<select id="gradientOverlayFont" style="width: 60%"></select>
					</td>
				</tr>
				<!--- 2026-10-03: plain range input, same widget-free convention heroAnimationEditor.cfm's own
				Speed slider already uses - no Kendo widget needed (or available - kendoTextBox isn't part of
				Kendo Core, confirmed earlier tonight). --->
				<tr>
					<td align="right" style="width: 20%">
						<label for="gradientOverlayFontSize">Text Size:</label>
					</td>
					<td colspan="3">
						<input type="range" id="gradientOverlayFontSize" min="12" max="72" step="1" value="<cfoutput>#existingOverlayFontSize#</cfoutput>" style="width:80%;">
						<span id="gradientOverlayFontSizeReadout" style="display:inline-block;width:40px;text-align:right;"><cfoutput>#existingOverlayFontSize#</cfoutput>px</span>
					</td>
				</tr>
				</cfif>
			</table>
		</td>
	</tr>
	<tr valign="middle" height="30px">
		<td valign="bottom" align="left">
			<button id="gradientCancelButton" class="k-button normalFontWeight" type="button" onclick="javascript:$('#gradientEditorWindow').kendoWindow('destroy');">Cancel</button>
			<button id="gradientSubmitButton" class="k-button k-primary" type="button" onclick="javascript:onGradientEditorSubmit();">Submit</button>
		</td>
	</tr>
</table>

<script>
	var gradientPicker = null;
	<!--- Non-null while a pasted gradient (window 78) is active - see applyCustomGradient()/clearCustomGradient()
	below. Submit uses this instead of gradientPicker.getValue() whenever it's set. --->
	var customGradientValue = null;
	<!--- One persistent Pickr instance (created once in initGradientEditor(), never recreated) bound to the "Stop
	Color" swatch, plus whichever Grapick handle is currently selected - see the 'handler:select' listener below.
	Editing a stop's color no longer creates/destroys any Pickr instance, unlike the earlier per-handle approach
	this replaced (see the big comment on #gradientPickerContainer .grp-handler-cp-c in the <style> block above). --->
	var stopColorPickr = null;
	var selectedHandler = null;

	function refreshGradientPreview() {
		var value = customGradientValue || (gradientPicker ? gradientPicker.getValue() : '');
		$('#gradientPreviewBg').css('background', value);
	}

	<!--- initGradientEditor() only runs once Grapick+Pickr have both loaded (see the getScript().done() chain
	below) and only converts #gradientType to a real Kendo widget as its last step - if that never ran (a script
	failed to load, or threw partway through), .data('kendoDropDownList') is undefined. Centralizing the lookup
	here so callers can check once instead of each repeating the same undefined-guard. --->
	function getGradientTypeWidget() {
		return $('#gradientType').data('kendoDropDownList') || null;
	}

	<!--- Called from gradientPasteEditor.cfm (window 78) via window.applyCustomGradient - shares this window's
	global JS scope (iframe: false), same as every createAdminInterfaceWindow popup. Per the "Custom takes over"
	decision: disables the Grapick stop editor and the Type/Angle controls (a pasted gradient already encodes its
	own type/angle/stops) rather than trying to keep both in sync. --->
	function applyCustomGradient(value) {
		customGradientValue = value;
		refreshGradientPreview();
		$('#gradientPickerContainer').css({ opacity: 0.4, 'pointer-events': 'none' });
		var typeWidget = getGradientTypeWidget();
		if (typeWidget) { typeWidget.enable(false); }
		$('#gradientAngle').prop('disabled', true);
		$('#gradientCustomModeNotice').show();
	}
	window.applyCustomGradient = applyCustomGradient;

	<!--- Clears the pasted gradient AND resets Grapick's own stops back to the default two - a plain "go back to
	the stop editor" wouldn't restore anything sensible if the user had already been fiddling with stops before
	pasting, so this is a genuine full reset of both inputs, not just a mode toggle. --->
	function clearCustomGradient() {
		customGradientValue = null;
		$('#gradientPickerContainer').css({ opacity: 1, 'pointer-events': 'auto' });
		var typeWidget = getGradientTypeWidget();
		if (typeWidget) { typeWidget.enable(true); typeWidget.value('linear'); }
		$('#gradientAngle').prop('disabled', false);
		$('#gradientCustomModeNotice').hide();

		if (gradientPicker) {
			gradientPicker.getHandlers().slice().forEach(function(h) { h.remove(); });
			gradientPicker.addHandler(0, '#4facfe', 1);
			gradientPicker.addHandler(100, '#00f2fe', 1);
			gradientPicker.setType('linear');
			gradientPicker.setDirection('90deg');
			<!--- The new handlers need their own selection synced back into the shared swatch, same as
			initGradientEditor() does right after its own addHandler() calls. --->
			selectedHandler = gradientPicker.getSelected() || gradientPicker.getHandlers()[gradientPicker.getHandlers().length - 1];
			if (stopColorPickr && selectedHandler) { stopColorPickr.setColor(selectedHandler.getColor()); }
		}
		$('#gradientAngle').val(90);
		$('#gradientAngle').closest('tr').css('visibility', 'visible');
		refreshGradientPreview();
	}

	function initGradientEditor() {
		gradientPicker = new Grapick({
			el: '#gradientPickerContainer',
			direction: 'right'
		});

		gradientPicker.addHandler(0, '#4facfe', 1);
		gradientPicker.addHandler(100, '#00f2fe', 1);

		<!--- One Pickr instance, created once, bound to the stable "Stop Color" swatch - see the big comment on
		#gradientPickerContainer .grp-handler-cp-c in the <style> block above for why this replaced creating a
		fresh Pickr instance inside each Grapick handle (that approach duplicated itself every time a color was
		picked, since setColor() triggers Grapick to re-render the handle, which re-ran the setup code again). --->
		stopColorPickr = Pickr.create({
			el: '#gradientStopColorSwatch',
			theme: 'classic',
			default: '#4facfe',
			comparison: false,
			position: 'bottom-middle',
			components: {
				preview: true,
				opacity: true,
				hue: true,
				interaction: { hex: true, rgba: true, input: true, clear: false, save: true }
			}
		});
		<!--- 'save' gets its own (color, instance) args from Pickr, same shape as 'change' - documented as "also
		fired on clear with null as color", so guard for that even though this config's own clear button is
		disabled. Applying the color again here (not just relying on 'change' having already fired) makes 'save'
		self-sufficient - a user hit a live case where the stop's color wasn't ending up applied, which a missed or
		out-of-order 'change' would explain. The null-check on stopColorPickr itself guards a live
		"Cannot read properties of null (reading 'hide')" crash on this exact line that couldn't be reproduced in
		isolated testing - cheap to guard regardless of the exact trigger. --->
		stopColorPickr.on('change', function(color) {
			if (selectedHandler && color) { selectedHandler.setColor(color.toRGBA().toString()); }
		}).on('save', function(color) {
			if (selectedHandler && color) { selectedHandler.setColor(color.toRGBA().toString()); }
			if (stopColorPickr) { stopColorPickr.hide(); }
		});

		<!--- Grapick auto-selects the last-added handle (confirmed live - the second addHandler() call above ends
		up with the .grp-handler-selected class), so sync the swatch to it now rather than waiting for a first
		click. --->
		selectedHandler = gradientPicker.getSelected() || gradientPicker.getHandlers()[gradientPicker.getHandlers().length - 1];
		if (selectedHandler) { stopColorPickr.setColor(selectedHandler.getColor()); }

		gradientPicker.on('handler:select', function(handler) {
			selectedHandler = handler;
			stopColorPickr.setColor(handler.getColor());
		});

		gradientPicker.on('change', refreshGradientPreview);
		refreshGradientPreview();

		$('#gradientType').kendoDropDownList({
			change: function() {
				gradientPicker.setType(this.value());
				$('#gradientAngle').closest('tr').css('visibility', this.value() === 'linear' ? 'visible' : 'hidden');
				refreshGradientPreview();
			}
		});

		$('#gradientAngle').on('input', function() {
			gradientPicker.setDirection($(this).val() + 'deg');
			refreshGradientPreview();
		});

		<!--- 2026-10-01: font picker is Post-only (the dropdown isn't rendered at all for a Page Collection -
		see the cfif around it above), so guard its init the same way. Applies the chosen font to the live
		preview textarea immediately, same "always show what you'll actually get" intent as refreshGradientPreview()
		itself - not just a name stored for later. --->
		if ($('#gradientOverlayFont').length) {
			<!--- 2026-10-03: shows each font rendered in its own face while browsing the list - same
			kendo.data.DataSource + template pattern themeSettings.cfm's own bodyFontDropdown already uses (Font/
			FontFace fields, both the same value from getThemeFonts()'s own query). Local inline data (not a
			remote transport) since gradientThemeFonts is already the exact theme-scoped, self-hosted+web-safe
			list this field needs - no reason to re-fetch the full font library bodyFontDropdown pulls from. --->
			var gradientFontDs = new kendo.data.DataSource({
				data: <cfoutput>#serializeJson(gradientThemeFonts)#</cfoutput>
			});
			$('#gradientOverlayFont').kendoDropDownList({
				dataTextField: 'Font',
				dataValueField: 'Font',
				dataSource: gradientFontDs,
				optionLabel: 'Default',
				template: '<label style="font-family:\'#:data.FontFace#\'">#:data.Font#</label>',
				change: function() {
					$('#gradientOverlayText').css('font-family', this.value() ? ('"' + this.value() + '"') : 'inherit');
				}
			}).data('kendoDropDownList').wrapper.css('width', '60%');
			$('#gradientOverlayFont').data('kendoDropDownList').value('<cfoutput>#existingOverlayFont#</cfoutput>');
			$('#gradientOverlayText').css('font-family', $('#gradientOverlayFont').val() ? ('"' + $('#gradientOverlayFont').val() + '"') : 'inherit');

			<!--- 2026-10-03: live-sizes the same preview textarea the font picker above already live-styles -
			same "always show what you'll actually get" intent. --->
			$('#gradientOverlayText').css('font-size', $('#gradientOverlayFontSize').val() + 'px');
			$('#gradientOverlayFontSize').on('input', function() {
				$('#gradientOverlayFontSizeReadout').text(this.value + 'px');
				$('#gradientOverlayText').css('font-size', this.value + 'px');
			});
		}
	}

	function onGradientEditorSubmit() {
		var gradientCss = customGradientValue || (gradientPicker ? gradientPicker.getValue() : $('#gradientPreviewBg').css('background-image'));
		var overlayText = $('#gradientOverlayText').val();
		<!--- Kendo's ColorPicker keeps its bound <input>'s value attribute in sync (same as carouselItems.cfm's
		identical widget, read there via plain form post) - defensive against either a "#ffffff" or "ffffff"
		return format, since that isn't documented consistently across Kendo versions. --->
		var overlayTextColor = $('#gradientOverlayTextColor').val() || '#ffffff';
		if (overlayTextColor.charAt(0) !== '#') { overlayTextColor = '#' + overlayTextColor; }
		<!--- Post-only field - $('#gradientOverlayFont') simply doesn't exist in the Page Collection branch (see
		the cfif around its row above), so this is just '' there, matching that branch's AJAX payload never
		having sent a font to begin with. --->
		var overlayFont = $('#gradientOverlayFont').val() || '';
		<!--- Same Post-only reasoning as overlayFont above - $('#gradientOverlayFontSize') doesn't exist in the
		Page Collection branch either. --->
		var overlayFontSize = $('#gradientOverlayFontSize').val() || '';

		<cfif isPageCollectionEnclosure>
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollectionHeroGradient',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					pageCollectionId: <cfoutput>#URL.optArgs#</cfoutput>,
					heroGradient: gradientCss,
					heroOverlayText: overlayText,
					heroOverlayTextColor: overlayTextColor
				},
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						<!--- A previously-uploaded hero image is still sitting in the Uppy Dashboard panel (and its
						hidden #enclosurePreview mirror) of the still-open enclosure editor window behind this one -
						saving a gradient here doesn't touch either, so without this they'd keep showing the old
						image/thumbnail even though the gradient is now what's actually saved. Shares this window's
						global JS scope (iframe: false on every createAdminInterfaceWindow popup), so enclosureUppy
						is directly reachable - wrapped defensively since this window can also be reached from a
						context where that variable was never declared (e.g. a future direct-URL open). --->
						try { enclosureUppy.cancelAll(); } catch(e) {}
						try { $('#enclosurePreview').html('<img src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="">'); } catch(e) {}
						try { reloadPageCollectionHeroPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch(e) {}
						try { $("#configurePageCollectionsWindow").data("kendoWindow").refresh(); } catch(e) {}
						$('#gradientEditorWindow').kendoWindow('destroy');
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		<cfelse>
			<!--- Sizing here (width:235px, height:130px, overflow:hidden, padding:10px, font-size:16px) must match
			Renderer.cfc's renderHeroGradientHtml() exactly - this is the client-side preview shown immediately
			after Save (before Submit persists it and a later reload renders the real server HTML). A plain fixed
			width matches renderEnclosureVideoPreview()'s own established 235x130 admin-thumbnail size - a
			max-width:1200px + margin:0 auto responsive/centering version was tried first and confirmed live (via
			the user's own DevTools inspection) to genuinely render as a 1200x130 box, ~150px offset from the left
			margin - too wide for this admin column's real available width, with margin:auto centering it inside
			an oversized parent rather than the visible content area. A small fixed pixel box sidesteps that
			entirely, same as the video preview already does in this exact container. --->
			<!--- 2026-10-01: single quotes, not double - this span sits inside a double-quoted style="..."
			attribute, so a double-quoted font name broke out of it early (same bug/fix as
			Renderer.cfc's renderHeroGradientHtml()). --->
			var overlayFontCss = overlayFont ? ("font-family:'" + overlayFont + "';") : '';
			var overlayFontSizeCss = (overlayFontSize || '16') + 'px';
			var overlayHtml = overlayText.length
				? '<div style="width:235px;height:130px;overflow:hidden;background:' + gradientCss + ';display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:10px;"><span style="color:' + overlayTextColor + ';font-size:' + overlayFontSizeCss + ';font-weight:bold;text-align:center;' + overlayFontCss + '">' + overlayText + '</span></div>'
				: '<div style="width:235px;height:130px;overflow:hidden;background:' + gradientCss + ';box-sizing:border-box;padding:10px;"></div>';
			<!--- Post has no plain-string hero field the way PageCollection.HeroImageUrl does - EnclosureMedia/Map/
			Carousel/PageCollection's own EntitySave calls are what actually persist THEIR hero types, and until
			today nothing did that for a gradient. Originally this branch only called setContent() (visual only) -
			a real bug the user hit live: the gradient showed in the editor, but clicking the enclosure editor's own
			Submit didn't save it anywhere, since Submit only checks whether the editor is EMPTY (to remove an
			existing enclosure) and never takes arbitrary editor content and persists it - that's specific to each
			enclosure type's own save call, same as this one now is. See Post.cfc's new HeroGradient/HeroOverlayText/
			HeroOverlayTextColor properties and blog.cfc's savePostHeroGradient(). --->
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeroGradient',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					heroGradient: gradientCss,
					heroOverlayText: overlayText,
					heroOverlayTextColor: overlayTextColor,
					heroOverlayFont: overlayFont,
					heroOverlayFontSize: overlayFontSize
				},
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						<!--- setContent(), not insertContent() - this is always the Post/Page enclosure editor's
						own mini-TinyMCE instance (see the file header comment above), and an enclosure is a
						single-item slot same as the image/map/carousel enclosure types (which all use setContent()
						too, e.g. bingMap.cfm). Using insertContent() here left whatever was already in the editor -
						e.g. the enclosure editor's hardcoded refreshOrm.gif placeholder - sitting underneath the new
						gradient instead of being replaced by it. --->
						tinymce.activeEditor.setContent(overlayHtml);
						<!--- The Image Quality slider / Estimate Image Size button belong to the Uppy upload flow -
						they make no sense once a gradient is what's actually set, so hide their rows in the
						still-open enclosure editor window behind this one. Each is its own <tr> in
						enclosureImageEditor.cfm (no shared wrapper id), so target each by its own element and hide
						the closest row - wrapped defensively like enclosureUppy.cancelAll() above, same shared-scope
						reasoning. This only affects the window instance that's open right now - reopening the
						enclosure editor fresh re-renders these rows visible again, since nothing here changes what
						enclosureImageEditor.cfm itself renders on a fresh load. --->
						try { $('label[for="imageQualitySlider"]').closest('tr').hide(); } catch(e) {}
						try { $('#imageQualitySlider').closest('tr').hide(); } catch(e) {}
						try { $('#imageQualityPreviewButton').closest('tr').hide(); } catch(e) {}
						try { reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch(e) {}
						$('#gradientEditorWindow').kendoWindow('destroy');
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		</cfif>
	}
</script>

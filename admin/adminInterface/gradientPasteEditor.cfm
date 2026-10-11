<!--- Paste Custom Gradient popup (window id 78 - see includes/templates/blogJsContent.cfm and
includes/windows/adminInterface.cfm's cfcase value=78). A plain textarea, not TinyMCE - the user is pasting a raw
CSS gradient() string (e.g. from an external tool like cssgradient.io, or one with a type Grapick can't build,
such as conic-gradient()), not rich text, so a rich-text editor would only risk mangling the paste. On Use This
Gradient, validates the pasted value looks like a single safe *-gradient(...) call (rejects anything containing
<, >, ", ', or ; beyond the one optional trailing one that gets stripped - closes off breaking out of the
style="..." attribute this value is later interpolated into, both client-side in gradientEditor.cfm's own preview
and server-side in admin/loadPreview.cfm/pageCollectionDetail.cfm's <cfoutput> of the saved HeroGradient), then
calls window.applyCustomGradient(value) - defined in gradientEditor.cfm, which opened this window and shares its
global JS scope (iframe: false, same as every createAdminInterfaceWindow popup). --->

<style>
	#gradientPasteTextarea {
		width: 100%;
		height: 140px;
		box-sizing: border-box;
		font-family: monospace;
		font-size: 13px;
	}
	#gradientPasteError {
		color: #d9534f;
		display: none;
		margin-top: 8px;
	}
</style>

<table align="left" class="k-content" width="100%" cellpadding="8" cellspacing="0" border="0">
	<tr>
		<td>
			<label for="gradientPasteTextarea">Paste a CSS gradient from any tool (e.g. cssgradient.io) - either the full declaration or just the gradient() value:</label>
		</td>
	</tr>
	<tr>
		<td>
			<textarea id="gradientPasteTextarea" placeholder="background: radial-gradient(circle, rgba(238, 174, 202, 1) 0%, rgba(148, 187, 233, 1) 100%);"></textarea>
			<div id="gradientPasteError"></div>
		</td>
	</tr>
	<tr valign="middle" height="30px">
		<td valign="bottom" align="right">
			<button id="gradientPasteCancelButton" class="k-button normalFontWeight" type="button" onclick="javascript:$('#gradientPasteEditorWindow').kendoWindow('destroy');">Cancel</button>
			<button id="gradientPasteSubmitButton" class="k-button k-primary" type="button" onclick="javascript:onGradientPasteSubmit();">Use This Gradient</button>
		</td>
	</tr>
</table>

<script>
	function onGradientPasteSubmit() {
		var raw = $('#gradientPasteTextarea').val() || '';

		<!--- Accept either a full "background: ...;" / "background-image: ...;" declaration or just the bare
		gradient() value - strip whichever wrapper is present. --->
		var value = raw.trim().replace(/^background(-image)?\s*:\s*/i, '').replace(/;\s*$/, '').trim();

		<!--- A CSS declaration can legally have more than one "background:" line (a plain-color fallback before
		the gradient, exactly like the example this feature was requested from) - only the LAST one is what
		actually renders, so use that. --->
		var lines = raw.split('\n').map(function(l) { return l.trim(); }).filter(function(l) { return /^background(-image)?\s*:/i.test(l); });
		if (lines.length) {
			value = lines[lines.length - 1].replace(/^background(-image)?\s*:\s*/i, '').replace(/;\s*$/, '').trim();
		}

		var validPattern = /^(repeating-)?(linear|radial|conic)-gradient\([^<>"';]*\)$/i;
		if (!value.length || !validPattern.test(value)) {
			$('#gradientPasteError').text('That doesn\'t look like a single linear-gradient()/radial-gradient()/conic-gradient() value. Paste just the gradient, with no extra CSS rules or HTML.').show();
			return;
		}

		try {
			window.applyCustomGradient(value);
		} catch (e) {
			$('#gradientPasteError').text('Could not apply this gradient: ' + e.message).show();
			return;
		}

		$('#gradientPasteEditorWindow').kendoWindow('destroy');
	}
</script>

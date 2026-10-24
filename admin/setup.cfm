<!--- Site Wizard (Galaxie 5, 2026-10-19): seven screens that turn a new install into the owner's own site - name, look,
logo, about you, home page, starter content, done - with a live preview of the site beside them. Each screen is saved when the
owner moves on (ProxyController.cfc saveSetup -> common/cfc/Setup.cfc), so leaving half way loses nothing, and the admin home
shows a "Finish setting up your site" banner until Done. Uses Kendo UI 2021 R1 (its Wizard; the rest of the admin uses 2019),
loaded on this page only. In the admin folder, so only a signed-in user reaches it; saving also needs EditServerSetting.
2026-10-20: Kendo's Wizard is only in Kendo UI Professional, which Galaxie can't ship, so this page failed on blogs installed from
GitHub. It now runs on the free Kendo UI Core that Galaxie includes, with Galaxie's own wizard (common/js/galaxieWizard.js), which
takes the same options and events. --->
<cfsetting showdebugoutput="false">
<cfcontent type="text/html; charset=utf-8">
<cfset canSetup = application.blog.isCapabilityAuthorized(session.capabilityList ?: "", "EditServerSetting")>
<cfset csrfToken = csrfGenerateToken("admin", false)>
<cfset setupState = application.blog.getSetup().getState()>
<cfset rendererObj = createObject("component", application.rendererComponentPath)>

<cfquery name="themes" datasource="#application.dsn#">
	SELECT t.ThemeAlias, t.ThemeName, t.DarkTheme, ts.BlogBackgroundImage, ts.HeaderBackgroundImage
	FROM Theme t JOIN ThemeSetting ts ON ts.ThemeSettingId = t.ThemeSettingRef
	WHERE t.UseTheme = 1
	ORDER BY t.ThemeName
</cfquery>

<!--- The name-logo type styles: blog fonts. Each font's file is embedded in the saved SVG logo, so it shows everywhere. --->
<cfset logoFonts = [
	{ "font": "Playfair Display Bold", "label": "Classic", "css": "", "upper": false, "spacing": 0 },
	{ "font": "Montserrat Black", "label": "Bold modern", "css": "text-transform:uppercase;letter-spacing:.06em;", "upper": true, "spacing": 0.06 },
	{ "font": "Pacifico Regular", "label": "Friendly script", "css": "", "upper": false, "spacing": 0 },
	{ "font": "Bebas Neue Regular", "label": "Tall caps", "css": "letter-spacing:.08em;", "upper": false, "spacing": 0.08 },
	{ "font": "Lobster Regular", "label": "Retro", "css": "", "upper": false, "spacing": 0 },
	{ "font": "Josefin Sans Regular", "label": "Light and airy", "css": "text-transform:uppercase;letter-spacing:.18em;", "upper": true, "spacing": 0.18 },
	{ "font": "Orbitron Bold", "label": "Tech", "css": "letter-spacing:.04em;", "upper": false, "spacing": 0.04 },
	{ "font": "Eagle Lake", "label": "Storybook", "css": "", "upper": false, "spacing": 0 }
]>
<cfset fontExt = application.serverSupportsWoff2 ? "woff2" : "woff">
<cfset fontFiles = {}>
<cfloop array="#application.blog.getFont()#" index="f">
	<cfif len(f["FileName"] ?: "")><cfset fontFiles[f["Font"]] = application.baseUrl & "/common/fonts/" & f["FileName"] & "." & fontExt></cfif>
</cfloop>
<cfset fontFaces = "">
<cfset fontParts = []>
<cfloop array="#logoFonts#" index="lf">
	<cfset fontFaces = fontFaces & rendererObj.getOverlayFontFaceStyle(lf.font)>
	<cfset arrayAppend(fontParts, '{"font":' & serializeJSON(lf.font) & ',"label":' & serializeJSON(lf.label) & ',"css":' & serializeJSON(lf.css)
		& ',"upper":' & (lf.upper ? 'true' : 'false') & ',"spacing":' & lf.spacing & ',"file":' & serializeJSON(fontFiles[lf.font] ?: "") & '}')>
</cfloop>
<cfset fontFaces = fontFaces & rendererObj.getOverlayFontFaceStyle("Montserrat Bold")>
<cfset markFontFile = fontFiles["Montserrat Bold"] ?: "">

<!--- The theme cards (2026-10-20): the same small pictures of a page as the Themes window, from ThemeEditor.cfc getThemeCards(). --->
<cfset setupThemeCards = application.blog.getThemeEditor().getThemeCards(true)>
<cfset themeParts = []>
<cfloop query="themes">
	<cfset arrayAppend(themeParts, '{"alias":' & serializeJSON(toString(themes.ThemeAlias)) & ',"name":' & serializeJSON(toString(themes.ThemeName))
		& ',"dark":' & (themes.DarkTheme eq 1 ? 'true' : 'false') & ',"bg":' & serializeJSON(application.baseUrl & themes.BlogBackgroundImage)
		& ',"header":' & serializeJSON(application.baseUrl & themes.HeaderBackgroundImage) & '}')>
</cfloop>

<!--- Sample logos: files in images/logo/samples/, named category-name.ext. SVGs drawn in currentColor take the color picked. --->
<cfset sampleFolder = expandPath(application.baseUrl & "/images/logo/samples")>
<cfset sampleParts = []>
<cfif directoryExists(sampleFolder)>
	<cfdirectory action="list" directory="#sampleFolder#" name="sampleFiles" type="file" sort="name asc">
	<cfloop query="sampleFiles">
		<cfset ext = lCase(listLast(sampleFiles.name, "."))>
		<cfif listFind("svg,png,gif,jpg,jpeg,webp", ext)>
			<cfset words = listToArray(reReplace(sampleFiles.name, "\.[^.]+$", ""), "-_ ")>
			<cfset cat = arrayLen(words) gt 1 ? words[1] : "Yours">
			<cfif arrayLen(words) gt 1><cfset arrayDeleteAt(words, 1)></cfif>
			<cfset markName = "">
			<cfloop array="#words#" index="w"><cfset markName = listAppend(markName, uCase(left(w, 1)) & mid(w, 2, 200), " ")></cfloop>
			<cfset part = '{"name":' & serializeJSON(toString(markName)) & ',"cat":' & serializeJSON(toString(uCase(left(cat, 1)) & mid(cat, 2, 200)))>
			<cfif ext eq "svg">
				<cfset svgText = reReplace(fileRead(sampleFolder & "/" & sampleFiles.name, "utf-8"), "<\?xml[^>]*\?>|<!DOCTYPE[^>]*>|<!--.*?-->", "", "all")>
				<cfset part = part & ',"fileSvg":' & serializeJSON(trim(svgText))>
			<cfelse>
				<cfset part = part & ',"src":' & serializeJSON(application.baseUrl & "/images/logo/samples/" & sampleFiles.name)>
			</cfif>
			<cfset arrayAppend(sampleParts, part & '}')>
		</cfif>
	</cfloop>
</cfif>

<!--- Time zones: the region/city ids people recognise. --->
<cfset zoneIds = createObject("java", "java.util.TimeZone").getAvailableIDs()>
<cfset zones = []>
<cfloop array="#zoneIds#" index="z">
	<cfif reFind("^(Africa|America|Antarctica|Asia|Atlantic|Australia|Europe|Indian|Pacific)/[A-Za-z_/-]+$", z)><cfset arrayAppend(zones, z)></cfif>
</cfloop>
<cfset arraySort(zones, "textnocase")>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Site Wizard</title>
<cfoutput>
<link rel="stylesheet" href="#application.baseUrl#/common/libs/kendoCore/styles/kendo.bootstrap-v4.min.css">
<!--- Font Awesome for the social icons beside the "Where to find you" fields (2026-10-20). --->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css">
<script src="#application.baseUrl#/common/libs/kendoCore/js/jquery.min.js"></script>
<script src="#application.baseUrl#/common/libs/kendoCore/js/kendo.ui.core.min.js"></script>
<script src="#application.baseUrl#/common/js/galaxieWizard.js"></script>
<script src="#application.baseUrl#/common/js/galaxieThemeCards.js"></script>
#fontFaces#
#setupThemeCards.fontFaces#
</cfoutput>
<style>
	:root { --ink: #1f2328; --muted: #5d6670; --line: #d8dde3; --accent: #007bff; --panel: #ffffff; --page: #eef1f4; }
	* { box-sizing: border-box; }
	html, body { margin: 0; height: 100%; font-family: Arial, Helvetica, sans-serif; color: var(--ink); background: var(--page); }
	.shell { display: flex; height: 100%; }
	.stepSide { width: 46%; min-width: 440px; background: var(--panel); border-right: 1px solid var(--line); display: flex; flex-direction: column; }
	.stepSide h1 { font-size: 20px; margin: 18px 22px 4px; }
	.stepSide .sub { margin: 0 22px 10px; color: var(--muted); font-size: 14px; }
	.stepSide .sub a { color: var(--accent); }
	#wizard { flex: 1; min-height: 0; padding: 0 12px 12px; }
	#wizard .gw-content { overflow: auto; }
	.lead { font-size: 15px; margin: 4px 0 14px; color: var(--muted); }
	.fieldRow { display: flex; align-items: flex-start; gap: 10px; margin: 0 0 14px; font-size: 14px; }
	.fieldRow > label { width: 25%; text-align: right; color: var(--muted); padding-top: 7px; flex: none; }
	.fieldRow .control { flex: 1; min-width: 0; }
	.fieldRow input.k-textbox, .fieldRow textarea { width: 100%; }
	.fieldRow textarea { min-height: 96px; font: inherit; padding: 6px 8px; border: 1px solid var(--line); border-radius: 4px; }
	.hint { font-size: 13px; color: var(--muted); margin-top: 6px; }
	.saveNote { font-size: 13px; color: #b00020; margin: 8px 0 0; min-height: 1em; }
	/* Look */
	.themeGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; padding: 2px 4px 8px; }
	.themeCard { border: 2px solid transparent; border-radius: 8px; cursor: pointer; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.15); overflow: hidden; text-align: left; padding: 0; font: inherit; color: inherit; }
	.themeCard:hover { box-shadow: 0 3px 10px rgba(0,0,0,.2); }
	.themeCard[aria-pressed="true"] { border-color: var(--accent); }
	.themePic { height: 92px; background-size: cover; background-position: center; position: relative; }
	.themeHeader { height: 22px; background-size: cover; background-position: left center; display: flex; align-items: center; padding: 0 8px; font-size: 11px; font-weight: bold; color: #fff; text-shadow: 0 1px 2px rgba(0,0,0,.6); overflow: hidden; white-space: nowrap; }
	.themeBody { position: absolute; left: 14%; right: 14%; top: 30px; bottom: 0; background: rgba(255,255,255,.88); border-radius: 3px 3px 0 0; }
	.themeCard.dark .themeBody { background: rgba(30,32,36,.88); }
	.themeName { padding: 7px 9px; font-size: 13px; display: flex; justify-content: space-between; align-items: center; }
	.themeFonts { padding: 0 9px 8px; font-size: 12px; color: var(--muted); }
	.themeName .tick { color: var(--accent); font-weight: bold; visibility: hidden; }
	.themeCard[aria-pressed="true"] .tick { visibility: visible; }
	.chips { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 12px; align-items: center; font-size: 14px; }
	.chips button { border: 1px solid var(--line); background: #fff; border-radius: 14px; padding: 4px 11px; font-size: 13px; cursor: pointer; }
	.chips button[aria-pressed="true"] { background: var(--accent); color: #fff; border-color: var(--accent); }
	/* Logo */
	.ways { margin-bottom: 14px; display: flex; flex-wrap: wrap; gap: 6px; }
	.wayPanel { display: none; }
	.wayPanel.on { display: block; }
	.logoGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 10px; }
	.logoCard { border: 2px solid var(--line); border-radius: 8px; background: #fff; cursor: pointer; padding: 0; font: inherit; color: inherit; text-align: left; overflow: hidden; }
	.logoCard[aria-pressed="true"] { border-color: var(--accent); }
	.logoSample { height: 78px; display: flex; align-items: center; justify-content: center; padding: 0 10px; background-size: cover; background-position: left center; overflow: hidden; white-space: nowrap; }
	.logoLabel { padding: 5px 9px; font-size: 12px; color: var(--muted); border-top: 1px solid var(--line); }
	.uploadBox { border: 2px dashed var(--line); border-radius: 8px; padding: 24px; text-align: center; color: var(--muted); font-size: 14px; }
	.uploadBox img { max-height: 90px; max-width: 100%; display: block; margin: 12px auto 0; }
	/* Home and starter */
	.choiceList { display: grid; gap: 10px; }
	.choice { display: flex; gap: 12px; align-items: flex-start; border: 2px solid var(--line); border-radius: 8px; padding: 12px; cursor: pointer; background: #fff; }
	.choice:has(input:checked) { border-color: var(--accent); }
	.choice input { margin-top: 3px; }
	.choice strong { display: block; margin-bottom: 2px; }
	.choice span { font-size: 13px; color: var(--muted); }
	/* Done */
	.summary { list-style: none; padding: 0; margin: 0 0 16px; }
	.summary li { display: flex; justify-content: space-between; padding: 9px 4px; border-bottom: 1px solid var(--line); font-size: 14px; }
	.summary .state { color: var(--muted); }
	.summary .state.done { color: #1a7f37; }
	.summary a { color: var(--accent); margin-left: 10px; }
	/* Preview switch, post picture cards, footer (2026-10-20). */
	.previewSwitch { display: inline-flex; border: 1px solid var(--line); border-radius: 16px; overflow: hidden; background: var(--panel); }
	.previewSwitch:empty { display: none; }
	.previewSwitch button { border: 0; background: none; padding: 4px 12px; font: inherit; font-size: 13px; cursor: pointer; color: var(--ink); }
	.previewSwitch button[aria-pressed=true] { background: var(--accent); color: var(--panel); }
	.heroCards { display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 10px; }
	.heroCard { border: 1px solid var(--line); border-radius: 8px; background: var(--panel); cursor: pointer; overflow: hidden; font: inherit; font-size: 13px; text-align: left; padding: 0; color: var(--ink); }
	.heroCard[aria-pressed=true] { border-color: var(--accent); box-shadow: 0 0 0 1px var(--accent); }
	.heroCard .art { height: 70px; background: var(--page); position: relative; display: block; }
	.heroCard .art i { position: absolute; display: block; background: rgba(93,102,112,.45); }
	.heroCard .art u { position: absolute; display: block; height: 4px; border-radius: 2px; background: rgba(31,35,40,.75); }
	.heroCard .art u.light { background: rgba(255,255,255,.95); }
	.heroCard .art u.soft { background: rgba(93,102,112,.5); }
	.heroCard .lbl { display: block; padding: 6px 8px; }
	.choice.disabled { opacity: .55; cursor: default; }
	.needsAbout { display: none; font-size: 13px; }
	.choice.disabled .needsAbout { display: block; }
	/* Upload buttons (2026-10-20): the file boxes are hidden; their labels are Kendo buttons. */
	.hiddenFile { position: absolute; width: 1px; height: 1px; opacity: 0; overflow: hidden; }
	.uploadButton { cursor: pointer; margin: 4px 0; }
	.fileName { color: var(--muted); font-size: 13px; }
	/* Preview */
	.previewSide { flex: 1; display: flex; flex-direction: column; min-width: 0; }
	.previewBar { display: flex; justify-content: space-between; align-items: center; padding: 10px 16px; font-size: 14px; color: var(--muted); }
	.previewBar a { color: var(--accent); }
	.previewStage { flex: 1; position: relative; overflow: hidden; margin: 0 16px 16px; border-radius: 8px; background: #fff; box-shadow: 0 2px 12px rgba(0,0,0,.18); }
	.previewStage iframe { position: absolute; top: 0; left: 0; border: 0; width: 166.67%; height: 166.67%; transform: scale(.6); transform-origin: 0 0; }
	.previewStage.mobile { width: 390px; max-width: calc(100% - 32px); margin-left: auto; margin-right: auto; }
	.previewStage.mobile iframe { width: 100%; height: 100%; transform: none; }
	.loading { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,.7); font-size: 14px; color: var(--muted); z-index: 2; }
	.denied { max-width: 560px; margin: 80px auto; background: #fff; padding: 24px; border-radius: 8px; font-size: 15px; }
	/* The admin's alternating blocks (owner, 10-20): the first k-content, then k-alt, with a line between rows and between blocks. */
	.block { padding: 10px 14px; }
	.block.k-alt { background-color: #f4f5f7; }
	.block + .block { border-top: 1px solid #c8c8c8; }
	.block > * + * { border-top: 1px solid #c8c8c8; padding-top: 10px; margin-top: 10px; }
	.block > * { margin-top: 0; margin-bottom: 0; }
	.block .wayPanel > * + * { border-top: 1px solid #c8c8c8; padding-top: 10px; margin-top: 10px; }
	.block .wayPanel > .fieldRow { margin-bottom: 0; }
	.block > .fieldRow, .block .wayPanel > .fieldRow { margin-bottom: 0; }
	.block h4 { margin: 2px 0; font-size: 15px; }
	.block .summary li:last-child { border-bottom: 0; }
	@media (max-width: 900px) {
		.shell { flex-direction: column; height: auto; }
		.stepSide { width: 100%; min-width: 0; }
		.previewStage { height: 70vh; flex: none; }
		.fieldRow { flex-direction: column; gap: 4px; }
		.fieldRow > label { width: auto; text-align: left; padding-top: 0; }
	}
</style>
</head>
<body>
<cfif not canSetup>
	<div class="denied"><cfoutput>Setting up the site needs permission to change the blog's settings. Please ask the blog's owner, or <a href="#application.baseUrl#/admin/">go back to the administration page</a>.</cfoutput></div>
<cfelse>
<div class="shell">
	<div class="stepSide">
		<h1>Set up your site</h1>
		<p class="sub"><cfoutput>Seven short steps. Skip anything and come back to it later from the administration page. <a href="#application.baseUrl#/admin/">Back to administration</a></cfoutput></p>
		<div id="wizard"></div>
	</div>
	<div class="previewSide">
		<div class="previewBar"><span>Your site, live</span><span class="previewSwitch" id="previewSwitch"></span><a href="#" id="toggleMobile">Show on mobile</a></div>
		<div class="previewStage" id="previewStage">
			<div class="loading" id="previewLoading">Loading your site...</div>
			<iframe id="preview" title="Preview of your site" sandbox="allow-same-origin allow-scripts allow-forms"></iframe>
		</div>
	</div>
</div>

<!--- The screens. They are moved into the wizard as live elements, so their widgets keep working. --->
<div style="display:none">
	<div id="stepSite">
		<div class="block k-content"><p class="lead">The basics: what your site is called and how to reach you.</p></div>
		<div class="block k-alt">
			<h4>Your site</h4>
			<div class="fieldRow"><label for="siteTitle">Site name</label><div class="control"><input id="siteTitle" class="k-textbox" maxlength="125"></div></div>
			<div class="fieldRow"><label for="siteDescription">Description</label><div class="control"><input id="siteDescription" class="k-textbox" maxlength="500" placeholder="One line about your site"><div class="hint">Shown to search engines and when your site is shared.</div></div></div>
		</div>
		<div class="block k-content">
			<h4>Email and time</h4>
			<div class="fieldRow"><label for="siteEmail">Email</label><div class="control"><input id="siteEmail" class="k-textbox" type="email" placeholder="you@example.com">
				<div class="hint">Comment notices, sign-in links and subscriber emails come from this address. <a href="#" id="sendTestEmail">Send a test email</a> <span id="testEmailResult"></span></div></div></div>
			<div class="fieldRow"><label for="siteTimeZone">Time zone</label><div class="control"><input id="siteTimeZone" style="width:100%"><div class="hint">Post dates and scheduled posts use this time.</div></div></div>
		</div>
	</div>
	<div id="stepLook">
		<div class="block k-content"><p class="lead">Pick how your site looks. You can change it any time.</p></div>
		<div class="block k-alt">
			<div class="chips" id="themeFilter">
				<span>Show:</span>
				<button type="button" data-f="all" aria-pressed="true">All</button>
				<button type="button" data-f="photo" aria-pressed="false">Photos</button>
				<button type="button" data-f="pattern" aria-pressed="false">Patterns and color</button>
				<button type="button" data-f="dark" aria-pressed="false">Dark</button>
			</div>
			<div class="themeGrid" id="themeGrid"></div>
		</div>
	</div>
	<div id="stepLogo">
		<div class="block k-content"><p class="lead">Your logo appears at the top of every page, in every theme.</p></div>
		<div class="block k-alt">
			<h4>Header logo</h4>
			<div class="ways" id="logoWays"></div>
			<div class="wayPanel on" id="wayName">
				<div class="fieldRow"><label for="logoName">Name</label><div class="control"><input id="logoName" class="k-textbox" maxlength="60"></div></div>
				<div class="fieldRow"><label for="logoColour">Color</label><div class="control"><input id="logoColour"></div></div>
				<div class="logoGrid" id="nameGrid"></div>
			</div>
			<div class="wayPanel" id="waySample">
				<div class="chips" id="sampleFilter"></div>
				<div class="fieldRow"><label for="sampleColour">Color</label><div class="control"><input id="sampleColour"></div></div>
				<div class="logoGrid" id="sampleGrid"></div>
				<p class="hint">Your site name is set beside each mark. Samples are starting points other sites may use too. For a logo that's only yours, upload your own.</p>
			</div>
			<div class="wayPanel" id="wayUpload">
				<div class="uploadBox">
					<p>Choose a picture of your logo: PNG, SVG, JPG, GIF or WebP, up to 2 MB. A wide logo about 300 by 80 pixels works best.</p>
					<!--- A Kendo button in place of the browser's own file box (2026-10-20, owner); the box itself is hidden. --->
					<input type="file" id="logoFile" class="hiddenFile" accept="image/png,image/svg+xml,image/jpeg,image/gif,image/webp">
					<label for="logoFile" class="k-button k-primary uploadButton" tabindex="0">Upload a logo</label> <span class="fileName" data-for="logoFile"></span>
					<img id="uploadPreview" alt="" hidden>
				</div>
			</div>
		</div>
		<!--- The footer logo (2026-10-21, owner): usually a bigger, fuller picture than the small one in the header. --->
		<div class="block k-content">
			<h4>Footer logo</h4>
			<p class="hint" style="margin-top:0">At the bottom of every page, above your footer links.</p>
			<div class="choiceList" id="footerLogoChoices">
				<label class="choice"><input type="radio" name="footerLogoMode" value="same"><div><strong>Same as the header logo</strong><span>Your header logo, centered in the footer.</span></div></label>
				<label class="choice"><input type="radio" name="footerLogoMode" value="upload"><div><strong>Upload a footer logo</strong><span>A fuller version: a stacked logo, a badge, or your logo with a tagline.</span></div></label>
				<label class="choice"><input type="radio" name="footerLogoMode" value="none"><div><strong>No footer logo</strong><span>Just your footer links and the copyright line.</span></div></label>
			</div>
			<div class="uploadBox" id="footerLogoUpload" style="margin-top:10px" hidden>
				<p>PNG, SVG, JPG, GIF or WebP, up to 2 MB. About 3 by 2, for example 480 by 320 pixels, works best; it shows up to 300 pixels wide.</p>
				<input type="file" id="footerLogoFile" class="hiddenFile" accept="image/png,image/svg+xml,image/jpeg,image/gif,image/webp">
				<label for="footerLogoFile" class="k-button k-primary uploadButton" tabindex="0">Upload a footer logo</label> <span class="fileName" data-for="footerLogoFile"></span>
				<img id="footerLogoPreview" alt="" hidden>
			</div>
		</div>
		<div class="block k-alt"><p class="hint">We also make the smaller logo for mobile and the picture used when your posts are shared on social media.</p></div>
	</div>
	<div id="stepAbout">
		<div class="block k-content"><p class="lead">Who is behind the site. This fills your About and Bio windows; change it any time in your profile.</p></div>
		<div class="block k-alt">
			<h4>You</h4>
			<div class="fieldRow"><label for="aboutPhoto">Photo</label><div class="control">
				<div style="display:flex;gap:14px;align-items:center;flex-wrap:wrap"><img id="aboutPhotoPreview" alt="" style="width:72px;height:72px;border-radius:50%;object-fit:cover;background:#eef1f4">
				<input type="file" id="aboutPhoto" class="hiddenFile" accept="image/png,image/jpeg,image/gif,image/webp">
				<label for="aboutPhoto" class="k-button k-primary uploadButton" tabindex="0">Upload a photo</label> <span class="fileName" data-for="aboutPhoto"></span></div>
				<div class="hint">Shown in your Bio window. A square photo works best.</div></div></div>
			<div class="fieldRow"><label for="aboutFirst">First name</label><div class="control"><input id="aboutFirst" class="k-textbox" maxlength="125"></div></div>
			<div class="fieldRow"><label for="aboutLast">Last name</label><div class="control"><input id="aboutLast" class="k-textbox" maxlength="125"></div></div>
		</div>
		<div class="block k-content">
			<h4>In your words</h4>
			<div class="fieldRow"><label for="aboutBio">About you</label><div class="control"><textarea id="aboutBio" placeholder="A few lines about yourself"></textarea><div class="hint">Shown in the Bio window. Leave a blank line to start a new paragraph.</div></div></div>
			<div class="fieldRow"><label for="aboutSite">About the site</label><div class="control"><textarea id="aboutSite" placeholder="What your site is about, and who it is for"></textarea><div class="hint">Shown in the About window.</div></div></div>
		</div>
		<div class="block k-alt">
			<h4>Where to find you</h4>
			<div class="fieldRow"><label for="aboutFacebook"><i class="fa-brands fa-facebook" aria-hidden="true"></i> Facebook</label><div class="control"><input id="aboutFacebook" class="k-textbox" placeholder="https://"></div></div>
			<div class="fieldRow"><label for="aboutInstagram"><i class="fa-brands fa-instagram" aria-hidden="true"></i> Instagram</label><div class="control"><input id="aboutInstagram" class="k-textbox" placeholder="https://"></div></div>
			<div class="fieldRow"><label for="aboutLinkedIn"><i class="fa-brands fa-linkedin" aria-hidden="true"></i> LinkedIn</label><div class="control"><input id="aboutLinkedIn" class="k-textbox" placeholder="https://"></div></div>
			<div class="fieldRow"><label for="aboutTwitter"><i class="fa-brands fa-x-twitter" aria-hidden="true"></i> X (Twitter)</label><div class="control"><input id="aboutTwitter" class="k-textbox" placeholder="https://"></div></div>
		</div>
	</div>
	<div id="stepHome">
		<div class="block k-content"><p class="lead">What visitors see first.</p></div>
		<div class="block k-alt">
			<h4>Home page</h4>
			<div class="choiceList" id="homeChoices">
				<label class="choice" id="homeKeepChoice" style="display:none"><input type="radio" name="homeLayout" value="keep"><div><strong>Keep my home page as it is</strong><span>Your home page stays as you have it now. Change it any time in Home Page settings.</span></div></label>
				<label class="choice"><input type="radio" name="homeLayout" value="posts"><div><strong>Latest posts</strong><span>A blog: your newest posts first.</span></div></label>
				<label class="choice"><input type="radio" name="homeLayout" value="featured"><div><strong>Your About page, then your latest posts</strong><span>Introduce yourself at the top, with posts below.</span><a href="#" class="needsAbout">Needs an About page: go back to Starter content</a></div></label>
				<label class="choice"><input type="radio" name="homeLayout" value="about"><div><strong>Just your About page</strong><span>A one-page site. New posts won't appear on the home page; they're still in the menu.</span><a href="#" class="needsAbout">Needs an About page: go back to Starter content</a></div></label>
			</div>
		</div>
		<div class="block k-content">
			<h4>Post heroes</h4>
			<p class="hint" style="margin-top:0">How the hero at the top of each post (its picture, video or scene) shows on the post's own page. Click one to see it on the right.</p>
			<div class="heroCards" id="heroCards"></div>
		</div>
		<div class="block k-alt">
			<h4>Footer</h4>
			<p class="hint" style="margin-top:0" id="footerHint">Made from what you entered: About and Contact links and your social links, never your email address. It is made when you press Next; change it any time in Themes, Content.</p>
			<div class="choiceList" id="footerChoices">
				<label class="choice"><input type="radio" name="footerStyle" value="simple"><div><strong>Simple</strong><span>About and Contact, and your social links.</span></div></label>
				<label class="choice"><input type="radio" name="footerStyle" value="blurb"><div><strong>With a short about blurb</strong><span>The first lines of what you wrote about yourself, above the links.</span></div></label>
				<label class="choice"><input type="radio" name="footerStyle" value="none"><div><strong>Just the basics</strong><span>Only the logo and the version line every footer has, without links.</span></div></label>
			</div>
		</div>
	</div>
	<div id="stepStarter">
		<div class="block k-content"><p class="lead">A few things to start with, so the site doesn't look empty. Each is an ordinary post or page; nothing is made until you press Next. The preview on the right shows how they will look.</p></div>
		<div class="block k-alt">
			<p class="hint" id="starterUpgradedNote" style="display:none;margin-top:0">Your blog already has its posts and pages, so nothing is ticked. Tick anything you would like to add.</p>
			<div class="choiceList">
				<label class="choice"><input type="checkbox" id="starterWelcome" checked><div><strong>A welcome post</strong><span>Your first post, ready to change. The next step uses it to show the post picture styles.</span></div></label>
				<label class="choice"><input type="checkbox" id="starterAbout" checked><div><strong>An About page</strong><span>Made from what you wrote about yourself. Needed for an About home page.</span></div></label>
				<label class="choice"><input type="checkbox" id="starterContact" checked><div><strong>A contact form</strong><span>At the end of your About page, so visitors can reach you. Their messages come to your email. Change its questions any time in Forms.</span></div></label>
			</div>
			<p class="hint">To change them later: in the administration, open <b>Posts and Pages</b>, then <b>Posts</b> (or <b>Pages</b> for the About page), and click the title in the list to open it in the editor. The last step also links straight to them.</p>
		</div>
	</div>
	<div id="stepDone">
		<div class="block k-content"><p class="lead">That's it. Here is what you set up; change anything with its link.</p></div>
		<div class="block k-alt"><ul class="summary" id="doneSummary"></ul></div>
		<div class="block k-content"><p class="hint">Press Done to finish and open your site.</p></div>
	</div>
</div>

<script>
$(function () {
	<cfoutput>
	var baseUrl = "#jsStringFormat(application.baseUrl)#";
	var csrfToken = "#csrfToken#";
	var themes = [#arrayToList(themeParts, ",")#];
	var themeCards = {};
	#serializeJSON(setupThemeCards.themes)#.forEach(function (c) { themeCards[c.ThemeAlias] = c; });
	var fonts = [#arrayToList(fontParts, ",")#];
	var markFontFile = #serializeJSON(markFontFile)#;
	var fontFaceHtml = #serializeJSON(fontFaces)#;
	var zones = #serializeJSON(zones)#;
	var saved = {
		title: #serializeJSON(setupState.title)#, description: #serializeJSON(setupState.description)#, email: #serializeJSON(setupState.email)#,
		timeZone: #serializeJSON(setupState.timeZone)#, theme: #serializeJSON(setupState.theme)#, stepsDone: #serializeJSON(setupState.stepsDone)#,
		homeLayout: #serializeJSON(setupState.homeLayout)#, heroStyle: #serializeJSON(setupState.heroStyle)#,
		firstName: #serializeJSON(setupState.firstName)#, lastName: #serializeJSON(setupState.lastName)#,
		biography: #serializeJSON(setupState.biography)#, profilePicture: #serializeJSON(setupState.profilePicture)#, facebookUrl: #serializeJSON(setupState.facebookUrl)#, linkedInUrl: #serializeJSON(setupState.linkedInUrl)#,
		instagramUrl: #serializeJSON(setupState.instagramUrl)#, twitterUrl: #serializeJSON(setupState.twitterUrl)#,
		welcomePostId: #val(setupState.welcomePostId)#, welcomeUrl: #serializeJSON(setupState.welcomeUrl)#, aboutPageId: #val(setupState.aboutPageId)#, aboutUrl: #serializeJSON(setupState.aboutUrl)#,
		footer: #serializeJSON(setupState.footer)#, footerIsCustom: #setupState.footerIsCustom ? "true" : "false"#, footerLogo: #serializeJSON(setupState.footerLogo)#,
		upgradedBlog: #setupState.upgradedBlog ? "true" : "false"#
	};
	var userMarks = [#arrayToList(sampleParts, ",")#];
	</cfoutput>
	var state = { theme: saved.theme || (themes[0] && themes[0].alias), way: "name", font: 0, sample: 0, name: saved.title, colour: "#ffffff", sampleColour: "#ffffff", upload: "", colourPicked: false,
		footerMode: saved.footerLogo || "same", footerUpload: "" };
	var dirty = {};
	function stepsDone() { return (saved.stepsDone || "").split(",").filter(Boolean); }

	// Built-in sample marks; your own from images/logo/samples/ come first.
	var marks = userMarks.concat([
		{ name: "Leaf", cat: "Personal", svg: '<path d="M40 6C21 7 8 17 8 32c0 4 1 7 2 9 3-12 12-21 23-25-10 6-16 15-19 25 15 2 28-9 26-35z" fill="currentColor"/>' },
		{ name: "Open book", cat: "Personal", svg: '<path d="M5 11c6-2 13-1 19 3 6-4 13-5 19-3v27c-6-2-13-1-19 3-6-4-13-5-19-3z" fill="none" stroke="currentColor" stroke-width="3" stroke-linejoin="round"/><path d="M24 14v27" stroke="currentColor" stroke-width="3"/>' },
		{ name: "Monogram", cat: "Business", svg: '<circle cx="24" cy="24" r="21" fill="currentColor"/><text x="24" y="31.5" text-anchor="middle" font-size="21" font-family="Georgia,serif" font-weight="bold" fill="#ffffff">{initial}</text>' },
		{ name: "Diamond", cat: "Business", svg: '<path d="M24 3l21 21-21 21L3 24z" fill="currentColor"/><path d="M24 14l10 10-10 10-10-10z" fill="#ffffff" opacity=".55"/>' },
		{ name: "Star badge", cat: "Club", svg: '<circle cx="24" cy="24" r="21" fill="none" stroke="currentColor" stroke-width="3"/><path d="M24 10.5l3.9 8.2 9 1.1-6.6 6.2 1.7 8.9L24 30.6l-8 4.3 1.7-8.9-6.6-6.2 9-1.1z" fill="currentColor"/>' },
		{ name: "Coffee cup", cat: "Food", svg: '<path d="M7 19h26v9a12 12 0 0 1-12 12h-2A12 12 0 0 1 7 28z" fill="currentColor"/><path d="M33 22h3a5 5 0 0 1 0 10h-3" fill="none" stroke="currentColor" stroke-width="3"/><path d="M15 6c-2 3 2 5 0 9M22 6c-2 3 2 5 0 9" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/>' },
		{ name: "Mountain", cat: "Outdoors", svg: '<path d="M2 41l14-23 8 12 6-8 16 19z" fill="currentColor"/><circle cx="36" cy="11" r="5" fill="currentColor"/>' },
		{ name: "Code", cat: "Tech", svg: '<path d="M16 12L5 24l11 12M32 12l11 12-11 12" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M27.5 8l-7 32" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>' }
	]);
	var sampleCat = "All";

	function esc(s) { return $("<div>").text(s == null ? "" : s).html(); }
	function isLightColour(hex) {
		var c = /^#([0-9a-f]{6})$/i.exec(hex || ""), n = c ? parseInt(c[1], 16) : 0;
		return !!c && (0.299 * (n >> 16 & 255) + 0.587 * (n >> 8 & 255) + 0.114 * (n & 255)) > 150;
	}
	function currentTheme() { return themes.filter(function (t) { return t.alias === state.theme; })[0] || themes[0]; }
	function lightHeader(t) { return /white|ice/i.test(t.header); }
	function initial() { return esc((state.name || "?").trim().charAt(0).toUpperCase()); }
	// A mark's own SVG markup (inner shapes, in a 48 x 48 box), with the letter or cut-out in a shade that shows on its color.
	function markInner(m) {
		return m.svg.replace("{initial}", initial()).replace(/#ffffff/g, isLightColour(state.sampleColour) ? "#1f2328" : "#ffffff");
	}
	function markHtml(m, size) {
		if (m.src) { return '<img src="' + m.src + '" alt="" style="width:' + size + 'px;height:' + size + 'px;object-fit:contain;flex:none">'; }
		if (m.fileSvg) { return '<span style="display:inline-flex;width:' + size + 'px;height:' + size + 'px;flex:none">' + m.fileSvg.replace(/<svg\b/i, '<svg style="width:100%;height:100%"') + '</span>'; }
		return '<svg viewBox="0 0 48 48" width="' + size + '" height="' + size + '" aria-hidden="true" style="flex:none">' + markInner(m) + '</svg>';
	}
	// The logo as HTML, for the cards and the live preview.
	function logoHtml(size) {
		if (state.way === "upload") { return state.upload ? '<img src="' + state.upload + '" alt="" style="max-height:' + size * 1.8 + 'px;max-width:320px;display:block">' : ""; }
		if (state.way === "sample") {
			return '<span style="display:inline-flex;align-items:center;gap:' + size * .35 + 'px;color:' + state.sampleColour + '">' + markHtml(marks[state.sample], size * 1.5)
				+ '<span style="font-family:\'Montserrat Bold\',sans-serif;font-size:' + size + 'px;line-height:1">' + esc(state.name) + '</span></span>';
		}
		var f = fonts[state.font];
		return '<span style="font-family:\'' + f.font + '\',serif;font-size:' + size + 'px;line-height:1.1;color:' + state.colour + ';' + f.css + '">' + esc(state.name) + '</span>';
	}

	// ---------- the preview: the blog in the picked theme, with the picked logo in its header until it is saved ----------
	var frame = document.getElementById("preview");
	var previewLogo = false;
	// What the preview shows (2026-10-20): the site, or on Starter content the welcome post / About page, or on Home page the home
	// page (in the picked layout) / a post (in the picked picture style). Unsaved choices are shown with preview-only address options
	// that only work for a signed-in owner (previewHome, previewHeroStyle); starter posts not made yet are drawn here instead.
	var previewView = "site";
	function addQuery(url, query) { return url + (url.indexOf("?") >= 0 ? "&" : "?") + query; }
	function previewUrl() {
		var q = "theme=" + encodeURIComponent(state.theme) + "&setupPreview=" + Date.now();
		if (previewView === "home") { return addQuery(baseUrl + "/index.cfm", q + "&previewHome=" + encodeURIComponent(homeLayout())); }
		if (previewView === "post") { return addQuery(saved.welcomeUrl || saved.aboutUrl || (baseUrl + "/index.cfm"), q + "&previewHeroStyle=" + encodeURIComponent(state.heroStyle)); }
		if (previewView === "welcome" && saved.welcomeUrl) { return addQuery(saved.welcomeUrl, q); }
		if (previewView === "about" && saved.aboutUrl) { return addQuery(saved.aboutUrl, q); }
		return addQuery(baseUrl + "/index.cfm", q);
	}
	function loadPreview() {
		$("#previewLoading").show();
		if ((previewView === "welcome" && !saved.welcomeUrl) || (previewView === "about" && !saved.aboutUrl)) {
			frame.removeAttribute("src"); frame.srcdoc = pretendPage(previewView); return;
		}
		frame.removeAttribute("srcdoc");
		frame.src = previewUrl();
	}
	// A starter post that isn't made yet, drawn in the picked theme's colors.
	function pretendPage(kind) {
		var t = themes.filter(function (x) { return x.alias === state.theme; })[0] || themes[0] || {};
		var name = esc($.trim($("#siteTitle").val()) || saved.title || "Your site");
		var head = '<div style="padding:14px 22px;color:' + (t.dark ? "white" : "white") + ';font:bold 20px Arial,sans-serif;background:rgba(40,60,90,.9) url(\'' + (t.header || "") + '\') center/cover">' + name + '</div>';
		var bio = $.trim($("#aboutBio").val() || "");
		var paras = bio ? bio.split(/\n\s*\n/).map(function (x) { return "<p>" + esc(x).replace(/\n/g, "<br>") + "</p>"; }).join("") : "<p>Tell your visitors who you are and what this site is about. <u>Edit this page</u> to make it yours.</p>";
		var body = kind === "welcome"
			? '<h1 style="font-size:26px;margin:0 0 6px">Welcome to ' + name + '</h1><div style="font:12px Arial,sans-serif;color:gray;margin-bottom:12px">Today</div><div style="height:160px;border-radius:6px;margin-bottom:14px;background:linear-gradient(135deg,rgb(29,67,80) 0%,rgb(164,57,49) 100%)"></div><p>Welcome to ' + name + '! This is the first post. <u>Edit it</u> to say hello in your own words, or delete it once you have written your own.</p>'
			: '<h1 style="font-size:26px;margin:0 0 12px">About</h1>' + paras + ($("#starterContact").is(":checked") ? '<h2 style="font-size:20px">Get in touch</h2><div style="border:1px solid silver;border-radius:6px;padding:12px;font:13px Arial,sans-serif">Name<div style="height:26px;border:1px solid silver;border-radius:4px;margin:4px 0 8px"></div>Email<div style="height:26px;border:1px solid silver;border-radius:4px;margin:4px 0 8px"></div>Message<div style="height:60px;border:1px solid silver;border-radius:4px;margin-top:4px"></div></div>' : "");
		return '<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0;font-family:Georgia,serif;color:rgb(40,40,40);background:silver url(\'' + (t.bg || "") + '\') center/cover fixed">' + head
			+ '<div style="max-width:760px;margin:22px auto;background:rgba(255,255,255,.96);border-radius:6px;padding:20px 26px;line-height:1.6">'
			+ '<div style="font:12px Arial,sans-serif;background:rgb(255,246,224);border:1px solid rgb(240,217,160);border-radius:4px;padding:6px 8px;margin-bottom:14px">Not made yet: this is how it will look once you press Next.</div>' + body + '</div></body></html>';
	}
	// The switch above the preview, for the screens that show more than the site.
	function setPreviewSwitch(views, pick) {
		var bar = $("#previewSwitch").empty();
		if (views.length > 1) {
			views.forEach(function (v) {
				bar.append($('<button type="button"></button>').attr("aria-pressed", v[0] === pick ? "true" : "false").text(v[1]).on("click", function () {
					previewView = v[0]; bar.children().attr("aria-pressed", "false"); $(this).attr("aria-pressed", "true"); loadPreview();
				}));
			});
		}
		previewView = pick; loadPreview();
	}
	function previewForStep(index) {
		if (index === 4) {
			var views = [];
			if ($("#starterWelcome").is(":checked")) { views.push(["welcome", "Welcome post"]); }
			if ($("#starterAbout").is(":checked")) { views.push(["about", "About page"]); }
			setPreviewSwitch(views, views.length ? (views.some(function (v) { return v[0] === previewView; }) ? previewView : views[0][0]) : "site");
		} else if (index === 5) {
			setPreviewSwitch([["home", "Home page"], ["post", "A post"]], previewView === "post" ? "post" : "home");
		} else if (previewView !== "site") {
			setPreviewSwitch([], "site");
		} else {
			$("#previewSwitch").empty();
		}
	}
	function applyLogo() {
		var doc;
		if (!previewLogo) { return; }
		try { doc = frame.contentDocument; } catch (e) { return; }
		if (!doc || !doc.body) { return; }
		if (!doc.getElementById("setupFonts")) { var holder = doc.createElement("div"); holder.id = "setupFonts"; holder.innerHTML = fontFaceHtml; doc.head.appendChild(holder); }
		var html = logoHtml(30);
		Array.prototype.forEach.call(doc.querySelectorAll("#logo"), function (cell) {
			var link = cell.querySelector("a");
			if (!link) { return; }
			if (!link.hasAttribute("data-original")) { link.setAttribute("data-original", link.innerHTML); }
			link.innerHTML = html ? '<span style="display:inline-block;padding:6px 10px">' + html + '</span>' : link.getAttribute("data-original");
		});
		Array.prototype.forEach.call(doc.querySelectorAll("#blogNameContainer"), function (n) { n.style.visibility = html && state.way !== "upload" ? "hidden" : ""; });
		<!--- The footer logo (2026-10-21): the theme's footer picture is hidden, and the chosen footer logo shows above the links. --->
		var foot = doc.getElementById("footerInnerContainer");
		if (foot) {
			Array.prototype.forEach.call(foot.querySelectorAll("img"), function (img) { if (!img.hasAttribute("data-setup")) { img.style.display = "none"; } });
			var mine = foot.querySelector("[data-setup]");
			if (!mine) { mine = doc.createElement("div"); mine.setAttribute("data-setup", "footerLogo"); mine.style.cssText = "text-align:center;padding:10px 0"; foot.insertBefore(mine, foot.firstChild); }
			mine.innerHTML = state.footerMode === "none" ? "" : state.footerMode === "upload"
				? (state.footerUpload ? '<img data-setup="1" src="' + state.footerUpload + '" alt="" style="max-width:min(300px,100%);height:auto;display:inline-block">' : "")
				: '<span style="display:inline-block">' + logoHtml(30) + '</span>';
		}
	}
	frame.addEventListener("load", function () { $("#previewLoading").hide(); applyLogo(); });
	$("#toggleMobile").on("click", function (e) {
		e.preventDefault();
		var mobile = !$("#previewStage").hasClass("mobile");
		$("#previewStage").toggleClass("mobile", mobile); $(this).text(mobile ? "Show on a computer" : "Show on mobile");
		loadPreview();
	});

	// ---------- screen 1: your site ----------
	$("#siteTitle").val(saved.title).on("input", function () { dirty.site = true; state.name = this.value; $("#logoName").val(this.value); });
	$("#siteDescription").val(saved.description).on("input", function () { dirty.site = true; });
	$("#siteEmail").val(saved.email).on("input", function () { dirty.site = true; });
	var browserZone = (window.Intl && Intl.DateTimeFormat().resolvedOptions().timeZone) || "";
	$("#siteTimeZone").kendoDropDownList({
		dataSource: zones, filter: "contains",
		// Until the owner has saved this screen, the browser's own time zone is the better guess than the installer's default.
		value: stepsDone().indexOf("site") >= 0 || zones.indexOf(browserZone) < 0 ? saved.timeZone : browserZone,
		change: function () { dirty.site = true; }
	});
	if (stepsDone().indexOf("site") < 0) { dirty.site = true; }
	$("#sendTestEmail").on("click", function (e) {
		e.preventDefault();
		$("#testEmailResult").text("Sending...");
		save("testEmail", { email: $.trim($("#siteEmail").val()) }).then(function () { $("#testEmailResult").text("Sent. Check your inbox (and spam folder)."); },
			function (message) { $("#testEmailResult").text(message); });
	});

	// ---------- screen 2: look ----------
	var themeFilter = "all";
	function isPhoto(t) { return /\.(jpg|webp)$/i.test(t.bg) && !/silver|chrome|abstract/i.test(t.bg); }
	function drawThemes() {
		var grid = $("#themeGrid").empty();
		themes.filter(function (t) {
			return themeFilter === "all" || (themeFilter === "dark" ? t.dark : themeFilter === "photo" ? isPhoto(t) : !isPhoto(t));
		}).forEach(function (t) {
			<!--- The same small picture of a page as the Themes window (common/js/galaxieThemeCards.js): the header with the site name in its
			font, the content box under it with a Latin sample in the theme's fonts, the sidebar on classic themes, and the font names. --->
			var data = themeCards[t.alias];
			var pic = data ? GalaxieThemeCards.picture(data, { siteName: state.name, baseUrl: baseUrl, height: 150 })
				: $('<div class="themePic"></div>').css("background-image", 'url("' + t.bg + '")');
			var card = $('<button type="button" class="themeCard"></button>').toggleClass("dark", t.dark).attr("aria-pressed", t.alias === state.theme ? "true" : "false")
				.append(pic)
				.append($('<div class="themeName"></div>').append($("<span>").text(t.name)).append('<span class="tick">&#10003;</span>'));
			if (data) { card.append($('<div class="themeFonts"></div>').append(GalaxieThemeCards.fontsLine(data))); }
			card.on("click", function () {
				state.theme = t.alias; dirty.look = true;
				if (!state.colourPicked) { state.colour = state.sampleColour = lightHeader(t) ? "#1f2328" : "#ffffff"; syncColours(); }
				$("#themeGrid .themeCard").attr("aria-pressed", "false"); card.attr("aria-pressed", "true");
				loadPreview(); drawLogos();
			});
			grid.append(card);
		});
		if (!grid.children().length) { grid.append('<p class="hint">No themes of this kind yet.</p>'); }
	}
	$("#themeFilter").on("click", "button", function () {
		themeFilter = $(this).data("f"); $("#themeFilter button").attr("aria-pressed", "false"); $(this).attr("aria-pressed", "true"); drawThemes();
	});
	if (!saved.theme) { dirty.look = true; }

	// ---------- screen 3: logo ----------
	function markPicked(grid, card) { grid.children(".logoCard").attr("aria-pressed", "false"); card.attr("aria-pressed", "true"); }
	function fitCards(grid) {
		grid.find(".logoSample").each(function () {
			var box = this, inner = box.firstElementChild, size = 24;
			if (!inner || !box.clientWidth) { return; }
			while (inner.scrollWidth > box.clientWidth - 16 && size > 10) {
				size -= 1;
				$(inner).css("font-size", size + "px").find("span").css("font-size", size + "px");
				$(inner).find("svg, img").attr({ width: size * 1.5, height: size * 1.5 }).css({ width: size * 1.5, height: size * 1.5 });
			}
		});
	}
	function drawLogos() {
		var headerCss = { "background-image": 'url("' + currentTheme().header + '")' };
		var nameGrid = $("#nameGrid").empty();
		fonts.forEach(function (f, i) {
			var keep = state.font, w = state.way; state.font = i; state.way = "name";
			var card = $('<button type="button" class="logoCard"></button>').attr("aria-pressed", i === keep && w === "name" ? "true" : "false")
				.append($('<div class="logoSample"></div>').css(headerCss).html(logoHtml(24)))
				.append($('<div class="logoLabel"></div>').text(f.label));
			state.font = keep; state.way = w;
			card.on("click", function () { state.font = i; state.way = "name"; dirty.logo = true; previewLogo = true; markPicked(nameGrid, card); applyLogo(); });
			nameGrid.append(card);
		});
		var cats = ["All"].concat(marks.map(function (m) { return m.cat; }).filter(function (c, i, a) { return a.indexOf(c) === i; }));
		$("#sampleFilter").html(cats.map(function (c) { return '<button type="button" data-c="' + esc(c) + '" aria-pressed="' + (c === sampleCat) + '">' + esc(c) + '</button>'; }).join(""));
		var sampleGrid = $("#sampleGrid").empty();
		marks.forEach(function (m, i) {
			if (sampleCat !== "All" && m.cat !== sampleCat) { return; }
			var keep = state.sample, w = state.way; state.sample = i; state.way = "sample";
			var card = $('<button type="button" class="logoCard"></button>').attr("aria-pressed", i === keep && w === "sample" ? "true" : "false")
				.append($('<div class="logoSample"></div>').css(headerCss).html(logoHtml(20)))
				.append($('<div class="logoLabel"></div>').text(m.name + " · " + m.cat));
			state.sample = keep; state.way = w;
			card.on("click", function () { state.sample = i; state.way = "sample"; dirty.logo = true; previewLogo = true; markPicked(sampleGrid, card); applyLogo(); });
			sampleGrid.append(card);
		});
		fitCards(nameGrid); fitCards(sampleGrid);
	}
	$("#sampleFilter").on("click", "button", function () { sampleCat = $(this).data("c"); drawLogos(); });
	$("#logoName").val(state.name).on("input", function () { state.name = this.value || " "; dirty.logo = true; previewLogo = true; drawLogos(); drawThemes(); applyLogo(); });
	var palette = ["#ffffff", "#1f2328", "#f4d03f", "#e67e22", "#c0392b", "#8e44ad", "#007bff", "#16a085", "#27ae60", "#7f8c8d"];
	function colourChange(key) { return function (e) { state[key] = e.value; state.colourPicked = true; dirty.logo = true; previewLogo = true; drawLogos(); applyLogo(); }; }
	$("#logoColour").kendoColorPicker({ palette: palette, columns: 10, value: state.colour, change: colourChange("colour") });
	$("#sampleColour").kendoColorPicker({ palette: palette, columns: 10, value: state.sampleColour, change: colourChange("sampleColour") });
	function syncColours() { $("#logoColour").data("kendoColorPicker").value(state.colour); $("#sampleColour").data("kendoColorPicker").value(state.sampleColour); }
	// The three ways, as buttons (Kendo UI Core has no ButtonGroup); the one chosen is the primary button.
	$.each([["name", "Your name as a logo"], ["sample", "Sample logos"], ["upload", "Upload your own"]], function (i, way) {
		$("#logoWays").append($('<button type="button" class="k-button"></button>').toggleClass("k-primary", i === 0).attr("aria-pressed", i === 0 ? "true" : "false").text(way[1]).on("click", function () {
			state.way = way[0];
			$("#logoWays button").removeClass("k-primary").attr("aria-pressed", "false");
			$(this).addClass("k-primary").attr("aria-pressed", "true");
			$(".wayPanel").removeClass("on"); $("#way" + { name: "Name", sample: "Sample", upload: "Upload" }[state.way]).addClass("on");
			drawLogos(); applyLogo();
		}));
	});
	<!--- The upload buttons (labels for hidden file boxes): open with Enter or Space too, and show the chosen file's name. --->
	$(".uploadButton").on("keydown", function (e) { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); $("#" + $(this).attr("for")).trigger("click"); } });
	$(".hiddenFile").on("change", function () { $('.fileName[data-for="' + this.id + '"]').text(this.files && this.files[0] ? this.files[0].name : ""); });
	<!--- The footer logo choice (2026-10-21). --->
	$("input[name=footerLogoMode][value=" + state.footerMode + "]").prop("checked", true);
	$("#footerLogoUpload").prop("hidden", state.footerMode !== "upload");
	$("input[name=footerLogoMode]").on("change", function () {
		state.footerMode = this.value; dirty.logo = true; previewLogo = true;
		$("#footerLogoUpload").prop("hidden", state.footerMode !== "upload");
		applyLogo();
	});
	$("#footerLogoFile").on("change", function () {
		var file = this.files && this.files[0]; if (!file) { return; }
		if (file.size > 2 * 1024 * 1024) { kendo.alert("That picture is larger than 2 MB. Please choose a smaller one."); return; }
		var reader = new FileReader();
		reader.onload = function () { state.footerUpload = reader.result; dirty.logo = true; previewLogo = true; $("#footerLogoPreview").attr("src", reader.result).prop("hidden", false); applyLogo(); };
		reader.readAsDataURL(file);
	});
	$("#logoFile").on("change", function () {
		var file = this.files && this.files[0]; if (!file) { return; }
		if (file.size > 2 * 1024 * 1024) { kendo.alert("That picture is larger than 2 MB. Please choose a smaller one."); return; }
		var reader = new FileReader();
		reader.onload = function () { state.upload = reader.result; state.way = "upload"; dirty.logo = true; previewLogo = true; $("#uploadPreview").attr("src", reader.result).prop("hidden", false); applyLogo(); };
		reader.readAsDataURL(file);
	});

	// The saved logo: an SVG with its font file inside it (so it shows in the right font everywhere), or the uploaded picture;
	// and a 1200 x 630 PNG for social media.
	function dataUrlOf(url) {
		return fetch(url).then(function (r) { if (!r.ok) { throw new Error("Can't load " + url); } return r.blob(); }).then(function (blob) {
			return new Promise(function (resolve) { var fr = new FileReader(); fr.onload = function () { resolve(fr.result); }; fr.readAsDataURL(blob); });
		});
	}
	function fontFace(name, file) {
		if (!file) { return Promise.resolve(""); }
		return dataUrlOf(file).then(function (data) {
			return '@font-face{font-family:"' + name + '";src:url(' + data.replace(/^data:[^;]*;/, "data:font/" + (/woff2$/.test(file) ? "woff2" : "woff") + ";") + ');}';
		});
	}
	function measure(text, font, size, spacing) {
		var ctx = document.createElement("canvas").getContext("2d");
		ctx.font = size + 'px "' + font + '"';
		return Math.ceil(ctx.measureText(text).width + spacing * size * text.length);
	}
	function svgDataUrl(svg) { return "data:image/svg+xml;base64," + btoa(unescape(encodeURIComponent(svg))); }
	function buildLogo() {
		var name = $.trim(state.name) || "My site";
		if (state.way === "upload") {
			if (!state.upload) { return Promise.reject("Please choose a picture, or pick one of the other two ways."); }
			return Promise.resolve({ logo: state.upload, hasName: false });
		}
		if (state.way === "sample") {
			var m = marks[state.sample], size = 40, markSize = 60, gap = 14;
			return document.fonts.load(size + 'px "Montserrat Bold"').then(function () {
				return Promise.all([fontFace("Montserrat Bold", markFontFile), m.src ? dataUrlOf(m.src) : Promise.resolve("")]);
			}).then(function (got) {
				var textW = measure(name, "Montserrat Bold", size, 0), w = markSize + gap + textW + 8, h = 80;
				var mark = m.src ? '<image x="2" y="10" width="' + markSize + '" height="' + markSize + '" href="' + got[1] + '"/>'
					: m.fileSvg ? m.fileSvg.replace(/<svg\b([^>]*)>/i, function (all, attrs) { return '<svg' + attrs.replace(/\s(width|height|x|y)="[^"]*"/gi, "") + ' x="2" y="10" width="' + markSize + '" height="' + markSize + '">'; })
					: '<svg x="2" y="10" width="' + markSize + '" height="' + markSize + '" viewBox="0 0 48 48">' + markInner(m) + '</svg>';
				return {
					logo: svgDataUrl('<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '" color="' + state.sampleColour + '"><style>' + got[0] + '</style>'
						+ mark + '<text x="' + (markSize + gap + 2) + '" y="54" font-family="Montserrat Bold, sans-serif" font-size="' + size + '" fill="' + state.sampleColour + '">' + esc(name) + '</text></svg>'),
					hasName: true
				};
			});
		}
		var f = fonts[state.font], text = f.upper ? name.toUpperCase() : name, fsize = 44;
		return document.fonts.load(fsize + 'px "' + f.font + '"').then(function () { return fontFace(f.font, f.file); }).then(function (face) {
			var w = measure(text, f.font, fsize, f.spacing) + 16, h = 80;
			return {
				logo: svgDataUrl('<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '"><style>' + face + '</style>'
					+ '<text x="8" y="56" font-family="' + f.font + ', serif" font-size="' + fsize + '"' + (f.spacing ? ' letter-spacing="' + (f.spacing * fsize).toFixed(1) + '"' : '')
					+ ' fill="' + state.colour + '">' + esc(text) + '</text></svg>'),
				hasName: true
			};
		});
	}
	function socialPng(logoUrl) {
		return new Promise(function (resolve) {
			var img = new Image();
			img.onload = function () {
				var c = document.createElement("canvas"); c.width = 1200; c.height = 630;
				var ctx = c.getContext("2d"), light = state.way === "upload" ? false : isLightColour(state.way === "sample" ? state.sampleColour : state.colour);
				ctx.fillStyle = light ? "#1f2328" : "#ffffff"; ctx.fillRect(0, 0, 1200, 630);
				var scale = Math.min(960 / (img.width || 300), 360 / (img.height || 80));
				var w = (img.width || 300) * scale, h = (img.height || 80) * scale;
				ctx.drawImage(img, (1200 - w) / 2, (630 - h) / 2, w, h);
				try { resolve(c.toDataURL("image/png")); } catch (e) { resolve(""); }
			};
			img.onerror = function () { resolve(""); };
			img.src = logoUrl;
		});
	}

	// ---------- screen 4: about ----------
	$("#aboutFirst").val(saved.firstName); $("#aboutLast").val(saved.lastName);
	$("#aboutBio").val($("<div>").html((saved.biography || "").replace(/<\/p>\s*<p>/gi, "\n\n").replace(/<br\s*\/?>/gi, "\n")).text());
	$("#aboutFacebook").val(saved.facebookUrl); $("#aboutInstagram").val(saved.instagramUrl); $("#aboutLinkedIn").val(saved.linkedInUrl); $("#aboutTwitter").val(saved.twitterUrl);
	$("#stepAbout").on("input", "input, textarea", function () { dirty.about = true; });
	$("#aboutPhotoPreview").attr("src", saved.profilePicture || baseUrl + "/images/defaultAvatar.jpg");
	$("#aboutPhoto").on("change", function () {
		var file = this.files && this.files[0]; if (!file) { return; }
		if (file.size > 8 * 1024 * 1024) { kendo.alert("That photo is larger than 8 MB. Please choose a smaller one."); return; }
		var reader = new FileReader();
		reader.onload = function () { state.photo = reader.result; dirty.about = true; $("#aboutPhotoPreview").attr("src", reader.result); };
		reader.readAsDataURL(file);
	});

	// ---------- screen 6: home page, post pictures, footer (after Starter content since 2026-10-20) ----------
	function homeLayout() { return $("input[name=homeLayout]:checked").val() || (saved.upgradedBlog ? "keep" : "posts"); }
	// The About layouts need an About page: one already made, or one ticked on Starter content.
	function aboutAvailable() { return !!saved.aboutUrl || $("#starterAbout").is(":checked"); }
	function syncHomeChoices() {
		var ok = aboutAvailable();
		$("#homeChoices input[value=featured], #homeChoices input[value=about]").prop("disabled", !ok).closest(".choice").toggleClass("disabled", !ok);
		if (!ok && (homeLayout() === "featured" || homeLayout() === "about")) { $("input[name=homeLayout][value=posts]").prop("checked", true); }
	}
	// A blog updated from an older version (2026-10-24, owner) already has a home page: keep it unless the owner picks another.
	if (saved.upgradedBlog) { $("#homeKeepChoice").show(); }
	$("input[name=homeLayout][value=" + (saved.homeLayout || (saved.upgradedBlog ? "keep" : "posts")) + "]").prop("checked", true);
	$("#homeChoices").on("change", "input", function () { dirty.home = true; previewView = "home"; previewForStep(5); });
	$("#homeChoices").on("click", ".needsAbout", function (e) { e.preventDefault(); wizard.select(4); });
	state.heroStyle = saved.heroStyle || "classic";
	[["classic", "Classic (inside the post)", '<i style="left:12%;top:30%;width:76%;height:38%"></i><u style="left:12%;top:12%;width:50%"></u><u class="soft" style="left:12%;top:78%;width:70%"></u>'],
	 ["held", "Full screen, held", '<i style="left:0;top:0;width:100%;height:100%"></i><u class="light" style="left:28%;top:46%;width:44%"></u>'],
	 ["band", "Tall band (scrolls away)", '<i style="left:0;top:0;width:100%;height:64%"></i><u class="light" style="left:8%;top:48%;width:40%"></u><u class="soft" style="left:8%;top:80%;width:70%"></u>'],
	 ["magazine", "Magazine (large heading, low left)", '<i style="left:0;top:0;width:100%;height:100%"></i><u class="light" style="left:8%;top:60%;width:55%;height:7px"></u><u class="light" style="left:8%;top:76%;width:40%;height:7px"></u>']
	].forEach(function (h) {
		var card = $('<button type="button" class="heroCard"></button>').attr("aria-pressed", h[0] === state.heroStyle ? "true" : "false")
			.append('<span class="art">' + h[2] + '</span>', $('<span class="lbl"></span>').text(h[1]));
		card.on("click", function () {
			state.heroStyle = h[0]; dirty.home = true;
			$("#heroCards .heroCard").attr("aria-pressed", "false"); card.attr("aria-pressed", "true");
			previewView = "post"; previewForStep(5);
		});
		$("#heroCards").append(card);
	});
	$("input[name=footerStyle][value=" + (saved.footer || "simple") + "]").prop("checked", true);
	$("#footerChoices").on("change", "input", function () { dirty.home = true; });
	if (saved.footerIsCustom) {
		$("#footerChoices input").prop("disabled", true).closest(".choice").addClass("disabled");
		$("#footerHint").text("You have changed the footer in Themes, so the Site Wizard leaves it as it is. Change it any time in Themes, Content.");
	}
	syncHomeChoices();
	if (stepsDone().indexOf("home") < 0) { dirty.home = true; }
	if (stepsDone().indexOf("starter") < 0) {
		dirty.starter = true;
		// ...and its posts and pages: nothing ticked to start with.
		if (saved.upgradedBlog) { $("#stepStarter input[type=checkbox]").prop("checked", false); $("#starterUpgradedNote").show(); }
	}
	$("#stepStarter").on("change", "input", function () {
		dirty.starter = true;
		// Contact form goes at the end of the About page.
		if (this.id === "starterContact" && this.checked) { $("#starterAbout").prop("checked", true); }
		if (this.id === "starterAbout" && !this.checked) { $("#starterContact").prop("checked", false); }
		previewView = this.id === "starterWelcome" ? "welcome" : "about";
		syncHomeChoices(); previewForStep(4);
	});

	// ---------- saving ----------
	function save(step, data) {
		return new Promise(function (resolve, reject) {
			$.ajax({ type: "post", url: baseUrl + "/common/cfc/ProxyController.cfc?method=saveSetup", dataType: "json",
				data: $.extend({ csrfToken: csrfToken, step: step }, data) })
				.done(function (r) {
					if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
					if (r && r.success) { if (r.stepsDone !== undefined) { saved.stepsDone = r.stepsDone; } resolve(r); }
					else { reject((r && r.errorMessage) || "This step could not be saved."); }
				})
				.fail(function (x) { reject(x.status === 403 ? "Your session has ended. Please sign in again." : "This step could not be saved (" + x.status + ")."); });
		});
	}
	// What each screen sends. A screen with nothing changed is not saved again.
	var savers = [
		function () { return save("site", { title: $.trim($("#siteTitle").val()), description: $.trim($("#siteDescription").val()), email: $.trim($("#siteEmail").val()), timeZone: $("#siteTimeZone").data("kendoDropDownList").value() })
			.then(function () { saved.title = $.trim($("#siteTitle").val()); }); },
		function () { return save("look", { themeAlias: state.theme }); },
		function () { return buildLogo().then(function (b) { return socialPng(b.logo).then(function (png) { if (state.footerMode === "upload" && !state.footerUpload) { return Promise.reject("Please choose a picture for the footer logo, or pick one of the other two choices."); }
			return save("logo", { logo: b.logo, social: png, hasName: b.hasName, footerMode: state.footerMode, footerLogo: state.footerMode === "upload" ? state.footerUpload : "" }); }); })
			.then(function () { previewLogo = false; }); },
		function () { return save("about", { firstName: $.trim($("#aboutFirst").val()), lastName: $.trim($("#aboutLast").val()), biography: $("#aboutBio").val(), aboutSite: $("#aboutSite").val(),
			facebookUrl: $.trim($("#aboutFacebook").val()), instagramUrl: $.trim($("#aboutInstagram").val()), linkedInUrl: $.trim($("#aboutLinkedIn").val()), twitterUrl: $.trim($("#aboutTwitter").val()),
			photo: state.photo || "" }).then(function () { state.photo = ""; }); },
		function () { return save("starter", { welcomePost: $("#starterWelcome").is(":checked"), aboutPage: $("#starterAbout").is(":checked"), contactForm: $("#starterContact").is(":checked") })
			.then(function (r) { ["welcomePostId", "welcomeUrl", "aboutPageId", "aboutUrl"].forEach(function (k) { if (r && r[k] !== undefined) { saved[k] = r[k]; } }); syncHomeChoices(); }); },
		function () { return save("home", { layout: homeLayout(), heroStyle: state.heroStyle, footer: saved.footerIsCustom ? "" : ($("input[name=footerStyle]:checked").val() || "simple") }); }
	];
	// Starter content comes before Home page (2026-10-20, owner): the About layouts need the About page, and the post picture styles
	// are shown on the welcome post.
	var stepKeys = ["site", "look", "logo", "about", "starter", "home"];

	// ---------- the wizard ----------
	var screens = [
		{ title: "Your site", id: "stepSite" }, { title: "Pick a look", id: "stepLook" }, { title: "Your logo", id: "stepLogo" }, { title: "About you", id: "stepAbout" },
		{ title: "Starter content", id: "stepStarter" }, { title: "Home page", id: "stepHome" }, { title: "Done", id: "stepDone" }
	];
	var busy = false;
	var wizard = $("#wizard").galaxieWizard({
		steps: screens.map(function (s, i) {
			return { title: s.title, content: '<div class="stepHolder" data-id="' + s.id + '"></div><p class="saveNote" data-note="' + i + '"></p>',
				buttons: i === 0 ? ["next"] : i === screens.length - 1 ? ["previous", "done"] : ["previous", "next"] };
		}),
		stepper: { linear: false },
		select: function (e) {
			// Leaving a screen saves it first; the move happens once the save has worked.
			var from = wizard.activeStep().options.index, to = e.step.options.index;
			if (busy) { e.preventDefault(); return; }
			// Screens drawn from the current state when they open.
			if (to === 2) { setTimeout(drawLogos, 0); }
			if (to === 6) { setTimeout(drawSummary, 0); }
			if (from < savers.length && dirty[stepKeys[from]]) {
				e.preventDefault(); busy = true;
				$("[data-note=" + from + "]").css("color", "#5d6670").text("Saving...");
				savers[from]().then(function () {
					dirty[stepKeys[from]] = false; busy = false;
					$("[data-note=" + from + "]").text("");
					if (from <= 3) { loadPreview(); }
					wizard.select(to);
					if (to === 6) { drawSummary(); }
				}, function (message) {
					busy = false;
					$("[data-note=" + from + "]").css("color", "#b00020").text(message);
				});
			}
		},
		activate: function (e) { fillHolders(); if (e.step.options.index === 2) { drawLogos(); } if (e.step.options.index === 6) { drawSummary(); } previewForStep(e.step.options.index); },
		done: function (e) {
			e.preventDefault();
			save("finish", {}).then(function () { window.location.href = baseUrl + "/"; }, function (message) { $("[data-note=6]").css("color", "#b00020").text(message); });
		}
	}).data("galaxieWizard");
	function fillHolders() { $("#wizard .stepHolder").each(function () { if (!$(this).children().length) { $(this).append($("#" + $(this).data("id"))); } }); }
	function drawSummary() {
		var done = stepsDone();
		$("#doneSummary").html(screens.slice(0, 6).map(function (s, i) {
			var ok = done.indexOf(stepKeys[i]) >= 0;
			return '<li><span>' + s.title + '</span><span><span class="state' + (ok ? " done" : "") + '">' + (ok ? "Done" : "Skipped") + '</span><a href="#" data-go="' + i + '">Change</a></span></li>';
		}).join("")
			// The starter posts, straight into the editor (2026-10-20).
			+ (saved.welcomePostId ? '<li><span>Your welcome post</span><span><a href="' + baseUrl + '/admin/?editPost=' + saved.welcomePostId + '">Edit it</a></span></li>' : "")
			+ (saved.aboutPageId ? '<li><span>Your About page</span><span><a href="' + baseUrl + '/admin/?editPost=' + saved.aboutPageId + '">Edit it</a></span></li>' : ""));
	}
	$("#doneSummary").on("click", "a[data-go]", function (e) { e.preventDefault(); wizard.select(+$(this).data("go")); });
	fillHolders();
	drawThemes(); drawLogos(); loadPreview();
	// Opens on the first screen not done yet.
	var firstOpen = stepKeys.filter(function (k) { return stepsDone().indexOf(k) < 0; })[0];
	if (firstOpen) { wizard.select(stepKeys.indexOf(firstOpen)); } else { wizard.select(6); }
	fillHolders(); drawSummary();
});
</script>
</cfif>
</body>
</html>

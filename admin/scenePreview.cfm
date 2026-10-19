<!--- Scene preview (2026-10-19, Galaxie 5): the live preview inside the Scene editor (window 107, sceneDetail.cfm), shown in an
iframe. It has no scene of its own: the editor posts the scene to it (window.postMessage, same site only) on every change, and
it rebuilds the scene with common/js/galaxieScene.js, keeping the scroll position. The editor narrows the iframe for the phone
view, so the engine's phone settings apply as they would on a phone. In the admin folder, so only a logged-in user can open it. --->
<cfsetting showdebugoutput="false">
<cfcontent type="text/html; charset=utf-8">
<cfoutput><!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>Scene preview</title>
<style>
	html, body { margin: 0; padding: 0; background: ##222; color: ##fff; font-family: Arial, Helvetica, sans-serif; }
	##scenePreviewEmpty { padding: 40px 20px; text-align: center; color: ##bbb; }
	<!--- Something below the scene to scroll into, as the post's own text would be. --->
	##scenePreviewAfter { padding: 40px 20px 60vh; color: ##ccc; text-align: center; font-size: 14px; }
</style>
</head>
<body>
<style id="scenePreviewFonts"></style>
<div id="scenePreviewEmpty">Loading the preview...</div>
<div id="scenePreviewHost"></div>
<div id="scenePreviewAfter">The post's own text starts here.</div>
<!--- With the engine's last-changed time on the address, so a changed engine is never an old cached copy (Scenes.cfc getEngineUrl). --->
<script src="#application.blog.getScenes().getEngineUrl()#"></script>
<script>
(function () {
	var baseUrl = "#jsStringFormat(application.baseUrl)#";
	var current = null;
	var waiting = null;
	var ready = false;
	var shown = null;
	<!--- The layer builder's "hold the scroll" (2026-10-19): { section, progress } keeps the scene at one point of a section's scroll -
	progress 0 to 1 through a pinned hero's pin, or through the section itself - so a depth can be changed and watched in place. --->
	var hold = null;

	function applyHold() {
		if (!hold || !shown) { return; }
		var section = (shown.sections || [])[hold.section];
		var root = section && section._root;
		if (!root) { return; }
		var start = root.getBoundingClientRect().top + window.scrollY, length = root.offsetHeight;
		window.ScrollTrigger.getAll().forEach(function (st) {
			if (st.trigger === root && st.pin) { start = st.start; length = st.end - st.start; }
		});
		window.scrollTo(0, start + Math.max(0, Math.min(1, hold.progress)) * length);
		window.ScrollTrigger.update();
	}

	function show(data) {
		shown = data;
		var host = document.getElementById("scenePreviewHost");
		var y = window.scrollY;
		if (current) { try { current.destroy(); } catch (e) {} current = null; }
		host.innerHTML = "";
		document.getElementById("scenePreviewEmpty").style.display = (data.sections && data.sections.length) ? "none" : "block";
		document.getElementById("scenePreviewEmpty").textContent = "Add a section to see the scene.";
		var container = document.createElement("div");
		host.appendChild(container);
		data.settings = data.settings || {};
		data.settings.baseUrl = baseUrl;
		document.body.style.background = data.pageColour || "##222";
		try {
			current = GalaxieScene.build(container, data);
		} catch (e) {
			host.innerHTML = '<div style="padding:20px;color:##f99">The preview could not be built: ' + String(e.message).replace(/</g, "&lt;") + '</div>';
			return;
		}
		<!--- Back to where the user was (or to the held point), after the layout settles. --->
		window.scrollTo(0, y);
		applyHold();
		setTimeout(function () { window.ScrollTrigger.refresh(); window.scrollTo(0, y); applyHold(); }, 50);
	}

	window.addEventListener("message", function (event) {
		if (event.origin !== window.location.origin || !event.data) { return; }
		if (event.data.type === "galaxieScenePreviewHold") { hold = event.data.hold || null; applyHold(); return; }
		if (event.data.type !== "galaxieScenePreview") { return; }
		if (event.data.hold !== undefined) { hold = event.data.hold || null; }
		<!--- {baseUrl} stands for the blog's address in saved scenes; the scene is sent as JSON text so it is copied exactly. --->
		var data;
		try { data = JSON.parse(String(event.data.json).split("{baseUrl}").join(baseUrl)); } catch (e) { return; }
		<!--- The @font-face rules for the blog fonts the scene uses, from the editor. --->
		document.getElementById("scenePreviewFonts").textContent = String(event.data.fontCss || "").replace(/<\//g, "");
		if (ready) { show(data); } else { waiting = data; }
	});

	GalaxieScene.ready(function () {
		ready = true;
		if (waiting) { show(waiting); waiting = null; }
		if (window.parent && window.parent !== window) { window.parent.postMessage({ type: "galaxieScenePreviewReady" }, window.location.origin); }
	});
})();
</script>
</body>
</html></cfoutput>

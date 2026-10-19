<!--- Scene cards (2026-10-19, Galaxie 5): the card styles and galaxieSceneCardThumb(sceneData, baseUrl), which draws a card's
thumbnail from the scene itself - its layers, photo or gradient, or the picture named in "thumbnail". Used by the Scene editor's
gallery (sceneDetail.cfm, window 107) and the post's Scene window (postScene.cfm, window 108). --->
<style>
	.sceneCards { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 16px; margin-top: 12px; }
	<!--- Flex column from the top: a button centres its content by default, which left shorter cards sitting lower. --->
	.sceneCard { display: flex; flex-direction: column; justify-content: flex-start; align-items: stretch; height: 100%; width: 100%; text-align: left; padding: 0; border: 1px solid rgba(128,128,128,.35); border-radius: 6px; overflow: hidden; background: transparent; color: inherit; font: inherit; cursor: pointer; }
	.sceneCard:hover, .sceneCard:focus { border-color: currentColor; outline: none; box-shadow: 0 0 0 2px rgba(128,128,128,.35); }
	.sceneCardThumb { position: relative; aspect-ratio: 16 / 9; overflow: hidden; background: #222; }
	.sceneCardThumb img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
	.sceneCardHeading { position: absolute; left: 0; right: 0; bottom: 10%; padding: 0 12px; text-align: center; color: #fff; font-size: 18px; font-weight: bold; text-shadow: 0 1px 6px rgba(0,0,0,.7); }
	.sceneCardBadge { position: absolute; top: 8px; right: 8px; padding: 2px 8px; border-radius: 10px; background: rgba(0,0,0,.55); color: #fff; font-size: 12px; }
	.sceneCardText { padding: 8px 10px 10px; }
	.sceneCardText strong { display: block; margin-bottom: 2px; }
	.sceneCardEmpty .sceneCardThumb { display: flex; align-items: center; justify-content: center; background: transparent; border-bottom: 1px dashed rgba(128,128,128,.5); font-size: 40px; opacity: .6; }
	.sceneCard.selected { border-color: currentColor; border-width: 3px; }
</style>
<script>
	window.galaxieSceneCardThumb = function (data, baseUrl) {
		function withBase(value) { return String(value || "").split("{baseUrl}").join(baseUrl); }
		var box = $('<div class="sceneCardThumb"></div>').css("background", data.pageColour || "#222");
		var s = (data.sections || [])[0] || {};
		if (data.thumbnail) {
			box.append($('<img alt="">').attr("src", withBase(data.thumbnail)));
		} else if (s.kind === "layeredHero") {
			$.each(s.layers || [], function (i, layer) { box.append($('<img alt="" loading="lazy">').attr("src", withBase(layer.src))); });
		} else if (s.image || s.poster) {
			box.append($('<img alt="" loading="lazy">').attr("src", withBase(s.imagePhone || s.image || s.poster)));
		} else if (s.gradient) {
			box.css("background", s.gradient);
		} else if (s.kind === "vantaHero") {
			box.css("background", "radial-gradient(ellipse at 50% 120%, " + ((s.options && s.options.color) || "#0e3b5c") + " 0%, " + (data.pageColour || "#0b1d2e") + " 75%)");
		} else if (s.colour) {
			box.css("background", s.colour);
		}
		if (s.kind === "vantaHero") { box.append('<span class="sceneCardBadge">Animated</span>'); }
		if (s.heading) { box.append($('<div class="sceneCardHeading"></div>').text(s.heading).css("font-family", s.headingFont || "")); }
		return box;
	};
</script>

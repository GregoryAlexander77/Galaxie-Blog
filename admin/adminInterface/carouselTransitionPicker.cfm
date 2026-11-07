<!--- The carousel transition picker (2026-11-06, owner; mock-up approved the same day): one window with every transition Galaxie can
play and a single live preview between the carousel's own pictures. One preview, not one per transition: each GL preview needs a WebGL
canvas and browsers allow only about 16 on a page. Included by carouselItems.cfm. Call:

	galaxieCarouselTransitionPicker({ pictures: [url, ...], effect: "GL", shader: "random", onUse: function (effect, shader, label) {} });

effect is GL or one of Swiper's own effects (slide, fade, cube, flip, coverflow, cards, creative); shader is the GL transition, saved with
hyphens as the GL library names it (page-curl). Renderer.cfc renderCarousel plays them with the same settings as the preview here. --->
<style>
	.ctBody { display: grid; grid-template-columns: 360px minmax(0, 1fr); }
	.ctList { overflow-y: auto; padding: 10px 12px; max-height: 64vh; }
	.ctGroup { margin: 8px 0 6px; font-weight: bold; }
	.ctGroupHint { margin: 0 0 8px; }
	.ctChoices { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }
	.ctChoices .k-button { justify-content: flex-start; text-align: left; width: 100%; }
	.ctChoices .k-button i { width: 18px; margin-right: 6px; }
	.ctChoices .k-button.ctOn { outline: 2px solid currentColor; outline-offset: -2px; }
	.ctPreviewSide { min-width: 0; padding: 14px; display: flex; flex-direction: column; gap: 10px; }
	.ctPreview { position: relative; width: 100%; aspect-ratio: 16 / 9; border-radius: 4px; overflow: hidden; background: #000; }
	.ctPreview .swiper { width: 100%; height: 100%; }
	/* Not for GL: the GL stylesheet hides these pictures so its canvas shows (a display: block here covered the GL transitions). */
	.ctPreview .swiper:not(.swiper-gl) .swiper-slide img { width: 100%; height: 100%; object-fit: cover; display: block; }
	.ctNow { font-weight: bold; }
	.ctFooter { display: flex; justify-content: flex-end; gap: 8px; padding: 10px 14px; }
</style>
<script>
(function () {
	var SIMPLE = [
		{ value: "slide", name: "Slide", icon: "fa-arrow-right-long", hint: "The next picture slides in." },
		{ value: "fade", name: "Fade", icon: "fa-circle-half-stroke", hint: "One picture fades into the next." },
		{ value: "cube", name: "Cube", icon: "fa-cube", hint: "The pictures turn like the sides of a cube." },
		{ value: "flip", name: "Flip", icon: "fa-repeat", hint: "Each picture flips over like a card." },
		{ value: "coverflow", name: "Coverflow", icon: "fa-layer-group", hint: "Pictures swing in at an angle." },
		{ value: "cards", name: "Cards", icon: "fa-clone", hint: "A stack of cards; the top one moves aside." },
		{ value: "creative", name: "Push back", icon: "fa-arrows-to-dot", hint: "The old picture sinks back as the new one arrives." }
	];
	var GL = [
		["random", "Random", "fa-shuffle", "A different one each time."], ["dots", "Dots", "fa-braille", "Breaks into dots."], ["flyeye", "Fly eye", "fa-eye", "A fly's-eye shimmer."],
		["morph-x", "Morph across", "fa-left-right", "Melts sideways."], ["morph-y", "Morph down", "fa-up-down", "Melts downwards."], ["page-curl", "Page curl", "fa-book-open", "Turns like a page."],
		["peel-x", "Peel across", "fa-scroll", "Peels off sideways."], ["peel-y", "Peel down", "fa-scroll", "Peels off downwards."], ["polygons-fall", "Polygons fall", "fa-shapes", "Shatters and falls."],
		["polygons-morph", "Polygons morph", "fa-shapes", "Shatters and reforms."], ["polygons-wind", "Polygons wind", "fa-wind", "Shatters and blows away."], ["pixelize", "Pixelize", "fa-border-all", "Turns into blocks."],
		["ripple", "Ripple", "fa-water", "Ripples like water."], ["shutters", "Shutters", "fa-grip-lines", "Opens like blinds."], ["slices", "Slices", "fa-bars", "Slides in slices."],
		["squares", "Squares", "fa-table-cells", "Changes square by square."], ["stretch", "Stretch", "fa-arrows-left-right", "Stretches across."], ["wave-x", "Wave", "fa-water", "A wave passes over."],
		["wind", "Wind", "fa-wind", "Blows away like dust."]
	].map(function (r) { return { value: r[0], name: r[1], icon: r[2], hint: r[3], gl: true }; });

	<!--- The label for a saved effect and shader ("GL · Page curl", "Fade"). Older carousels saved the shader with a space. --->
	window.galaxieCarouselTransitionLabel = function (effect, shader) {
		effect = (effect || "GL").toLowerCase();
		if (effect === "gl") {
			var key = (shader || "random").toLowerCase().replace(/ /g, "-");
			var t = GL.filter(function (g) { return g.value === key; })[0];
			return "GL · " + (t ? t.name : "Random");
		}
		var s = SIMPLE.filter(function (g) { return g.value === effect; })[0];
		return s ? s.name : "Slide";
	};

	<!--- Swiper and its GL add-on, the same files a carousel on a page loads (Renderer.cfc renderCarousel), once. --->
	function withSwiper(done) {
		if (window.Swiper && window.SwiperGL) { done(); return; }
		if (!document.getElementById("galaxieSwiperCss")) {
			$("head").append('<link id="galaxieSwiperCss" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@10/swiper-bundle.min.css"><link rel="stylesheet" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/swiper/viper/swiper-gl.min.css">');
		}
		var load = function (src, next) { var s = document.createElement("script"); s.src = src; s.onload = next; document.head.appendChild(s); };
		var gl = function () { if (window.SwiperGL) { done(); } else { load("<cfoutput>#application.baseUrl#</cfoutput>/common/libs/swiper/viper/swiper-gl.min.js", done); } };
		if (window.Swiper) { gl(); } else { load("https://cdn.jsdelivr.net/npm/swiper@10/swiper-bundle.min.js", gl); }
	}

	window.galaxieCarouselTransitionPicker = function (opts) {
		opts = opts || {};
		var pictures = (opts.pictures || []).filter(Boolean);
		<!--- A transition needs two pictures to show: with one, a plain dark picture goes beside it. --->
		if (pictures.length < 2) {
			var c = document.createElement("canvas"); c.width = 16; c.height = 9; var x = c.getContext("2d"); x.fillStyle = "#2b2b2b"; x.fillRect(0, 0, 16, 9);
			pictures.push(c.toDataURL("image/png"));
		}
		var startGl = (opts.effect || "GL").toLowerCase() === "gl";
		var startKey = startGl ? (opts.shader || "random").toLowerCase().replace(/ /g, "-") : (opts.effect || "slide").toLowerCase();
		var chosen = (startGl ? GL : SIMPLE).filter(function (t) { return t.value === startKey; })[0] || GL[0];
		var showing = null, swiper = null, hoverTimer = null;

		var box = $('<div id="carouselTransitionPickerWindow"></div>').appendTo("body");
		box.html(
			'<div class="ctBody">' +
				'<div class="ctList">' +
					'<div class="ctGroup">Simple</div><div class="ctGroupHint k-form-hint">Light and quick, and they work everywhere.</div><div class="ctChoices ctSimple"></div>' +
					'<div class="ctGroup" style="margin-top: 14px;">GL</div><div class="ctGroupHint k-form-hint">Drawn with the graphics card (WebGL): richer, a little heavier.</div><div class="ctChoices ctGl"></div>' +
				'</div>' +
				'<div class="ctPreviewSide k-alt">' +
					'<div class="ctPreview"></div>' +
					'<div><span class="ctNow"></span> <span class="k-form-hint ctNowHint"></span></div>' +
					'<div class="k-form-hint">Point at a transition to see it; click to choose it.</div>' +
				'</div>' +
			'</div>' +
			'<div class="ctFooter k-alt"><button type="button" class="k-button ctCancel">Cancel</button><button type="button" class="k-button k-primary ctUse">Use this</button></div>');
		var button = function (t) { return $('<button type="button" class="k-button normalFontWeight"></button>').html('<i class="fontAwesomeIcon fas ' + t.icon + '"></i>').append(document.createTextNode(t.name)).data("t", t); };
		SIMPLE.forEach(function (t) { box.find(".ctSimple").append(button(t)); });
		GL.forEach(function (t) { box.find(".ctGl").append(button(t)); });
		var mark = function () {
			box.find(".ctChoices .k-button").removeClass("ctOn").filter(function () { var t = $(this).data("t"); return t === chosen; }).addClass("ctOn");
		};

		<!--- The preview: the old carousel comes down, and its WebGL canvas is let go of, before the next one is made. --->
		var stop = function () {
			if (!swiper) { return; }
			box.find(".ctPreview canvas").each(function () { try { var g = this.getContext("webgl") || this.getContext("experimental-webgl"); var ext = g && g.getExtension("WEBGL_lose_context"); if (ext) { ext.loseContext(); } } catch (e) {} });
			try { swiper.destroy(true, true); } catch (e) {}
			swiper = null;
		};
		var play = function (t) {
			if (showing === t) { return; }
			showing = t;
			box.find(".ctNow").text(t.name); box.find(".ctNowHint").text(t.hint);
			stop();
			var preview = box.find(".ctPreview");
			preview.html('<div class="swiper"><div class="swiper-wrapper">' + pictures.map(function (src) { return '<div class="swiper-slide"><img src="' + String(src).replace(/"/g, "&quot;") + '" alt="" class="swiper-gl-image"></div>'; }).join("") + '</div></div>');
			var o = { rewind: true, speed: t.gl ? 1200 : 800, autoplay: { delay: 1400, disableOnInteraction: false }, allowTouchMove: false };
			if (t.gl) { o.modules = [window.SwiperGL]; o.effect = "gl"; o.gl = { shader: t.value }; }
			else {
				o.effect = t.value;
				<!--- The same settings as Renderer.cfc renderCarousel. --->
				o.fadeEffect = { crossFade: true };
				o.coverflowEffect = { rotate: 50, depth: 120, slideShadows: true };
				o.creativeEffect = { prev: { shadow: true, translate: [0, 0, -400] }, next: { translate: ["100%", 0, 0] } };
			}
			try { swiper = new window.Swiper(preview.find(".swiper")[0], o); } catch (e) {}
		};

		box.find(".ctChoices").on("mouseenter", ".k-button", function () { var t = $(this).data("t"); clearTimeout(hoverTimer); hoverTimer = setTimeout(function () { play(t); }, 150); });
		box.find(".ctChoices").on("mouseleave", function () { clearTimeout(hoverTimer); hoverTimer = setTimeout(function () { play(chosen); }, 400); });
		box.find(".ctChoices").on("click", ".k-button", function () { chosen = $(this).data("t"); mark(); play(chosen); });

		var win = box.kendoWindow({
			title: "Carousel transition", modal: true, width: Math.min(1100, Math.round(window.innerWidth * 0.96)) + "px", actions: ["Close"],
			close: function () { clearTimeout(hoverTimer); stop(); setTimeout(function () { try { win.destroy(); } catch (e) {} }, 0); }
		}).data("kendoWindow");
		box.find(".ctCancel").on("click", function () { win.close(); });
		box.find(".ctUse").on("click", function () {
			var effect = chosen.gl ? "GL" : chosen.value, shader = chosen.gl ? chosen.value : "";
			if (typeof opts.onUse === "function") { opts.onUse(effect, shader, window.galaxieCarouselTransitionLabel(effect, shader)); }
			win.close();
		});
		win.center().open();
		mark();
		withSwiper(function () { play(chosen); });
	};
})();
</script>

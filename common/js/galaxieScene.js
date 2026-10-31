/*
	Galaxie Scenes engine (Galaxie Blog 5, 2026-10-19). Builds a scrolling scene - heroes, text blocks and image slides - from a
	plain data description, with GSAP 3 + ScrollTrigger. Replaces the 2019 ScrollMagic templates in includes/postContent/parallax/,
	which keep working until each post is moved over. Design: doc/aiDraftArticles/parallaxScenesDesign.cfm.

	GSAP is loaded from cdnjs with Subresource Integrity, so the browser refuses the files if they were ever changed; if cdnjs
	can't be reached (a firewall, a privacy blocker), the same files are loaded from this server, when the blog has them in
	common/libs/gsap3/. The blog owner can also choose "this server only" (no third party): the page tells the engine in
	window.GalaxieSceneConfig = { source: "cdn" or "local", localBase: ".../common/libs/gsap3/", local: ["gsap.min.js", ...] }.
	GalaxieScene.ready(callback, data) loads GSAP and the plugins the scene's effects need.

	Plugins and effects (2026-10-19): PLUGINS lists the GSAP plugins the engine knows. An effect names the plugin it needs, and
	falls back to the plain rise when that plugin can't be loaded, so a scene never breaks. To add a plugin: one entry in
	PLUGINS (file, integrity, global) and the effect that uses it (see NEEDS and animateReveals). Never use this on a page that still loads TweenMax 2 / ScrollMagic: GSAP 3 defines the same global names.

	Usage:
		GalaxieScene.ready(function () {
			var scene = GalaxieScene.build(document.getElementById("myScene"), sceneData);
			// scene.destroy() removes the animations (the markup stays)
		});

	sceneData:
		{
			pageColour: "#392630",                 // the color around the scene
			settings: {                             // defaults for every section; a section can override any of them
				scrub: true,                        // true = exactly with the scroll, 0.5 = glides half a second behind
				intensity: 1,                       // how far layered heroes move (1 = the deepest layer travels one screen)
				pinLength: "200%",                  // how long heroes stay pinned
				fadeHeight: "35vh",                 // the fade from a hero into the next section
				rise: 160,                          // how far headings and text rise as they come in, in pixels
				guides: false,                      // ScrollTrigger markers - for the editor's preview only
				phoneMotion: "full",                // "full" or "light" (half the movement on phones)
				baseUrl: ""                         // the blog's base URL, for loading Three.js and Vanta on demand
			},
			sections: [ { kind: ..., ... }, ... ]
		}

	Every section can have: heading, html (rich text), a button (buttonText, buttonUrl - a web address or a path on the site -,
	buttonColour, buttonTextColour), colour (its top color - the next hero's fade uses it), gradient or
	background, textColour, headingFont, textFont, headingSize, textSize, headingSizePhone, textSizePhone, align
	("left"|"center"|"right"), shadow ("none"|"soft"|"strong"|"glow"), shadowColour, glow ({ colour, opacity 0-1, softness px },
	on its own or with the shadow), overlay ({ colour, opacity }).
	Heroes can also have (2026-10-19, post heroes): height ("75vh"; a full screen when not set), pin (false: no hold - the hero
	scrolls away with the page while its picture zooms and its text fades) and textPosition ("center", or "bottom" for a large
	heading low on the left).

	Kinds:
		text          a heading and rich text on a gradient or color
		imageSlide    a full-screen picture whose background moves slower than the page: image, imagePhone
		map           one of the blog's Azure maps, live (2026-10-20, owner), with a heading and text, on a color or gradient like a
		              text block: mapId, mapType (static or route), mapHeight (percent of the screen: 50, 70 or 100). Drawn by
		              preview/maps.cfm in a frame, as a map in a post is.
		form          one of the blog's forms (2026-10-19, owner), with a heading and text, on a color or gradient like a text block:
		              form (its alias), formTitle. Shown on the blog by common/js/webForms.js, as a form placed in a post is.
		slideshow     pictures with captions, held in place while each scroll brings in the next (2026-10-19, owner): slides
		              [{ image, imagePhone, heading, caption }], colour (behind the pictures)
		layeredHero   pinned image layers moving at different depths: layers [{ src, srcPhone, depth }]
		photoHero     one pinned photo with a slow zoom: image, imagePhone, zoom (1.15)
		vantaHero     a Vanta animation: effect ("WAVES", "NET", "BIRDS"...), options ({ color: 0x..., ... })
		gradientHero  a pinned gradient
		videoHero     a muted looping background video: video, poster
	All heroes pin, let their heading rise and fade, fade into the next section's color, and let the next section rise over
	them (the curtain).
*/
(function (window, document) {
	"use strict";

	var DEFAULTS = { scrub: true, intensity: 1, pinLength: "200%", fadeHeight: "35vh", rise: 160, guides: false, phoneMotion: "full", baseUrl: "" };
	var HERO_KINDS = { layeredHero: 1, photoHero: 1, vantaHero: 1, gradientHero: 1, videoHero: 1 };
	var SHADOWS = {
		soft: function (c) { return "0 2px 6px " + rgba(c, 0.65); },
		strong: function (c) { return "0 3px 12px " + rgba(c, 0.85) + ", 0 0 2px " + rgba(c, 0.9); },
		glow: function (c) { return "0 0 10px " + rgba(c, 0.9) + ", 0 0 26px " + rgba(c, 0.7); }
	};
	var scriptPromises = {};
	// GSAP 3.15.0, with the SHA-512 hashes of the files on cdnjs (the copies in common/libs/gsap3/ are the same files).
	var CDN = "https://cdnjs.cloudflare.com/ajax/libs/gsap/3.15.0/";
	var CORE = [
		{ file: "gsap.min.js", global: "gsap", integrity: "sha512-oJ8QbaQThQoJZ7oEv+29jfPM6CcP+zUxh3PKJs1vyOhx0UraUrE7PQgeItu3dOuCJyrzWpoYMsVjkkPEBzbUqw==" },
		{ file: "ScrollTrigger.min.js", global: "ScrollTrigger", integrity: "sha512-OaIE7ud4P04EhnBuhEcm0wQSceIxbi2pV03oBLS/+F6ampfxsnxcIxOp7H2eF9G7N0kEht0VAzOLG+dTLSo17Q==" }
	];
	// The GSAP plugins the engine knows. Only loaded on a page whose scene uses an effect that needs one.
	var PLUGINS = {
		SplitText: { file: "SplitText.min.js", global: "SplitText", integrity: "sha512-LFdAHEel9Gwq2HmgZUgnl3mLwXjC6nrfMU6IRLA2AOaKQaWgdrT8ZlmI2ZjVkgB32TeYyi7KdD80ihb9W6uH8Q==" }
	};
	// Which plugin each effect needs: headingEffect "words" and "letters" split the heading with SplitText.
	var NEEDS = { headingEffect: { words: "SplitText", letters: "SplitText" } };
	function config() { return window.GalaxieSceneConfig || { source: "cdn", local: [] }; }
	var stylesAdded = false;

	/* ---------- small helpers ---------- */

	function setting(data, section, name) {
		if (section && section[name] !== undefined && section[name] !== null && section[name] !== "") { return section[name]; }
		if (data.settings && data.settings[name] !== undefined) { return data.settings[name]; }
		return DEFAULTS[name];
	}

	function el(tag, className, parent) {
		var e = document.createElement(tag);
		if (className) { e.className = className; }
		if (parent) { parent.appendChild(e); }
		return e;
	}

	// "#000", "#000000" or "rgb(...)" -> rgba with an alpha; anything else is returned as it is.
	function rgba(colour, alpha) {
		colour = colour || "#000000";
		var hex = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(colour);
		if (hex) {
			var h = hex[1].length === 3 ? hex[1].replace(/(.)/g, "$1$1") : hex[1];
			return "rgba(" + parseInt(h.substr(0, 2), 16) + "," + parseInt(h.substr(2, 2), 16) + "," + parseInt(h.substr(4, 2), 16) + "," + alpha + ")";
		}
		var rgb = /^rgba?\(([^,]+),([^,]+),([^,)]+)/i.exec(colour);
		return rgb ? "rgba(" + rgb[1] + "," + rgb[2] + "," + rgb[3] + "," + alpha + ")" : colour;
	}

	function isPhone() { return window.matchMedia("(max-width: 768px)").matches; }

	function loadScript(src, integrity) {
		if (!scriptPromises[src]) {
			scriptPromises[src] = new Promise(function (resolve, reject) {
				var tag = document.createElement("script");
				tag.src = src; tag.async = false; tag.onload = resolve; tag.onerror = reject;
				if (integrity) { tag.integrity = integrity; tag.crossOrigin = "anonymous"; tag.referrerPolicy = "no-referrer"; }
				document.head.appendChild(tag);
			});
		}
		return scriptPromises[src];
	}

	// The engine's own CSS, added once. Kept here so the engine is one file; themes can still override it.
	function addStyles() {
		if (stylesAdded) { return; }
		stylesAdded = true;
		var css = [
			// clip, not hidden (2026-10-30): overflow-x:hidden turned the scene into a scroll box with its own scrollbar, a dark
			// strip down the right of a scene inside a post. hidden stays for browsers without clip.
			// z-index 0 (2026-10-31, owner): its own layer under the blog's floating menu (#fixedNavHeader, z-index 1) - a held hero
			// is fixed to the screen while it plays and, coming later in the page at the same level, was drawn over the menu.
			".gScene{position:relative;z-index:0;overflow-x:hidden;overflow-x:clip}",
			".gScene *{box-sizing:border-box}",
			".gScene .gs-section{position:relative;z-index:2}",
			".gScene .gs-softTop{position:relative;z-index:2;pointer-events:none}",
			".gScene .gs-text{padding:12vh 8vw;min-height:60vh;display:flex;flex-direction:column;justify-content:center}",
			// The theme's header and body fonts (2026-10-21), set by the page (blogContentCss.cfm, scenePreview.cfm); a section's own
			// font, set on the element, still wins.
			".gScene .gs-heading{font-family:var(--galaxieSceneHeadingFont,inherit);font-size:clamp(1.4rem,3vw,2.4rem);margin:0 0 .6em;line-height:1.2}",
			".gScene .gs-body{font-family:var(--galaxieSceneTextFont,inherit);font-size:clamp(1rem,1.6vw,1.3rem);line-height:1.5}",
			".gScene .gs-body p{margin:0 0 .8em;max-width:60ch}",
			".gScene .gs-align-center{text-align:center;align-items:center}.gScene .gs-align-center .gs-body p{margin-left:auto;margin-right:auto}",
			".gScene .gs-align-right{text-align:right;align-items:flex-end}",
			".gScene .gs-hero{position:relative;height:100vh;overflow:hidden;z-index:1}",
			".gScene .gs-heroBack{position:absolute;inset:0}",
			".gScene .gs-layer{position:absolute;inset:0;will-change:transform}",
			".gScene .gs-layer img,.gScene .gs-photo img{display:block;width:100%;height:100vh;object-fit:cover;object-position:50% 50%}",
			".gScene .gs-photo{position:absolute;inset:0;will-change:transform}",
			// A picture that turns while scrolling (section.spin, degrees): a square that covers the screen at any angle, centred.
			".gScene .gs-photo.gs-spin,.gScene .gs-slideBack.gs-spin{left:50%;top:50%;right:auto;bottom:auto;width:150vmax;height:150vmax}",
			".gScene .gs-photo.gs-spin img{height:100%}",
			".gScene .gs-video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}",
			".gScene .gs-overlay{position:absolute;inset:0;pointer-events:none;z-index:2}",
			".gScene .gs-heroText{position:absolute;inset:0;display:flex;flex-direction:column;justify-content:center;padding:0 8vw;z-index:3}",
			".gScene .gs-heroText .gs-heading{font-size:clamp(2rem,6vw,4.5rem)}",
			".gScene .gs-heroText.gs-textBottom{justify-content:flex-end;padding-bottom:16vh;text-align:left;align-items:flex-start}",
			// Low text follows the hero's own align when it is center or right (2026-10-24); left stays the default.
			".gScene .gs-heroText.gs-textBottom.gs-align-center{text-align:center;align-items:center}",
			".gScene .gs-heroText.gs-textBottom.gs-align-right{text-align:right;align-items:flex-end}",
			".gScene .gs-hero.gs-sized .gs-photo img{height:100%}",
			".gScene .gs-fade{position:absolute;left:0;width:100%;bottom:0;pointer-events:none;z-index:4}",
			".gScene .gs-fadeSolid{position:absolute;left:0;width:100%;height:300vh;top:calc(100% - 2px);pointer-events:none}",
			".gScene .gs-slide{height:100vh;overflow:hidden;display:flex;flex-direction:column;justify-content:center;padding:0 8vw}",
			".gScene .gs-slideBack{position:absolute;left:0;right:0;top:-20%;height:140%;background-size:cover;background-position:center;will-change:transform}",
			".gScene .gs-slide .gs-heading{font-size:clamp(1.6rem,4vw,3rem)}",
			".gScene .gs-slideText{position:relative;z-index:3}",
			// A button under the heading and text (2026-10-19, owner): to another page, post or site.
			".gScene .gs-button{display:inline-block;align-self:flex-start;margin-top:1.4em;padding:.75em 1.6em;border-radius:999px;background:#ffffff;color:#1f2328;font-weight:bold;text-decoration:none;font-size:clamp(1rem,1.4vw,1.15rem);line-height:1.2;box-shadow:0 4px 14px rgba(0,0,0,.25);text-shadow:none;transition:transform .15s ease}",
			".gScene .gs-button:hover,.gScene .gs-button:focus{transform:translateY(-2px)}",
			".gScene .gs-align-center .gs-button{align-self:center}.gScene .gs-align-right .gs-button{align-self:flex-end}",
			// The slideshow (2026-10-19): the slides on top of each other, each fading in over the one before.
			".gScene .gs-slideshow{position:relative;height:100vh;overflow:hidden}",
			".gScene .gs-showSlide{position:absolute;inset:0}",
			".gScene .gs-showPic{position:absolute;inset:0;background-size:cover;background-position:center;will-change:transform}",
			".gScene .gs-showText{position:absolute;left:0;right:0;bottom:0;padding:14vh 8vw 9vh;display:flex;flex-direction:column;background:linear-gradient(to bottom,rgba(0,0,0,0),rgba(0,0,0,.55))}",
			".gScene .gs-showText .gs-heading{font-size:clamp(1.6rem,4vw,3rem);margin-bottom:.3em}",
			".gScene .gs-showDots{position:absolute;right:18px;top:50%;transform:translateY(-50%);display:flex;flex-direction:column;gap:10px;z-index:3}",
			".gScene .gs-showDots span{width:10px;height:10px;border-radius:50%;background:rgba(255,255,255,.45);box-shadow:0 0 3px rgba(0,0,0,.5);transition:background .2s}",
			".gScene .gs-showDots span.gs-on{background:#ffffff}",
			// With motion turned off: the pictures one after another, nothing held.
			".gScene .gs-slideshow.gs-static{height:auto}.gScene .gs-static .gs-showSlide{position:relative;height:80vh;opacity:1!important}.gScene .gs-static .gs-showDots{display:none}",
			// A form (2026-10-19): as wide as a comfortable form; the note is replaced by the form itself once it loads.
			".gScene .gs-formHolder{margin-top:1.2em;max-width:640px;width:100%}.gScene .gs-align-center .gs-formHolder{margin-left:auto;margin-right:auto}.gScene .gs-align-right .gs-formHolder{margin-left:auto}",
			".gScene .gs-formNote{display:block;padding:18px;border:2px dashed currentColor;border-radius:8px;opacity:.75;text-align:center}",
			// A map (2026-10-20): as wide as the section, rounded, its height a share of the screen.
			".gScene .gs-mapHolder{margin-top:1.2em;width:100%}.gScene .gs-mapHolder iframe{display:block;width:100%;border:0;border-radius:8px;background:rgba(128,128,128,.2)}",
			".gScene .gs-reveal{opacity:0}",
			"@media (prefers-reduced-motion: reduce){.gScene .gs-reveal{opacity:1}}"
		].join("\n");
		var style = el("style");
		style.id = "galaxieSceneStyles";
		style.appendChild(document.createTextNode(css));
		document.head.appendChild(style);
	}

	/* ---------- the look of a section: fonts, sizes, colors, shadows, overlay ---------- */

	function applyLook(section, root, headingEl, bodyEl) {
		if (section.textColour) { root.style.color = section.textColour; }
		if (section.align) { root.classList.add("gs-align-" + section.align); }
		var phone = isPhone();
		if (headingEl) {
			if (section.headingFont) { headingEl.style.fontFamily = section.headingFont; }
			var hs = phone && section.headingSizePhone ? section.headingSizePhone : section.headingSize;
			if (hs) { headingEl.style.fontSize = hs; }
		}
		if (bodyEl) {
			if (section.textFont) { bodyEl.style.fontFamily = section.textFont; }
			var ts = phone && section.textSizePhone ? section.textSizePhone : section.textSize;
			if (ts) { bodyEl.style.fontSize = ts; }
		}
		var shadow = SHADOWS[section.shadow];
		var parts = [];
		if (shadow) { parts.push(shadow(section.shadowColour || "#000000")); }
		// A glow of its own, with or without the shadow - the same as Renderer.cfc getGlowCss: a tight core and a wider halo.
		if (section.glow && section.glow.colour) {
			var a = section.glow.opacity !== undefined && section.glow.opacity !== "" ? Math.min(1, Math.max(0.1, +section.glow.opacity)) : 0.8;
			var soft = Math.min(60, Math.max(4, +section.glow.softness || 24));
			parts.push("0 0 " + Math.max(2, Math.round(soft / 2.5)) + "px " + rgba(section.glow.colour, a) + ", 0 0 " + soft + "px " + rgba(section.glow.colour, Math.round(a * 70) / 100));
		}
		if (parts.length) {
			var value = parts.join(", ");
			if (headingEl) { headingEl.style.textShadow = value; }
			if (bodyEl) { bodyEl.style.textShadow = value; }
		}
	}

	function addOverlay(section, parent) {
		if (!section.overlay || !section.overlay.opacity) { return; }
		var o = el("div", "gs-overlay", parent);
		o.style.backgroundColor = section.overlay.colour || "#000000";
		o.style.opacity = section.overlay.opacity;
	}

	// A button's address: a web address or a path on this site, nothing that could run script.
	function safeUrl(url) { url = String(url || "").trim(); return /^(https?:\/\/|\/(?!\/))/i.test(url) ? url : ""; }

	function addText(section, parent, headingTag) {
		var heading = null, body = null, button = null;
		if (section.heading) {
			heading = el(headingTag || "h2", "gs-heading gs-reveal", parent);
			heading.textContent = section.heading;
		}
		if (section.html) {
			body = el("div", "gs-body gs-reveal", parent);
			// Rich text written by the blog owner in the editor (TinyMCE) - the same trust as a post's body.
			body.innerHTML = section.html;
		}
		if (section.buttonText && safeUrl(section.buttonUrl)) {
			button = el("a", "gs-button gs-reveal", parent);
			button.textContent = section.buttonText;
			button.href = safeUrl(section.buttonUrl);
			if (section.buttonColour) { button.style.backgroundColor = section.buttonColour; }
			if (section.buttonTextColour) { button.style.color = section.buttonTextColour; }
		}
		return { heading: heading, body: body, button: button };
	}

	/* ---------- markup for each kind ---------- */

	function buildText(section, root) {
		root.classList.add("gs-text");
		if (section.gradient) { root.style.background = section.gradient; }
		else if (section.background || section.colour) { root.style.background = section.background || section.colour; }
		// No text color of its own (2026-10-19): white on a dark background, near-black on a light one - never the theme's
		// own text color, which on a post is usually dark, and unreadable on a dark section.
		if (!section.textColour) { root.style.color = isLight(section.colour || ((/(#[0-9a-f]{6})/i.exec(section.gradient || "") || [])[1]) || "") ? "#1f2328" : "#ffffff"; }
		var t = addText(section, root);
		applyLook(section, root, t.heading, t.body);
	}

	// Whether a #rrggbb color is light (perceived brightness); anything else counts as dark.
	function isLight(colour) {
		var m = /^#([0-9a-f]{6})$/i.exec(String(colour).trim());
		if (!m) { return false; }
		var n = parseInt(m[1], 16), r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
		return (0.299 * r + 0.587 * g + 0.114 * b) > 150;
	}

	function buildSlide(section, root) {
		root.classList.add("gs-slide");
		var back = el("div", "gs-slideBack", root);
		var image = isPhone() && section.imagePhone ? section.imagePhone : section.image;
		if (image) { back.style.backgroundImage = 'url("' + image + '")'; }
		if (+section.spin) { back.classList.add("gs-spin"); gsap.set(back, { xPercent: -50, yPercent: -50 }); }
		addOverlay(section, root);
		var holder = el("div", "gs-slideText", root);
		if (!section.textColour) { root.style.color = "#ffffff"; }
		if (!section.shadow) { section.shadow = "soft"; }
		var t = addText(section, holder);
		applyLook(section, root, t.heading, t.body);
	}

	// A form: a text block, then the form's placeholder, the same markup a form placed in a post has.
	function buildForm(section, root) {
		buildText(section, root);
		// In the editor, a ready-made form picked but not made yet (it's made when the scene is saved) shows by its name.
		if (!section.form && section.pendingReadyMade) {
			el("span", "gs-formNote", el("div", "gs-formHolder gs-reveal", root)).textContent = "[Form: " + (section.formTitle || "ready-made form") + ", made when you save]";
			return;
		}
		if (!/^[a-z0-9-]{1,100}$/i.test(String(section.form || ""))) { return; }
		var holder = el("div", "gs-formHolder gs-reveal", root);
		var placeholder = el("div", "galaxieWebForm", holder);
		placeholder.setAttribute("data-webform", section.form);
		var note = el("span", "gs-formNote", placeholder);
		note.textContent = "[Form: " + (section.formTitle || section.form) + "]";
	}

	// A product from the shop (2026-10-21): a text block, then the product's card with its Add to cart button (common/js/shop.js),
	// or every product for "*". Where the shop script can't run (the editor's preview), the placeholder shows the product's name.
	function buildProduct(section, root) {
		buildText(section, root);
		var alias = String(section.product || "");
		if (alias !== "*" && !/^[a-z0-9-]{1,100}$/i.test(alias)) { return; }
		var holder = el("div", "gs-formHolder gs-reveal", root);
		var placeholder = el("div", "galaxieProduct", holder);
		placeholder.setAttribute("data-product", alias);
		var note = el("span", "gs-formNote", placeholder);
		note.textContent = "[Product: " + (section.productName || (alias === "*" ? "All products" : alias)) + "]";
	}

	// A map: a text block, then the map, live, in a frame - the same page (preview/maps.cfm) a map in a post shows.
	function buildMap(data, section, root) {
		buildText(section, root);
		var mapId = parseInt(section.mapId, 10);
		if (!(mapId > 0)) { return; }
		var holder = el("div", "gs-mapHolder gs-reveal", root);
		var frame = el("iframe", "", holder);
		var height = { "50": 50, "70": 70, "100": 100 }[String(section.mapHeight || "70")] || 70;
		frame.style.height = height + "vh";
		frame.setAttribute("title", section.heading || "Map");
		frame.setAttribute("loading", "lazy");
		frame.setAttribute("allowfullscreen", "allowfullscreen");
		frame.src = setting(data, section, "baseUrl") + "/preview/maps.cfm?mapId=" + mapId + "&mapType=" + (section.mapType === "route" ? "route" : "static") + "&thumbnail=false";
	}

	// Forms load after the page does (common/js/webForms.js), and a scene's content comes later still, so the scene starts the form
	// loader itself. Where there is none (the editor's preview), the placeholder shows the form's name.
	// Products the same way (2026-10-21): the shop script is downloaded when the scene has one.
	function startShop(container, data) {
		if (!container.querySelector(".galaxieProduct[data-product]") || !window.galaxieLoader || !window.galaxieLoader.shop) { return; }
		window.galaxieLoader.shop(function () {
			if (window.galaxieShop) { window.galaxieShop.init({ baseUrl: setting(data, null, "baseUrl") }); }
		});
	}

	function startForms(container, data) {
		if (!container.querySelector(".galaxieWebForm[data-webform]") || !window.galaxieLoader || !window.galaxieLoader.webForms) { return; }
		window.galaxieLoader.webForms(function () {
			if (window.galaxieWebForms) { window.galaxieWebForms.init({ baseUrl: setting(data, null, "baseUrl") }); }
		});
	}

	function buildSlideshow(section, root) {
		root.classList.add("gs-slideshow");
		root.style.background = section.colour || "#111111";
		if (!section.textColour) { root.style.color = "#ffffff"; }
		if (!section.shadow) { section.shadow = "soft"; }
		var phone = isPhone(), slides = section.slides || [], dots = slides.length > 1 ? el("div", "gs-showDots") : null;
		slides.forEach(function (slide, i) {
			var box = el("div", "gs-showSlide", root);
			if (i) { box.style.opacity = 0; }
			var pic = el("div", "gs-showPic", box);
			var image = phone && slide.imagePhone ? slide.imagePhone : slide.image;
			if (image) { pic.style.backgroundImage = 'url("' + String(image).replace(/"/g, "%22") + '")'; }
			if (slide.alt) { pic.setAttribute("role", "img"); pic.setAttribute("aria-label", slide.alt); }
			if (slide.heading || slide.caption) {
				var text = el("div", "gs-showText", box), heading = null, body = null;
				if (slide.heading) { heading = el("h2", "gs-heading", text); heading.textContent = slide.heading; }
				if (slide.caption) { body = el("div", "gs-body", text); body.textContent = slide.caption; }
				applyLook(section, text, heading, body);
			}
			if (dots) { el("span", i ? "" : "gs-on", dots); }
		});
		if (dots) { root.appendChild(dots); }
	}

	function animateSlideshow(data, section, root) {
		var slides = root.querySelectorAll(".gs-showSlide"), n = slides.length;
		if (n < 2) { return; }
		var dots = root.querySelectorAll(".gs-showDots span");
		var tl = gsap.timeline({
			scrollTrigger: {
				trigger: root, start: "top top", end: "+=" + ((n - 1) * 100) + "%", pin: true,
				scrub: setting(data, section, "scrub"), markers: !!setting(data, section, "guides"),
				onUpdate: function (self) {
					var on = Math.round(self.progress * (n - 1));
					Array.prototype.forEach.call(dots, function (d, i) { d.classList.toggle("gs-on", i === on); });
				}
			}
		});
		for (var i = 1; i < n; i++) {
			// Each scroll: the next picture fades in over the last and settles from a slight zoom; its caption rises in.
			tl.fromTo(slides[i], { opacity: 0 }, { opacity: 1, duration: 1, ease: "none" }, i - 1);
			tl.fromTo(slides[i].querySelector(".gs-showPic"), { scale: 1.08 }, { scale: 1, duration: 1, ease: "none" }, i - 1);
			var text = slides[i].querySelector(".gs-showText");
			if (text) { tl.fromTo(text, { y: 40, opacity: 0 }, { y: 0, opacity: 1, duration: 0.4, ease: "none" }, i - 0.45); }
		}
	}

	function buildHero(data, section, root, nextSection) {
		root.classList.add("gs-hero");
		if (section.height) { root.style.height = section.height; root.classList.add("gs-sized"); }
		// What the hero fades into (2026-10-21): the next section's gradient's top color when it has a gradient - the seam must
		// match what that section starts with - then the hero's own fade color, the next section's color, or the page color.
		var joinColour = (nextSection && gradientTopColour(nextSection.gradient)) || section.fadeColour || (nextSection && nextSection.colour) || data.pageColour || "#000000";
		root.style.backgroundColor = joinColour;
		var back = el("div", "gs-heroBack", root);
		// The phone pictures also in a box taller than it is wide (2026-10-30, owner: the wolf showed only a slice): a scene
		// inside a post on a desktop is the post's width but a screen tall, and wide art keeps only its middle there.
		var boxWidth = root.parentNode ? root.parentNode.clientWidth : window.innerWidth;
		var phone = isPhone() || boxWidth < (section.height ? root.offsetHeight : window.innerHeight);

		if (section.kind === "layeredHero") {
			(section.layers || []).forEach(function (layer, i, all) {
				var wrap = el("div", "gs-layer", back);
				// A depth of 0 is a layer that stays still (2026-10-19, the layer builder); no depth at all is spread out by position.
				var hasDepth = layer.depth !== undefined && layer.depth !== null && layer.depth !== "";
				wrap.setAttribute("data-depth", hasDepth ? Math.max(0, +layer.depth || 0) : (i + 1) * 100);
				var img = el("img", "", wrap);
				img.src = phone && layer.srcPhone ? layer.srcPhone : layer.src;
				img.alt = ""; img.decoding = "async";
				// Where wide art is cropped from (2026-10-30): focus "40%" keeps the left of middle, e.g. the wolf and the moon.
				if (section.focus && !(phone && layer.srcPhone) && /^\d{1,3}%$/.test(section.focus)) { img.style.objectPosition = section.focus + " 50%"; }
				// The fade travels with the front layer, so the picture melts into the next section.
				if (i === all.length - 1) { addFade(section, data, wrap, joinColour); }
			});
		} else if (section.kind === "photoHero") {
			var photo = el("div", "gs-photo", back);
			var pimg = el("img", "", photo);
			pimg.src = phone && section.imagePhone ? section.imagePhone : section.image;
			pimg.alt = section.alt || ""; pimg.decoding = "async";
			if (+section.spin) { photo.classList.add("gs-spin"); gsap.set(photo, { xPercent: -50, yPercent: -50 }); }
		} else if (section.kind === "vantaHero") {
			back.classList.add("gs-vanta");
		} else if (section.kind === "gradientHero") {
			back.style.background = section.gradient || joinColour;
		} else if (section.kind === "videoHero") {
			var v = el("video", "gs-video", back);
			v.muted = true; v.loop = true; v.playsInline = true; v.setAttribute("playsinline", ""); v.preload = "none";
			if (section.poster) { v.poster = section.poster; }
			v.src = section.video;
		}
		addOverlay(section, root);
		if (section.kind !== "layeredHero") { addFade(section, data, root, joinColour); }

		var textBox = el("div", "gs-heroText" + (section.textPosition === "bottom" ? " gs-textBottom" : ""), root);
		// Text low on the left, for a hero that starts part way down the page (a post hero under the post's title): raised by
		// that distance, so the heading sits near the bottom of the first screen the visitor sees, not below it.
		if (section.textPosition === "bottom") {
			var heroTop = root.getBoundingClientRect().top + (window.pageYOffset || 0);
			if (heroTop > 0) { textBox.style.paddingBottom = "calc(16vh + " + Math.round(Math.min(heroTop, window.innerHeight * 0.5)) + "px)"; }
		}
		if (!section.textColour) { root.style.color = "#ffffff"; }
		if (!section.shadow) { section.shadow = "soft"; }
		var t = addText(section, textBox, section.headingTag || "h1");
		applyLook(section, textBox, t.heading, t.body);
		// Hero text is visible from the start (it is the first thing on the page); it rises and fades while pinned instead.
		[t.heading, t.body, t.button].forEach(function (x) { if (x) { x.classList.remove("gs-reveal"); } });
	}

	// An eased fade (2026-10-19, owner: "you can't tell where the base ends"): the color's opacity climbs slowly at first and
	// faster near the bottom, over many stops, so there is no visible line where the fade starts - a plain two-stop
	// transparent-to-color gradient shows one. For a #rrggbb color; anything else gets the plain gradient.
	function easedFade(colour) {
		var m = /^#([0-9a-f]{6})$/i.exec(String(colour || "").trim());
		if (!m) { return "linear-gradient(to bottom, transparent 0%, " + colour + " 100%)"; }
		var n = parseInt(m[1], 16), rgb = [(n >> 16) & 255, (n >> 8) & 255, n & 255].join(",");
		var stops = [];
		for (var i = 0; i <= 10; i++) {
			var t = i / 10, a = t * t * (3 - 2 * t);   // smoothstep: slow, faster, slow again at full color
			stops.push("rgba(" + rgb + "," + a.toFixed(3) + ") " + (t * 100) + "%");
		}
		return "linear-gradient(to bottom, " + stops.join(", ") + ")";
	}

	// A section's own color at its top edge - what the section above it fades into: its gradient's top color, its background
	// color, or the page color. A gradient is "used instead of the color" (the Scene editor), so it wins here too (2026-10-21,
	// owner: a section with both faded into its solid color, then started with the gradient's dark top, leaving a band).
	function sectionColour(data, section) {
		return gradientTopColour(section.gradient) || section.colour || data.pageColour || "#000000";
	}
	// A gradient's color at the top edge. Straight: 180deg (the usual) runs top to bottom, so its first color is at the top;
	// one pointing up (0deg, "to top") ends there, so its last. Round: its outer color.
	function gradientTopColour(gradient) {
		var text = String(gradient || ""), colours = text.match(/#[0-9a-f]{6}|rgba?\([^)]*\)/gi);
		if (!colours) { return ""; }
		if (/radial-gradient/i.test(text)) { return colours[colours.length - 1]; }
		var deg = /linear-gradient\(\s*(-?[\d.]+)deg/i.exec(text), angle = 180;
		if (deg) { angle = ((parseFloat(deg[1]) % 360) + 360) % 360; }
		else if (/linear-gradient\(\s*to\s+top/i.test(text)) { angle = 0; }
		var pointsUp = angle < 90 || angle > 270;
		return pointsUp ? colours[colours.length - 1] : colours[0];
	}

	function addFade(section, data, parent, joinColour) {
		var fade = el("div", "gs-fade", parent);
		fade.style.height = setting(data, section, "fadeHeight");
		fade.style.background = easedFade(joinColour);
		var solid = el("div", "gs-fadeSolid", parent === section._root ? null : parent);
		if (solid.parentNode) { solid.style.backgroundColor = joinColour; } else { solid = null; }
	}

	/* ---------- one live animation at a time: Vanta and video run only on screen ---------- */

	function startLive(data, section, root) {
		if (section.kind === "videoHero") {
			var v = root.querySelector("video");
			if (v) { var p = v.play(); if (p && p.catch) { p.catch(function () {}); } }
			return;
		}
		if (section.kind !== "vantaHero" || root._vanta) { return; }
		root._vanta = "starting";
		var base = setting(data, section, "baseUrl");
		var effect = (section.effect || "WAVES").toUpperCase();
		var engine = (effect === "TRUNK" || effect === "TOPOLOGY") ? base + "/common/libs/p5/p5.min.js" : base + "/common/libs/three/three.min.js";
		loadScript(engine)
			.then(function () { return loadScript(base + "/common/libs/vanta/vanta." + effect.toLowerCase() + ".min.js"); })
			.then(function () {
				if (root._vanta !== "starting" || !window.VANTA || !window.VANTA[effect]) { return; }
				var options = Object.assign({ el: root.querySelector(".gs-heroBack"), mouseControls: true, touchControls: true, gyroControls: false }, section.options || {});
				// Scenes are stored as JSON, which has no 0x numbers: Vanta's colors can be written "#0e3b5c" and are turned into numbers here.
				Object.keys(options).forEach(function (k) {
					if (typeof options[k] === "string" && /^#[0-9a-f]{6}$/i.test(options[k]) && /colou?r/i.test(k)) { options[k] = parseInt(options[k].slice(1), 16); }
				});
				// Clouds 2 draws its clouds from a noise picture, which Vanta looks for beside the page unless told where it is.
				if (effect === "CLOUDS2" && !options.texturePath) { options.texturePath = base + "/common/libs/vanta/noise.png"; }
				root._vanta = window.VANTA[effect](options);
			})
			.catch(function () { root._vanta = null; });
	}

	function stopLive(section, root) {
		if (section.kind === "videoHero") {
			var v = root.querySelector("video");
			if (v) { v.pause(); }
			return;
		}
		if (root._vanta && root._vanta.destroy) { root._vanta.destroy(); }
		root._vanta = null;
	}

	/* ---------- animations ---------- */

	// Plugin effect: a heading that comes in word by word or letter by letter (SplitText). Returns false when it can't (no
	// SplitText, or another effect), so the caller does its usual animation instead.
	function splitIn(x, data, section, rise, splits, trigger) {
		var effect = section.headingEffect;
		if ((effect !== "words" && effect !== "letters") || !window.SplitText) { return false; }
		var split = new window.SplitText(x, { type: effect === "letters" ? "words,chars" : "words" });
		splits.push(split);
		gsap.set(x, { opacity: 1, y: 0 });
		gsap.from(effect === "letters" ? split.chars : split.words, {
			opacity: 0, y: rise * 0.35, duration: 0.8, ease: "power3.out", stagger: effect === "letters" ? 0.03 : 0.09, delay: trigger === x ? 0 : 0.2,
			scrollTrigger: { trigger: trigger, start: "top 88%", toggleActions: "play none none reverse", markers: !!setting(data, section, "guides") }
		});
		return true;
	}

	function animateHero(data, section, root, phoneFactor, splits) {
		var guides = !!setting(data, section, "guides");
		// No hold (section.pin false): the same changes, spread over the hero scrolling off the top of the screen.
		var held = section.pin !== false;
		// A held hero that ends the scene (2026-10-31, owner: a long dark stretch before the post's text): by the end of its hold
		// the layers have risen off the screen and it is nearly all its fade color, which then took another whole screen to scroll
		// away. Now what follows comes up a screen sooner, behind it, and the hero fades out over the last third of its hold, so
		// the text shows through as the art leaves. The art and its movement are unchanged.
		var pinScreens = parseFloat(setting(data, section, "pinLength")) / 100;
		var ending = held && section._ending && pinScreens > 1;
		if (ending) {
			var endSpacer = el("div", "gs-endSpacer");
			endSpacer.style.height = "calc(" + (pinScreens * 100) + "vh - 100vh)";
			root.parentNode.insertBefore(endSpacer, root.nextSibling);
			section._endSpacer = endSpacer;
		}
		var tl = gsap.timeline({
			scrollTrigger: {
				trigger: root, start: "top top", end: held ? "+=" + setting(data, section, "pinLength") : "bottom top",
				pin: held, pinSpacing: held && !section._curtain && !ending, anticipatePin: held ? 1 : 0,
				scrub: setting(data, section, "scrub"), markers: guides,
				onToggle: function (self) { self.isActive ? startLive(data, section, root) : stopLive(section, root); }
			}
		});

		if (section.kind === "layeredHero") {
			// Travel relative to the screen: the deepest layer moves one screen x intensity over the whole pin.
			var layers = root.querySelectorAll(".gs-layer");
			var maxDepth = Math.max(1, Math.max.apply(null, Array.prototype.map.call(layers, function (l) { return +l.getAttribute("data-depth"); })));
			var intensity = setting(data, section, "intensity") * phoneFactor;
			Array.prototype.forEach.call(layers, function (layer) {
				tl.to(layer, { y: function () { return -(layer.getAttribute("data-depth") / maxDepth) * window.innerHeight * intensity; }, ease: "none" }, 0);
			});
		} else {
			if (section.kind === "photoHero") {
				// The slow zoom while held, and the turn when the photo has one.
				tl.fromTo(root.querySelector(".gs-photo"), { scale: 1, rotation: 0 }, { scale: section.zoom || 1.15, rotation: +section.spin || 0, ease: "none" }, 0);
			}
			// Without moving layers, the fade climbs over the hero so it melts into the next section.
			var fade = root.querySelector(".gs-fade");
			if (fade) { tl.to(fade, { height: held ? "100vh" : "100%", ease: "none" }, 0); }
		}
		var text = root.querySelector(".gs-heroText");
		// The heading's entrance, when the hero has a heading effect: plays as the hero comes on screen (at once, for a hero at the top).
		var heroHeading = root.querySelector(".gs-heading");
		if (heroHeading) { splitIn(heroHeading, data, section, setting(data, section, "rise") * phoneFactor, splits, root); }
		if (text) {
			tl.to(text, { y: function () { return -window.innerHeight * 0.45 * phoneFactor; }, opacity: 0, ease: "none" }, 0);
		}
		if (ending) {
			var whole = tl.duration();
			tl.to(root, { opacity: 0, duration: whole / 3, ease: "power1.in" }, whole * 2 / 3);
		}
		// A hero at the top of the page is already on screen before any scrolling.
		if (root.getBoundingClientRect().top < window.innerHeight) { startLive(data, section, root); }
		// A hero further down starts as soon as it comes up the screen (2026-10-20, owner: Fog and Clouds 2 "do not seem to work"):
		// the timeline above only turns it on once its top reaches the top of the screen, so until then its background was empty.
		if (section.kind === "vantaHero" || section.kind === "videoHero") {
			ScrollTrigger.create({
				trigger: root, start: "top bottom", end: "top top",
				onEnter: function () { startLive(data, section, root); },
				onEnterBack: function () { startLive(data, section, root); },
				onLeaveBack: function () { stopLive(section, root); }
			});
		}
	}

	function animateSlide(data, section, root) {
		var back = root.querySelector(".gs-slideBack");
		// A turning picture turns as it passes, instead of drifting up and down.
		var spin = +section.spin || 0;
		var trigger = { trigger: root, start: "top bottom", end: "bottom top", scrub: true, markers: !!setting(data, section, "guides") };
		if (spin) {
			gsap.fromTo(back, { rotation: 0 }, { rotation: spin, ease: "none", scrollTrigger: trigger });
		} else {
			gsap.fromTo(back, { yPercent: -10 }, { yPercent: 10, ease: "none", scrollTrigger: trigger });
		}
	}

	function animateReveals(data, section, root, phoneFactor, splits) {
		var rise = setting(data, section, "rise") * phoneFactor;
		Array.prototype.forEach.call(root.querySelectorAll(".gs-reveal"), function (x) {
			// Heading effects that need SplitText: each word or letter rises in turn. Without SplitText, the plain rise below.
			if (x.classList.contains("gs-heading") && splitIn(x, data, section, rise, splits, x)) { return; }
			gsap.fromTo(x, { opacity: 0, y: rise }, {
				opacity: 1, y: 0, duration: 1.2, ease: "power3.out",
				scrollTrigger: { trigger: x, start: "top 88%", toggleActions: "play none none reverse", markers: !!setting(data, section, "guides") }
			});
		});
	}

	/* ---------- build ---------- */

	function heroParallax(container, data) {
		data.pageColour = colourBehind(container) || data.pageColour;
		if (!data.settings.fadeHeight) { data.settings.fadeHeight = "40vh"; }
		data.settings.intensity = Math.min(+(data.settings.intensity || 1), 0.6);
		(data.sections || []).forEach(function (section) {
			if (HERO_KINDS[section.kind]) { section.pin = false; delete section.fadeColour; }
		});
	}

	// The first solid background color behind an element (the post's own box), as #rrggbb.
	function colourBehind(node) {
		for (var n = node.parentElement; n; n = n.parentElement) {
			var m = /rgba?\(([0-9]+),\s*([0-9]+),\s*([0-9]+)(?:,\s*([0-9.]+))?\)/.exec(getComputedStyle(n).backgroundColor);
			if (m && (m[4] === undefined || +m[4] > 0.5)) {
				return "#" + [m[1], m[2], m[3]].map(function (x) { return ("0" + (+x).toString(16)).slice(-2); }).join("");
			}
		}
		return "";
	}

	function build(container, data) {
		// Still (2026-10-20): GreenSock is switched off in Blog Options, so nothing is loaded and the scene shows its pictures and text
		// without movement, as visitors who turned motion off see it.
		var still = !!config().still;
		if (!still) {
			if (!window.gsap || !window.ScrollTrigger) { throw new Error("GalaxieScene needs gsap.min.js and ScrollTrigger.min.js"); }
			gsap.registerPlugin(window.ScrollTrigger);
		}
		addStyles();
		data = data || {};
		data.settings = data.settings || {};
		// A hero parallax scene (2026-10-22, owner): the hero at the top of a post. Its layers move while it scrolls away (no hold,
		// so no empty stretch after the art), it fades into the color behind the post with a fade tall enough to wash out the
		// bottom of the art, and its layers travel no further than the scene. Other scenes keep their own rules.
		if (data.settings.type === "heroParallax") { heroParallax(container, data); }
		container.classList.add("gScene");
		if (data.pageColour) { container.style.backgroundColor = data.pageColour; }

		// 1. Markup
		var built = [];
		(data.sections || []).forEach(function (section, i) {
			var root = el("section", "gs-section gs-kind-" + section.kind, container);
			section._root = root;
			var next = data.sections[i + 1];
			if (section.kind === "text") { buildText(section, root); }
			else if (section.kind === "imageSlide") { buildSlide(section, root); }
			else if (section.kind === "slideshow") { buildSlideshow(section, root); }
			else if (section.kind === "form") { buildForm(section, root); }
			else if (section.kind === "map") { buildMap(data, section, root); }
			else if (section.kind === "product") { buildProduct(section, root); }
			else if (HERO_KINDS[section.kind]) { buildHero(data, section, root, next); }
			else { root.style.display = "none"; return; }   // unknown kinds (map, event...) come in a later phase
			built.push({ section: section, root: root });
			// The curtain: a spacer as long as the pin minus one screen, so the next section rises over the pinned hero and
			// covers it exactly when the pin ends. A hero that is the scene's last section (the usual post hero) has nothing to
			// slide over it - the post's own text follows - so it pins normally and then scrolls away.
			section._curtain = HERO_KINDS[section.kind] && !!next;
			// A hero that ends the scene (the usual post hero), see animateHero.
			section._ending = HERO_KINDS[section.kind] && !next;
			if (section._curtain) {
				var spacer = el("div", "gs-curtainSpacer", container);
				spacer.style.height = "calc(" + parseFloat(setting(data, section, "pinLength")) + "vh - 100vh)";
			}
			// A section sliding up over a hero gets a soft top edge (2026-10-19, owner): a band above it fading from clear into its
			// own color, so where it meets the hero - even before the hero's own fade is complete - there is no hard line.
			var previous = data.sections[i - 1];
			if (previous && previous._curtain) {
				// Just before the section (heroes and slides clip what is outside them), pulled up over the hero by its own height.
				var soft = document.createElement("div");
				soft.className = "gs-softTop";
				soft.style.height = setting(data, previous, "fadeHeight");
				soft.style.marginTop = "calc(-1 * " + setting(data, previous, "fadeHeight") + ")";
				soft.style.marginBottom = "-2px";
				soft.style.background = easedFade(sectionColour(data, section));
				container.insertBefore(soft, root);
			}
		});

		startForms(container, data);
		startShop(container, data);

		if (still) {
			container.classList.add("gs-still");
			Array.prototype.forEach.call(container.querySelectorAll(".gs-reveal"), function (x) { x.style.opacity = 1; x.style.transform = "none"; });
			Array.prototype.forEach.call(container.querySelectorAll(".gs-slideshow"), function (x) { x.classList.add("gs-static"); });
			return { container: container, refresh: function () {}, destroy: function () {} };
		}

		// 2. Animations, set up per screen size and motion preference (and undone/redone when they change).
		var mm = gsap.matchMedia();
		mm.add({ phone: "(max-width: 768px)", desktop: "(min-width: 769px)", reduceMotion: "(prefers-reduced-motion: reduce)" }, function (context) {
			var c = context.conditions;
			// settings.reducedMotion lets the editor's preview show what visitors who turned motion off will see.
			if (c.reduceMotion || data.settings.reducedMotion) {
				gsap.set(container.querySelectorAll(".gs-reveal"), { opacity: 1, y: 0 });
				Array.prototype.forEach.call(container.querySelectorAll(".gs-slideshow"), function (x) { x.classList.add("gs-static"); });
				// Still start the hero animations that are on screen, but without scroll effects.
				built.forEach(function (b) { if (HERO_KINDS[b.section.kind] && b.root.getBoundingClientRect().top < window.innerHeight) { startLive(data, b.section, b.root); } });
				return;
			}
			var splits = [];
			built.forEach(function (b) {
				var factor = c.phone && setting(data, b.section, "phoneMotion") === "light" ? 0.5 : 1;
				if (HERO_KINDS[b.section.kind]) { animateHero(data, b.section, b.root, factor, splits); }
				if (b.section.kind === "imageSlide") { animateSlide(data, b.section, b.root); }
				if (b.section.kind === "slideshow") { b.root.classList.remove("gs-static"); animateSlideshow(data, b.section, b.root); }
				animateReveals(data, b.section, b.root, factor, splits);
			});
			return function () {
				splits.forEach(function (split) { try { split.revert(); } catch (e) {} });
				built.forEach(function (b) {
					if (HERO_KINDS[b.section.kind]) { stopLive(b.section, b.root); }
					if (b.section._endSpacer) { b.section._endSpacer.remove(); b.section._endSpacer = null; }
				});
			};
		});

		// Images change the page height as they load; measure again once everything is in.
		var refresh = function () { window.ScrollTrigger.refresh(); };
		if (document.readyState === "complete") { setTimeout(refresh, 0); } else { window.addEventListener("load", refresh, { once: true }); }

		return {
			container: container,
			refresh: refresh,
			destroy: function () { mm.revert(); }
		};
	}

	// Loads GSAP and ScrollTrigger from the CDN (in order) unless the page already has them, then calls back.
	// One library file: from cdnjs, then from this server if cdnjs fails; or from this server only, when the owner chose that.
	function loadLibrary(entry) {
		if (window[entry.global]) { return Promise.resolve(); }
		var c = config();
		var local = (c.local || []).indexOf(entry.file) >= 0 && c.localBase ? c.localBase + entry.file : null;
		if (c.source === "local") { return local ? loadScript(local, entry.integrity) : Promise.reject(new Error(entry.file + " is not on this server")); }
		return loadScript(CDN + entry.file, entry.integrity).catch(function (error) {
			if (local) { return loadScript(local, entry.integrity); }
			throw error;
		});
	}
	// The plugins a scene's effects need.
	function pluginsFor(data) {
		var wanted = {};
		((data && data.sections) || []).forEach(function (section) {
			Object.keys(NEEDS).forEach(function (key) { var name = NEEDS[key][section[key]]; if (name) { wanted[name] = true; } });
		});
		return Object.keys(wanted);
	}
	// Loads GSAP and ScrollTrigger, then the plugins the scene needs (a plugin that won't load is skipped: its effect falls back).
	function ready(callback, data) {
		// GreenSock switched off (2026-10-20): nothing to load; the scene is built still.
		if (config().still) { if (callback) { callback(); } return Promise.resolve(); }
		var core = CORE.reduce(function (chain, entry) { return chain.then(function () { return loadLibrary(entry); }); }, Promise.resolve());
		return core.then(function () {
			return Promise.all(pluginsFor(data).map(function (name) {
				return loadLibrary(PLUGINS[name]).then(function () { gsap.registerPlugin(window[PLUGINS[name].global]); }).catch(function () {});
			}));
		}).then(function () { if (callback) { callback(); } });
	}

	// Whether a plugin can be used on this blog (the editor offers an effect only then).
	function pluginAvailable(name) {
		var c = config(), p = PLUGINS[name];
		return !!p && (c.source !== "local" || (c.local || []).indexOf(p.file) >= 0);
	}

	window.GalaxieScene = { build: build, ready: ready, pluginAvailable: pluginAvailable, plugins: Object.keys(PLUGINS), version: "1.3.0-still" };
})(window, document);

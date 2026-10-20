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
			pageColour: "#392630",                 // the colour around the scene
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

	Every section can have: heading, html (rich text), colour (its top colour - the next hero's fade uses it), gradient or
	background, textColour, headingFont, textFont, headingSize, textSize, headingSizePhone, textSizePhone, align
	("left"|"center"|"right"), shadow ("none"|"soft"|"strong"|"glow"), shadowColour, glow ({ colour, opacity 0-1, softness px },
	on its own or with the shadow), overlay ({ colour, opacity }).
	Heroes can also have (2026-10-19, post heroes): height ("75vh"; a full screen when not set), pin (false: no hold - the hero
	scrolls away with the page while its picture zooms and its text fades) and textPosition ("center", or "bottom" for a large
	heading low on the left).

	Kinds:
		text          a heading and rich text on a gradient or colour
		imageSlide    a full-screen picture whose background moves slower than the page: image, imagePhone
		layeredHero   pinned image layers moving at different depths: layers [{ src, srcPhone, depth }]
		photoHero     one pinned photo with a slow zoom: image, imagePhone, zoom (1.15)
		vantaHero     a Vanta animation: effect ("WAVES", "NET", "BIRDS"...), options ({ color: 0x..., ... })
		gradientHero  a pinned gradient
		videoHero     a muted looping background video: video, poster
	All heroes pin, let their heading rise and fade, fade into the next section's colour, and let the next section rise over
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
			".gScene{position:relative;overflow-x:hidden}",
			".gScene *{box-sizing:border-box}",
			".gScene .gs-section{position:relative;z-index:2}",
			".gScene .gs-softTop{position:relative;z-index:2;pointer-events:none}",
			".gScene .gs-text{padding:12vh 8vw;min-height:60vh;display:flex;flex-direction:column;justify-content:center}",
			".gScene .gs-heading{font-size:clamp(1.4rem,3vw,2.4rem);margin:0 0 .6em;line-height:1.2}",
			".gScene .gs-body{font-size:clamp(1rem,1.6vw,1.3rem);line-height:1.5}",
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
			".gScene .gs-hero.gs-sized .gs-photo img{height:100%}",
			".gScene .gs-fade{position:absolute;left:0;width:100%;bottom:0;pointer-events:none;z-index:4}",
			".gScene .gs-fadeSolid{position:absolute;left:0;width:100%;height:300vh;top:calc(100% - 2px);pointer-events:none}",
			".gScene .gs-slide{height:100vh;overflow:hidden;display:flex;flex-direction:column;justify-content:center;padding:0 8vw}",
			".gScene .gs-slideBack{position:absolute;left:0;right:0;top:-20%;height:140%;background-size:cover;background-position:center;will-change:transform}",
			".gScene .gs-slide .gs-heading{font-size:clamp(1.6rem,4vw,3rem)}",
			".gScene .gs-slideText{position:relative;z-index:3}",
			".gScene .gs-reveal{opacity:0}",
			"@media (prefers-reduced-motion: reduce){.gScene .gs-reveal{opacity:1}}"
		].join("\n");
		var style = el("style");
		style.id = "galaxieSceneStyles";
		style.appendChild(document.createTextNode(css));
		document.head.appendChild(style);
	}

	/* ---------- the look of a section: fonts, sizes, colours, shadows, overlay ---------- */

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

	function addText(section, parent, headingTag) {
		var heading = null, body = null;
		if (section.heading) {
			heading = el(headingTag || "h2", "gs-heading gs-reveal", parent);
			heading.textContent = section.heading;
		}
		if (section.html) {
			body = el("div", "gs-body gs-reveal", parent);
			// Rich text written by the blog owner in the editor (TinyMCE) - the same trust as a post's body.
			body.innerHTML = section.html;
		}
		return { heading: heading, body: body };
	}

	/* ---------- markup for each kind ---------- */

	function buildText(section, root) {
		root.classList.add("gs-text");
		if (section.gradient) { root.style.background = section.gradient; }
		else if (section.background || section.colour) { root.style.background = section.background || section.colour; }
		// No text colour of its own (2026-10-19): white on a dark background, near-black on a light one - never the theme's
		// own text colour, which on a post is usually dark, and unreadable on a dark section.
		if (!section.textColour) { root.style.color = isLight(section.colour || ((/(#[0-9a-f]{6})/i.exec(section.gradient || "") || [])[1]) || "") ? "#1f2328" : "#ffffff"; }
		var t = addText(section, root);
		applyLook(section, root, t.heading, t.body);
	}

	// Whether a #rrggbb colour is light (perceived brightness); anything else counts as dark.
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

	function buildHero(data, section, root, nextSection) {
		root.classList.add("gs-hero");
		if (section.height) { root.style.height = section.height; root.classList.add("gs-sized"); }
		var joinColour = section.fadeColour || (nextSection && nextSection.colour) || data.pageColour || "#000000";
		root.style.backgroundColor = joinColour;
		var back = el("div", "gs-heroBack", root);
		var phone = isPhone();

		if (section.kind === "layeredHero") {
			(section.layers || []).forEach(function (layer, i, all) {
				var wrap = el("div", "gs-layer", back);
				// A depth of 0 is a layer that stays still (2026-10-19, the layer builder); no depth at all is spread out by position.
				var hasDepth = layer.depth !== undefined && layer.depth !== null && layer.depth !== "";
				wrap.setAttribute("data-depth", hasDepth ? Math.max(0, +layer.depth || 0) : (i + 1) * 100);
				var img = el("img", "", wrap);
				img.src = phone && layer.srcPhone ? layer.srcPhone : layer.src;
				img.alt = ""; img.decoding = "async";
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
		[t.heading, t.body].forEach(function (x) { if (x) { x.classList.remove("gs-reveal"); } });
	}

	// An eased fade (2026-10-19, owner: "you can't tell where the base ends"): the colour's opacity climbs slowly at first and
	// faster near the bottom, over many stops, so there is no visible line where the fade starts - a plain two-stop
	// transparent-to-colour gradient shows one. For a #rrggbb colour; anything else gets the plain gradient.
	function easedFade(colour) {
		var m = /^#([0-9a-f]{6})$/i.exec(String(colour || "").trim());
		if (!m) { return "linear-gradient(to bottom, transparent 0%, " + colour + " 100%)"; }
		var n = parseInt(m[1], 16), rgb = [(n >> 16) & 255, (n >> 8) & 255, n & 255].join(",");
		var stops = [];
		for (var i = 0; i <= 10; i++) {
			var t = i / 10, a = t * t * (3 - 2 * t);   // smoothstep: slow, faster, slow again at full colour
			stops.push("rgba(" + rgb + "," + a.toFixed(3) + ") " + (t * 100) + "%");
		}
		return "linear-gradient(to bottom, " + stops.join(", ") + ")";
	}

	// A section's own colour at its top: its background colour, the first colour of its gradient, or the page colour.
	function sectionColour(data, section) {
		if (section.colour) { return section.colour; }
		var m = /(#[0-9a-f]{6})/i.exec(section.gradient || "");
		return m ? m[1] : (data.pageColour || "#000000");
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
				// Scenes are stored as JSON, which has no 0x numbers: Vanta's colours can be written "#0e3b5c" and are turned into numbers here.
				Object.keys(options).forEach(function (k) {
					if (typeof options[k] === "string" && /^#[0-9a-f]{6}$/i.test(options[k]) && /colou?r/i.test(k)) { options[k] = parseInt(options[k].slice(1), 16); }
				});
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
		var tl = gsap.timeline({
			scrollTrigger: {
				trigger: root, start: "top top", end: held ? "+=" + setting(data, section, "pinLength") : "bottom top",
				pin: held, pinSpacing: held && !section._curtain, anticipatePin: held ? 1 : 0,
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
		// A hero at the top of the page is already on screen before any scrolling.
		if (root.getBoundingClientRect().top < window.innerHeight) { startLive(data, section, root); }
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

	function build(container, data) {
		if (!window.gsap || !window.ScrollTrigger) { throw new Error("GalaxieScene needs gsap.min.js and ScrollTrigger.min.js"); }
		gsap.registerPlugin(window.ScrollTrigger);
		addStyles();
		data = data || {};
		data.settings = data.settings || {};
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
			else if (HERO_KINDS[section.kind]) { buildHero(data, section, root, next); }
			else { root.style.display = "none"; return; }   // unknown kinds (map, event...) come in a later phase
			built.push({ section: section, root: root });
			// The curtain: a spacer as long as the pin minus one screen, so the next section rises over the pinned hero and
			// covers it exactly when the pin ends. A hero that is the scene's last section (the usual post hero) has nothing to
			// slide over it - the post's own text follows - so it pins normally and then scrolls away.
			section._curtain = HERO_KINDS[section.kind] && !!next;
			if (section._curtain) {
				var spacer = el("div", "gs-curtainSpacer", container);
				spacer.style.height = "calc(" + parseFloat(setting(data, section, "pinLength")) + "vh - 100vh)";
			}
			// A section sliding up over a hero gets a soft top edge (2026-10-19, owner): a band above it fading from clear into its
			// own colour, so where it meets the hero - even before the hero's own fade is complete - there is no hard line.
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

		// 2. Animations, set up per screen size and motion preference (and undone/redone when they change).
		var mm = gsap.matchMedia();
		mm.add({ phone: "(max-width: 768px)", desktop: "(min-width: 769px)", reduceMotion: "(prefers-reduced-motion: reduce)" }, function (context) {
			var c = context.conditions;
			// settings.reducedMotion lets the editor's preview show what visitors who turned motion off will see.
			if (c.reduceMotion || data.settings.reducedMotion) {
				gsap.set(container.querySelectorAll(".gs-reveal"), { opacity: 1, y: 0 });
				// Still start the hero animations that are on screen, but without scroll effects.
				built.forEach(function (b) { if (HERO_KINDS[b.section.kind] && b.root.getBoundingClientRect().top < window.innerHeight) { startLive(data, b.section, b.root); } });
				return;
			}
			var splits = [];
			built.forEach(function (b) {
				var factor = c.phone && setting(data, b.section, "phoneMotion") === "light" ? 0.5 : 1;
				if (HERO_KINDS[b.section.kind]) { animateHero(data, b.section, b.root, factor, splits); }
				if (b.section.kind === "imageSlide") { animateSlide(data, b.section, b.root); }
				animateReveals(data, b.section, b.root, factor, splits);
			});
			return function () {
				splits.forEach(function (split) { try { split.revert(); } catch (e) {} });
				built.forEach(function (b) { if (HERO_KINDS[b.section.kind]) { stopLive(b.section, b.root); } });
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

	window.GalaxieScene = { build: build, ready: ready, pluginAvailable: pluginAvailable, plugins: Object.keys(PLUGINS), version: "1.2.0-plugins" };
})(window, document);

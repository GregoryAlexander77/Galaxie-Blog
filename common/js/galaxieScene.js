/*
	Galaxie Scenes engine (Galaxie Blog 5, 2026-10-19). Builds a scrolling scene - heroes, text blocks and image slides - from a
	plain data description, with GSAP 3 + ScrollTrigger. Replaces the 2019 ScrollMagic templates in includes/postContent/parallax/,
	which keep working until each post is moved over. Design: doc/aiDraftArticles/parallaxScenesDesign.cfm.

	Needs gsap.min.js and ScrollTrigger.min.js (common/libs/gsap3/) loaded first. Never load it on a page that still loads
	TweenMax 2 / ScrollMagic: GSAP 3 defines the same global names.

	Usage:
		var scene = GalaxieScene.build(document.getElementById("myScene"), sceneData);
		scene.destroy();   // removes the animations (the markup stays)

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
	("left"|"center"|"right"), shadow ("none"|"soft"|"strong"|"glow"), shadowColour, overlay ({ colour, opacity }).

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

	function loadScript(src) {
		if (!scriptPromises[src]) {
			scriptPromises[src] = new Promise(function (resolve, reject) {
				var tag = document.createElement("script");
				tag.src = src; tag.async = true; tag.onload = resolve; tag.onerror = reject;
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
			".gScene .gs-video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}",
			".gScene .gs-overlay{position:absolute;inset:0;pointer-events:none;z-index:2}",
			".gScene .gs-heroText{position:absolute;inset:0;display:flex;flex-direction:column;justify-content:center;padding:0 8vw;z-index:3}",
			".gScene .gs-heroText .gs-heading{font-size:clamp(2rem,6vw,4.5rem)}",
			".gScene .gs-fade{position:absolute;left:0;width:100%;bottom:0;pointer-events:none;z-index:4}",
			".gScene .gs-fadeSolid{position:absolute;left:0;width:100%;height:300vh;top:100%;pointer-events:none}",
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
		if (shadow) {
			var value = shadow(section.shadowColour || "#000000");
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
		var t = addText(section, root);
		applyLook(section, root, t.heading, t.body);
	}

	function buildSlide(section, root) {
		root.classList.add("gs-slide");
		var back = el("div", "gs-slideBack", root);
		var image = isPhone() && section.imagePhone ? section.imagePhone : section.image;
		if (image) { back.style.backgroundImage = 'url("' + image + '")'; }
		addOverlay(section, root);
		var holder = el("div", "gs-slideText", root);
		if (!section.textColour) { root.style.color = "#ffffff"; }
		if (!section.shadow) { section.shadow = "soft"; }
		var t = addText(section, holder);
		applyLook(section, root, t.heading, t.body);
	}

	function buildHero(data, section, root, nextSection) {
		root.classList.add("gs-hero");
		var joinColour = section.fadeColour || (nextSection && nextSection.colour) || data.pageColour || "#000000";
		root.style.backgroundColor = joinColour;
		var back = el("div", "gs-heroBack", root);
		var phone = isPhone();

		if (section.kind === "layeredHero") {
			(section.layers || []).forEach(function (layer, i, all) {
				var wrap = el("div", "gs-layer", back);
				wrap.setAttribute("data-depth", layer.depth || (i + 1) * 100);
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

		var textBox = el("div", "gs-heroText", root);
		if (!section.textColour) { root.style.color = "#ffffff"; }
		if (!section.shadow) { section.shadow = "soft"; }
		var t = addText(section, textBox, section.headingTag || "h1");
		applyLook(section, textBox, t.heading, t.body);
		// Hero text is visible from the start (it is the first thing on the page); it rises and fades while pinned instead.
		[t.heading, t.body].forEach(function (x) { if (x) { x.classList.remove("gs-reveal"); } });
	}

	function addFade(section, data, parent, joinColour) {
		var fade = el("div", "gs-fade", parent);
		fade.style.height = setting(data, section, "fadeHeight");
		fade.style.background = "linear-gradient(to bottom, transparent 0%, " + joinColour + " 100%)";
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

	function animateHero(data, section, root, phoneFactor) {
		var guides = !!setting(data, section, "guides");
		var tl = gsap.timeline({
			scrollTrigger: {
				trigger: root, start: "top top", end: "+=" + setting(data, section, "pinLength"),
				pin: true, pinSpacing: false, anticipatePin: 1,
				scrub: setting(data, section, "scrub"), markers: guides,
				onToggle: function (self) { self.isActive ? startLive(data, section, root) : stopLive(section, root); }
			}
		});

		if (section.kind === "layeredHero") {
			// Travel relative to the screen: the deepest layer moves one screen x intensity over the whole pin.
			var layers = root.querySelectorAll(".gs-layer");
			var maxDepth = Math.max.apply(null, Array.prototype.map.call(layers, function (l) { return +l.getAttribute("data-depth"); }));
			var intensity = setting(data, section, "intensity") * phoneFactor;
			Array.prototype.forEach.call(layers, function (layer) {
				tl.to(layer, { y: function () { return -(layer.getAttribute("data-depth") / maxDepth) * window.innerHeight * intensity; }, ease: "none" }, 0);
			});
		} else {
			if (section.kind === "photoHero") {
				tl.fromTo(root.querySelector(".gs-photo"), { scale: 1 }, { scale: section.zoom || 1.15, ease: "none" }, 0);
			}
			// Without moving layers, the fade climbs over the hero so it melts into the next section.
			var fade = root.querySelector(".gs-fade");
			if (fade) { tl.to(fade, { height: "100vh", ease: "none" }, 0); }
		}
		var text = root.querySelector(".gs-heroText");
		if (text) {
			tl.to(text, { y: function () { return -window.innerHeight * 0.45 * phoneFactor; }, opacity: 0, ease: "none" }, 0);
		}
		// A hero at the top of the page is already on screen before any scrolling.
		if (root.getBoundingClientRect().top < window.innerHeight) { startLive(data, section, root); }
	}

	function animateSlide(data, section, root) {
		var back = root.querySelector(".gs-slideBack");
		gsap.fromTo(back, { yPercent: -10 }, {
			yPercent: 10, ease: "none",
			scrollTrigger: { trigger: root, start: "top bottom", end: "bottom top", scrub: true, markers: !!setting(data, section, "guides") }
		});
	}

	function animateReveals(data, section, root, phoneFactor) {
		var rise = setting(data, section, "rise") * phoneFactor;
		Array.prototype.forEach.call(root.querySelectorAll(".gs-reveal"), function (x) {
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
			// covers it exactly when the pin ends.
			if (HERO_KINDS[section.kind]) {
				var spacer = el("div", "gs-curtainSpacer", container);
				spacer.style.height = "calc(" + parseFloat(setting(data, section, "pinLength")) + "vh - 100vh)";
			}
		});

		// 2. Animations, set up per screen size and motion preference (and undone/redone when they change).
		var mm = gsap.matchMedia();
		mm.add({ phone: "(max-width: 768px)", desktop: "(min-width: 769px)", reduceMotion: "(prefers-reduced-motion: reduce)" }, function (context) {
			var c = context.conditions;
			if (c.reduceMotion) {
				gsap.set(container.querySelectorAll(".gs-reveal"), { opacity: 1, y: 0 });
				// Still start the hero animations that are on screen, but without scroll effects.
				built.forEach(function (b) { if (HERO_KINDS[b.section.kind] && b.root.getBoundingClientRect().top < window.innerHeight) { startLive(data, b.section, b.root); } });
				return;
			}
			built.forEach(function (b) {
				var factor = c.phone && setting(data, b.section, "phoneMotion") === "light" ? 0.5 : 1;
				if (HERO_KINDS[b.section.kind]) { animateHero(data, b.section, b.root, factor); }
				if (b.section.kind === "imageSlide") { animateSlide(data, b.section, b.root); }
				animateReveals(data, b.section, b.root, factor);
			});
			return function () { built.forEach(function (b) { if (HERO_KINDS[b.section.kind]) { stopLive(b.section, b.root); } }); };
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

	window.GalaxieScene = { build: build, version: "1.0.0-phase2" };
})(window, document);

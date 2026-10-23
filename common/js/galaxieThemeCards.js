/*
	Galaxie theme cards (2026-10-20): a small picture of a page in a theme - the background picture, the header ribbon with the logo,
	the site name in its font and color and the menu, then the content box right under it with a post in the theme's fonts (a Latin
	sample) and, on a classic (not modern) theme, the sidebar. Shared by the Themes window (admin/adminInterface/themeEditor.cfm) and
	Site Wizard's "Pick a look" (admin/setup.cfm), so the two always show the same thing. The theme data comes from ThemeEditor.cfc
	getThemeCards(); its fonts' @font-face rules are put on the page by the page itself.

	GalaxieThemeCards.picture(theme, { siteName, baseUrl, height }) returns a jQuery element (div.themeCardPicture).
*/
(function (window, $) {
	"use strict";

	var CSS = [
		".themeCardPicture{position:relative;overflow:hidden;background-size:cover;background-position:center;background-color:rgb(136,136,136)}",
		".themeCardPicture .themeCardHeader{box-sizing:border-box;height:34px;margin:0 auto;background-size:cover;background-position:center;display:flex;align-items:center;gap:8px;padding:0 8px;overflow:hidden;white-space:nowrap}",
		".themeCardPicture .themeCardHeader img{max-height:24px;max-width:30%}",
		".themeCardPicture .themeCardName{font-size:15px;line-height:1;overflow:hidden;text-overflow:ellipsis}",
		".themeCardPicture .themeCardMenu{margin-left:auto;font-size:10px;opacity:.9}",
		".themeCardPicture .themeCardBody{position:absolute;top:34px;bottom:0;display:flex}",
		".themeCardPicture .themeCardPosts,.themeCardPicture .themeCardSide{background:rgb(255,255,255);color:rgb(34,34,34);padding:7px 8px;overflow:hidden;text-align:left}",
		".themeCardPicture.dark .themeCardPosts,.themeCardPicture.dark .themeCardSide{background:rgb(36,38,42);color:rgb(230,230,230)}",
		".themeCardPicture .themeCardPosts{flex:1 1 auto}",
		".themeCardPicture .themeCardSide{flex:0 0 auto;border-left:1px solid rgba(128,128,128,.25)}",
		".themeCardPicture .themeCardTitle{font-weight:bold;font-size:13px;line-height:1.2;margin-bottom:4px}",
		".themeCardPicture .themeCardText1{font-size:10px;line-height:1.4}",
		".themeCardPicture .themeCardPod{font-size:9px;line-height:1.35;margin-bottom:6px}",
		".themeCardPicture .themeCardPod b{display:block;font-size:10px;margin-bottom:2px}"
	].join("");

	function addStyles() {
		if (document.getElementById("galaxieThemeCardsCss")) { return; }
		var style = document.createElement("style");
		style.id = "galaxieThemeCardsCss";
		style.textContent = CSS;
		document.head.appendChild(style);
	}
	function bool(v) { return v === true || v === "1" || v === 1 || v === "true" || v === "YES" || v === "yes"; }
	function fontCss(name, type) { return name ? "'" + String(name).replace(/'/g, "") + "'" + (type ? ", " + type : "") : "inherit"; }
	function img(path, base) { return path ? (/^(https?:)?\/\//.test(path) || (base && path.indexOf(base + "/") === 0) ? path : (base || "") + path) : ""; }

	function picture(t, options) {
		var o = options || {};
		addStyles();
		var width = Math.max(40, Math.min(100, parseInt(t.ContentWidth, 10) || 60)), classic = String(t.Breakpoint) !== "0";
		if (classic) { width = Math.max(width, 80); }
		var left = (100 - width) / 2, opacity = Math.max(0.5, Math.min(1, (parseInt(t.SiteOpacity, 10) || 99) / 100));
		var pic = $('<div class="themeCardPicture"></div>').toggleClass("dark", bool(t.Dark)).css({
			height: (o.height || 230) + "px",
			"background-image": bool(t.IncludeBackgroundImages) && t.BlogBackgroundImage ? 'url("' + img(t.BlogBackgroundImage, o.baseUrl) + '")' : "none",
			"background-color": t.BlogBackgroundColor || "rgb(136,136,136)"
		});
		var header = $('<div class="themeCardHeader"></div>').css({ "background-image": t.HeaderBackgroundImage ? 'url("' + img(t.HeaderBackgroundImage, o.baseUrl) + '")' : "none", width: width + "%" });
		if (t.LogoImage) { header.append($('<img alt="">').attr("src", img(t.LogoImage, o.baseUrl))); }
		if (bool(t.DisplayBlogName)) { header.append($('<span class="themeCardName"></span>').text(o.siteName || "").css({ "font-family": fontCss(t.BlogNameFont, t.BlogNameFontType), color: t.BlogNameTextColor || "white" })); }
		header.append($('<span class="themeCardMenu">Menu &nbsp; About &nbsp; Themes</span>').css({ "font-family": fontCss(t.MenuFont, t.MenuFontType), color: t.BlogNameTextColor || "white" }));
		var body = $('<div class="themeCardBody"></div>').css({ left: left + "%", right: left + "%", opacity: opacity, "font-family": fontCss(t.Font, t.FontType) });
		body.append($('<div class="themeCardPosts"></div>').append(
			$('<div class="themeCardTitle">Lorem ipsum dolor sit amet</div>').css("font-family", fontCss(t.BlogNameFont, t.BlogNameFontType)),
			$('<div class="themeCardText1">Consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</div>')));
		if (classic) {
			var side = Math.max(20, Math.min(45, parseInt(t.SideBarContainerWidth, 10) || 35));
			body.append($('<div class="themeCardSide"></div>').css("width", side + "%").append(
				'<div class="themeCardPod"><b>Categories</b>Lorem<br>Ipsum<br>Dolor</div>',
				'<div class="themeCardPod"><b>Recent posts</b>Sit amet<br>Consectetur</div>'));
		}
		return pic.append(header, body);
	}

	// "Header: Font · Body: Font", each in its own font.
	function fontsLine(t) {
		return $('<span class="themeCardFontNames"></span>').append(
			$("<span></span>").text("Header: " + (t.BlogNameFont || "default")).css("font-family", fontCss(t.BlogNameFont, t.BlogNameFontType)), " · ",
			$("<span></span>").text("Body: " + (t.Font || "default")).css("font-family", fontCss(t.Font, t.FontType)));
	}

	window.GalaxieThemeCards = { picture: picture, fontsLine: fontsLine, fontCss: fontCss, bool: bool, version: "1.0.0" };
})(window, jQuery);

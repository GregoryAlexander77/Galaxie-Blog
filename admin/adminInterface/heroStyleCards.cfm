<!--- The post hero styles as picture cards (2026-10-23, owner: "users probably won't know what the post hero styles mean"). Each
card has a tiny browser that plays a short scroll, so the difference between the styles is seen, not read. Included by
blogOptions.cfm (Post Hero Style) and postHeroText.cfm (a post's own style). The choice goes into a hidden input, so the forms
read it as they read the dropdown it replaces.

Set before including:
	heroCardsId          the hidden input's id
	heroCardsName        its name ('' for none)
	heroCardsValue       the chosen style: classic, held, band or magazine ('' = the blog's choice)
	heroCardsBlogChoice  '' for the blog's own setting; else the blog's style, and a first card "Blog's choice" is shown
	heroCardsSmall       true for the smaller cards (the Hero text window)
--->
<cfparam name="heroCardsName" default="">
<cfparam name="heroCardsValue" default="classic">
<cfparam name="heroCardsBlogChoice" default="">
<cfparam name="heroCardsSmall" default="false">
<cfset heroCardStyles = [
	{ key: "classic", name: "Classic", what: "The picture sits inside the post, under the title. Quiet and simple, good for posts that are mostly text." },
	{ key: "held", name: "Tall, held", what: "A tall picture that stays put while the post slides up over it. Edge to edge on phones." },
	{ key: "band", name: "Tall band", what: "A tall picture across the top with the title on it. It scrolls away with the page." },
	{ key: "magazine", name: "Magazine", what: "Tall, like a magazine cover, with a large heading low on the left. Edge to edge on phones." }
]>
<!--- Not "Full screen" (2026-10-25): on a computer a post's hero stays in the post's width (design B, 10-22). --->
<cfset heroCardNames = { "classic": "Classic", "held": "Tall, held", "band": "Tall band", "magazine": "Magazine" }>
<!--- A picture that ships with every blog (a theme background). --->
<cfset heroCardPicture = application.baseUrl & "/images/background/themes/antelopCanyon.webp">
<cfif not structKeyExists(request, "heroStyleCardsCss")>
<cfset request.heroStyleCardsCss = true>
<style>
	.heroCards { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 14px; margin-top: 10px; }
	.heroCards.small { grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 10px; }
	@media (max-width: 900px) { .heroCards { grid-template-columns: repeat(2, minmax(0, 1fr)); } .heroCards.small { grid-template-columns: repeat(3, minmax(0, 1fr)); } }
	@media (max-width: 480px) { .heroCards, .heroCards.small { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
	.heroCard { display: flex; flex-direction: column; justify-content: flex-start; text-align: left; padding: 10px; border: 2px solid rgba(128,128,128,.35); border-radius: 8px; background: transparent; color: inherit; font: inherit; cursor: pointer; }
	.heroCard[aria-checked="true"] { border-color: currentColor; }
	.heroCard .heroCardName { display: block; margin: 8px 0 2px; }
	.heroCard .heroCardWhat { display: block; font-size: 13px; opacity: .75; line-height: 1.35; }
	.heroCards.small .heroCardWhat { display: none; }
	.heroCard .heroCardPick { display: block; margin-top: 6px; font-size: 13px; opacity: 0; }
	.heroCard[aria-checked="true"] .heroCardPick { opacity: .9; }
	/* A tiny browser, 16:10: a bar with three dots, then the page. --heroCardBg is the theme's own background (set below). */
	.heroMini, .heroMini span { display: block; }
	.heroMini { position: relative; width: 100%; aspect-ratio: 16 / 10; border-radius: 6px; overflow: hidden; background: var(--heroCardBg, white); border: 1px solid rgba(128,128,128,.4); }
	.heroMini .bar { position: absolute; left: 0; right: 0; top: 0; height: 9%; background: rgba(128,128,128,.25); z-index: 5; }
	.heroMini .bar i { position: absolute; top: 35%; width: 4%; aspect-ratio: 1; border-radius: 50%; background: rgba(128,128,128,.6); }
	.heroMini .bar i:nth-child(1) { left: 3%; } .heroMini .bar i:nth-child(2) { left: 8%; } .heroMini .bar i:nth-child(3) { left: 13%; }
	.heroMini .view { position: absolute; left: 0; right: 0; top: 9%; bottom: 0; overflow: hidden; }
	.heroMini .page { position: absolute; left: 0; right: 0; top: 0; }
	.heroMini .pic { background-position: center; background-size: cover; background-repeat: no-repeat; }
	.heroMini .ln { height: 5px; border-radius: 3px; background: rgba(128,128,128,.45); margin: 0 8% 6px; }
	.heroMini .ln.mid { width: 65%; }
	.heroMini .title { height: 9px; border-radius: 4px; background: rgba(128,128,128,.8); margin: 0 8% 8px; width: 55%; }
	.heroMini .light { background: rgba(255,255,255,.95); box-shadow: 0 1px 3px rgba(0,0,0,.35); }
	.heroMini .body { background: var(--heroCardBg, white); }
	.heroMini .fade { background: linear-gradient(to bottom, transparent, var(--heroCardBg, white)); }
	/* Classic: title, then the picture inside the post; the whole page scrolls. */
	.heroMini.classic .page { animation: heroCardScroll 6s ease-in-out infinite; padding-top: 8%; }
	.heroMini.classic .pic { margin: 0 8% 8px; border-radius: 3px; aspect-ratio: 16 / 7; }
	/* Tall, held: the picture stays; the post slides up over it. */
	.heroMini.held .pic { position: absolute; inset: 0; }
	.heroMini.held .over { position: absolute; left: 0; right: 0; top: 0; height: 100%; animation: heroCardSlide 6s ease-in-out infinite; }
	.heroMini.held .heading { height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; }
	.heroMini.held .heading .title { margin: 0 0 6px; width: 50%; }
	.heroMini.held .heading .ln { width: 34%; margin: 0; }
	.heroMini.held .fade { height: 30px; }
	.heroMini.held .body { padding-top: 4%; }
	/* Tall band: shorter than the screen, so the post's first lines show under it; it scrolls away. */
	.heroMini.band .page { animation: heroCardScroll 6s ease-in-out infinite; }
	.heroMini.band .pic { position: relative; height: 0; padding-bottom: 34%; }
	.heroMini.band .pic .title { position: absolute; left: 0; bottom: 18%; }
	.heroMini.band .fade { height: 14px; margin-top: -14px; position: relative; }
	.heroMini.band .body { padding-top: 6%; }
	/* Magazine: fills the screen, a large heading low on the left; it scrolls away into the post. */
	.heroMini.magazine .page { animation: heroCardScroll 6s ease-in-out infinite; }
	.heroMini.magazine .pic { position: relative; height: 0; padding-bottom: 56%; }
	.heroMini.magazine .pic .big { position: absolute; left: 7%; height: 12px; border-radius: 5px; }
	.heroMini.magazine .pic .big.a { bottom: 30%; width: 62%; }
	.heroMini.magazine .pic .big.b { bottom: 18%; width: 44%; }
	.heroMini.magazine .pic .kicker { position: absolute; left: 7%; bottom: 46%; width: 18%; height: 5px; border-radius: 3px; }
	.heroMini.magazine .fade { height: 18px; margin-top: -18px; position: relative; }
	.heroMini.magazine .body { padding-top: 6%; }
	.heroMini.blogChoice { display: flex; align-items: center; justify-content: center; text-align: center; font-size: 12px; opacity: .8; padding: 0 8px; box-sizing: border-box; }
	@keyframes heroCardScroll { 0%, 22% { transform: translateY(0); } 62%, 82% { transform: translateY(-46%); } 100% { transform: translateY(0); } }
	@keyframes heroCardSlide { 0%, 22% { transform: translateY(0); } 62%, 82% { transform: translateY(-62%); } 100% { transform: translateY(0); } }
	/* Only the chosen card and the one under the pointer play; the rest rest at the top. */
	.heroCard:not([aria-checked="true"]):not(:hover):not(:focus-visible) .page,
	.heroCard:not([aria-checked="true"]):not(:hover):not(:focus-visible) .over { animation-play-state: paused; }
	@media (prefers-reduced-motion: reduce) { .heroMini .page, .heroMini .over { animation: none !important; } }
</style>
</cfif>
<cfset heroCardsGroupId = heroCardsId & "Cards">
<cfoutput>
<input type="hidden" id="#heroCardsId#"<cfif len(heroCardsName)> name="#heroCardsName#"</cfif> value="#encodeForHtmlAttribute(heroCardsValue)#">
<div class="heroCards<cfif heroCardsSmall> small</cfif>" id="#heroCardsGroupId#" role="radiogroup" aria-label="Post hero style" data-for="#heroCardsId#">
	<cfif len(heroCardsBlogChoice)>
	<button type="button" class="heroCard" role="radio" data-style="" aria-checked="#len(heroCardsValue) ? 'false' : 'true'#">
		<span class="heroMini blogChoice">Blog's choice<br/>(#encodeForHtml(heroCardNames[heroCardsBlogChoice] ?: heroCardsBlogChoice)#)</span>
		<span class="heroCardName">Blog's choice</span>
		<span class="heroCardPick">&##10003; Chosen</span>
	</button>
	</cfif>
	<cfloop array="#heroCardStyles#" index="hcs">
	<button type="button" class="heroCard" role="radio" data-style="#hcs.key#" aria-checked="#heroCardsValue eq hcs.key ? 'true' : 'false'#" title="#encodeForHtmlAttribute(hcs.what)#">
		<span class="heroMini #hcs.key#" aria-hidden="true"><span class="bar"><i></i><i></i><i></i></span><span class="view">
		<cfif hcs.key eq "classic">
			<span class="page"><span class="title"></span><span class="pic" style="background-image: url('#heroCardPicture#')"></span><cfloop from="1" to="9" index="i"><span class="ln#i mod 3 eq 0 ? ' mid' : ''#"></span></cfloop></span>
		<cfelseif hcs.key eq "held">
			<span class="pic" style="background-image: url('#heroCardPicture#')"></span>
			<span class="over"><span class="heading"><span class="title light"></span><span class="ln light"></span></span><span class="fade"></span><span class="body"><cfloop from="1" to="9" index="i"><span class="ln#i mod 3 eq 0 ? ' mid' : ''#"></span></cfloop></span></span>
		<cfelseif hcs.key eq "band">
			<span class="page"><span class="pic" style="background-image: url('#heroCardPicture#')"><span class="title light"></span></span><span class="fade"></span><span class="body"><cfloop from="1" to="10" index="i"><span class="ln#i mod 3 eq 0 ? ' mid' : ''#"></span></cfloop></span></span>
		<cfelse>
			<span class="page"><span class="pic" style="background-image: url('#heroCardPicture#')"><span class="kicker light"></span><span class="big a light"></span><span class="big b light"></span></span><span class="fade"></span><span class="body"><cfloop from="1" to="10" index="i"><span class="ln#i mod 3 eq 0 ? ' mid' : ''#"></span></cfloop></span></span>
		</cfif>
		</span></span>
		<span class="heroCardName">#hcs.name#</span>
		<span class="heroCardWhat">#hcs.what#</span>
		<span class="heroCardPick">&##10003; Chosen</span>
	</button>
	</cfloop>
</div>
<script>
	(function () {
		var group = $("###heroCardsGroupId#");
		// The tiny pages take the theme's own background color, so they look right in dark themes too.
		var bg = window.getComputedStyle(group.closest(".k-content, .k-alt")[0] || document.body).backgroundColor;
		if (bg && bg !== "rgba(0, 0, 0, 0)" && bg !== "transparent") { group[0].style.setProperty("--heroCardBg", bg); }
		group.on("click", ".heroCard", function () {
			group.find(".heroCard").attr("aria-checked", "false");
			$(this).attr("aria-checked", "true");
			$("###heroCardsId#").val($(this).attr("data-style")).trigger("change");
		});
	})();
</script>
</cfoutput>

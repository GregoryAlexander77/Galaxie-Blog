<!--- Let the users scroll down to see the whole image. --->
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
			
<!--- Include tail end scripts. --->
<script>
	<!--- Lazy load the images. --->
	deferimg('img.fade', 100, 'lazied', function(img) {
		img.onload = function() {
			img.className+=' shown';
		}
	});
</script>

<!-- PrismJs (our code hightlighter) is only downloaded when the page has code to highlight. See galaxieLoader in head.cfm. -->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// These are the same elements that Prism highlights by default
	if ($('code[class*="language-"], [class*="language-"] code, code[class*="lang-"], [class*="lang-"] code').length) {
		galaxieLoader.prism();
	}
</script>

<!-- Forms placed in a post or page (2026-10-13) are only downloaded when the page has one. See common/js/webForms.js. -->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	if ($('.galaxieWebForm[data-webform], .galaxieWebFormList[data-webform]').length) {
		galaxieLoader.webForms(function() {
			galaxieWebForms.init({ baseUrl: '<cfoutput>#application.baseUrl#</cfoutput>' });
		});
	}
</script>

<!--- When the page has been loaded, fade in the menu's. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// Show the topMenu
	$('#topMenu').css('visibility', 'visible');	
	
	// Get the width of the main flex container ('mainBlog').
	var parentContainerWidth = $( "#mainBlog" ).width();
	
	// Set the width of the footer
	$("#footerDiv").width(parentContainerWidth);
	
	// Listeners 
	// Script to show the sticky header when a certain scroll position has been reached (i.e. the navigation menu that is shown at the top of the page when you scroll down a little bit).
	$(document).scroll(function() {
		var y = $(this).scrollTop();
		// If the user has scrolled down 40 pixels...
		if (y > 40) {
			// Display the fixed nav menu
			$('#fixedNavMenu').css('visibility', 'visible');
			// And fade it in 
			$('#fixedNavHeader').fadeIn();
		} else { // or if the user had scrolled up, or is at the top of the page...
			$('#fixedNavHeader').fadeOut();
		}
	});	
	
</script>

<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// Initialize plyr on the videos. Plyr is only downloaded when the page has a video. See galaxieLoader in head.cfm.
	if ($('video').length) {
		galaxieLoader.plyr(function() {
			const players = Plyr.setup('video', { captions: { active: true } });
			// Expose player so it can be used from the console
			window.players = players;
		});
	}
</script>

<!--- Vanta.js (vantajs.com) is only downloaded when the page actually has a live-animation placeholder to fill -
same "don't pay for what you don't use" pattern as Prism/Plyr just above. Renderer.cfc's isSinglePostPage gating
(see getHeroFallbackHtml()/renderEnclosure()) already guarantees at most one [data-animation-effect] element can
ever exist on any page - this never runs on a card/grid page or on mobile, since those contexts always resolve to
the generated gradient fallback instead. 2026-10-03: renamed from [data-vanta-effect]/[data-vanta-options]/
galaxieLoader.vantaEngine() while still dev-only/unmigrated. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	(function() {
		var animationEl = document.querySelector('[data-animation-effect]');
		if (!animationEl) { return; }
		<!--- Respect the visitor's own OS/browser-level motion preference - a continuous WebGL/canvas render loop
		is exactly the kind of thing prefers-reduced-motion exists to let people opt out of, and it costs nothing
		to check before ever loading Three.js/p5.js for a visitor who's asked not to see it. --->
		if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) { return; }
		var effect = animationEl.getAttribute('data-animation-effect');
		var options = {};
		try { options = JSON.parse(animationEl.getAttribute('data-animation-options') || '{}'); } catch(e) {}
		galaxieLoader.heroAnimationEngine(effect, function() {
			var vantaOptions = {el: animationEl, mouseControls: false, touchControls: false, gyroControls: false};
			<!--- 2026-10-03: only color values (saved as "#hex" strings) need the hex-to-number conversion -
			speed, and the newer per-effect numeric/boolean options (shininess, waveHeight, waveSpeed, zoom,
			points, maxDistance, spacing, showDots), are already genuine numbers/booleans straight out of
			JSON.parse() above, so a typeof check tells them apart with no hardcoded key list to keep in sync
			with heroAnimationEditor.cfm's own options. --->
			Object.keys(options).forEach(function(key) {
				vantaOptions[key] = (typeof options[key] === 'string') ? parseInt(options[key].replace('#', ''), 16) : options[key];
			});
			<!--- 2026-10-03: BIRDS' colorMode and CLOUDS2's texturePath never go through the saved-options
			pipeline above - see heroAnimationEditor.cfm's applyEffectSpecificVantaOptions() for why. Keep this
			block in sync with that function and preview/heroAnimation.cfm's own copy if either effect's
			handling ever changes. --->
			if (effect === 'BIRDS') {
				vantaOptions.colorMode = 'varianceGradient';
			} else if (effect === 'CLOUDS2') {
				vantaOptions.texturePath = '<cfoutput>#application.baseUrl#</cfoutput>/common/libs/vanta/noise.png';
			}
			if (window.VANTA && window.VANTA[effect]) {
				window.VANTA[effect](vantaOptions);
			}
		});
	})();
</script>
<!--- Disqus tail end script to enable the number of page views and the comment count. Only include this when we are looking at the blog. Disqus comments are obviously not going to be available in the admin page! --->
<cfif application.includeDisqus and pageTypeId eq 1>
<script id="dsq-count-scr" type="<cfoutput>#scriptTypeString#</cfoutput>" src="//<cfoutput>#application.disqusBlogIdentifier#</cfoutput>.disqus.com/count.js" async></script>
</cfif>
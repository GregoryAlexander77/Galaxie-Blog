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
<!--- Disqus tail end script to enable the number of page views and the comment count. Only include this when we are looking at the blog. Disqus comments are obviously not going to be available in the admin page! --->
<cfif application.includeDisqus and pageTypeId eq 1>
<script id="dsq-count-scr" type="<cfoutput>#scriptTypeString#</cfoutput>" src="//<cfoutput>#application.disqusBlogIdentifier#</cfoutput>.disqus.com/count.js" async></script>
</cfif>
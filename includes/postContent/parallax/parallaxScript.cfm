<cfset scriptTypeString = "deferjs"><!---deferjs text/javascript--->
<!--- Note: this template should have all of the variables on the index.cfm present. --->
<br/>
<style>

	:root {
		--scrollViewWidth: 80%;
	}
</style>

<!--- Include the css. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '<cfoutput>#application.baseUrl#</cfoutput>includes/postContent/parallax/parallaxCss.css') );
</script>

<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		
	// Reload if the session is not defined.
	isiPad = navigator.userAgent.match(/iPad/i) != null;
	
	// Refresh the browser when it is resized. Don't do this on mobile or in the iPad.
	if (!isMobile && !isiPad){
		$(window).bind('resize', function(e){
			if (window.RT) clearTimeout(window.RT);
			window.RT = setTimeout(function(){
				this.location.reload(false); /* false to get page from cache */
			}, 100);
		});
	}
		
	// Resize when a mobile device's orientation has changed.
	// Listen for orientation changes    
	if (!isMobile){
		window.addEventListener("orientationchange", function() {
			// Reload
			this.location.reload(false); /* false to get page from cache */
		}, false);
	}
	
	// Set the content width depending upon the screen size.
	function setCssVars() {
			
		document.documentElement.style.setProperty("--sceneFontSize", "18pt");
		document.documentElement.style.setProperty("--sceneHeaderFontSize", "1.5em");
		document.documentElement.style.setProperty("--splashTitleFontSize", getSplashTitleFontSize());
		document.documentElement.style.setProperty("--sceneContainerWidth", "80%");
		document.documentElement.style.setProperty("--scrollViewFont", "Eras Demi");
		document.documentElement.style.setProperty("--scrollViewFontSize", "18pt");
		document.documentElement.style.setProperty("--scrollViewTextAlign", "center");
		document.documentElement.style.setProperty("--scrollViewHeight", "575px");
		document.documentElement.style.setProperty("--slideBottomPercent", "30%");
		document.documentElement.style.setProperty("--lastSlideBottomPercent", "20%");
		document.documentElement.style.setProperty("--navigationRightPosition", "30px");
		document.documentElement.style.setProperty("--toolTipWidth", "300px");
		document.documentElement.style.setProperty("--toolTipHeight", "175px");
		document.documentElement.style.setProperty("--toolTipFontSize", "10pt");
		document.documentElement.style.setProperty("--grizzlyWindowHeight", "750px");
		document.documentElement.style.setProperty("--grizzlyWindowWidth", "975px");
		document.documentElement.style.setProperty("--headerCornerImageWidth", "100%");
		
	}
		
	// function to set the splash title font size. The splash title div sets the font size bigger than the rest of the containers, so the font size needs to be reduced a little bit. 
	function getSplashTitleFontSize(){
		// Get the window width
		var windowWidth = $(window).width();
		// Get the scrollViewWidth value.
		var sceneFontSize = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sceneFontSize'));
		// Calculate the pixel width
		var splashTitleFontSize = sceneFontSize - 4;
		// Return it.
		return splashTitleFontSize;	
	}
	
		
	function getGrizzlyWindowHeight(){
		return getComputedStyle(document.documentElement).getPropertyValue('--grizzlyWindowHeight');
	}
		
	function getGrizzlyWindowWidth(){
		return getComputedStyle(document.documentElement).getPropertyValue('--grizzlyWindowWidth');
	}
	
	// Function to determine if the browser supports global css vars. The else block is used for IE 11 which returns undefined. 
	function getBrowserSupportForCssVars() {
		if (window.CSS && CSS.supports('color', 'var(--fake-var)')){
			return window.CSS && CSS.supports('color', 'var(--fake-var)');
		} else {
			return false;
		}	
	}
	
	// Helper functions
	// This function is used to set the max-width for the blogContent and the sideBar. We need to get the number of pixes for a given percent. 
	function calculatePercent(percent, number){
		var val = ((percent/100) * number);
		return Math.round(val);
	}
		
	/* Theme helper functions */
	function getThemeIdFromBaseKendoTheme(baseKendoTheme){
		switch(baseKendoTheme) {
			case "black":
				var themeId = 1;
			break;	
			case "blueOpal":
				var themeId = 2;
			break;
			case "default":
				var themeId = 3;
			break;
			case "fiori":
				var themeId = 4;
			break;
			case "flat":
				var themeId = 5;
			break;
			case "highcontrast":
				var themeId = 6;		  
			break;
			case "material":
				var themeId = 7;	  
			break;
			case "materialblack":
				var themeId = 8;	  
			break;
			case "metro":
				var themeId = 9;	  
			break;
			case "moonlight":
				var themeId = 10;		  
			break;
			case "nova":
				var themeId = 11;	  
			break;
			case "office365":
				var themeId = 12;		  
			break;
			case "silver":
				var themeId = 13;	  
			break;
			case "uniform":
				var themeId = 14;		  
			break;
		}
	}
					  	
</script>
	
</head>
	
<body onload="setCssVars();" onresize="setCssVars()">
	
	<!-- Hidden form to indicate the scene. We will use this to prevent duplicate notifications when the user scrolls quickly down the page when we use notification timings. -->
	<input type="hidden" id="currentScene" name="currentScene" value="intro">	
	
	<div id="mainContainer" class="main-container">

		<article id="cb01" class="content-block1 blueGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Introducing Galaxie Blog</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Galaxie Blog is a free open source ColdFusion based blog.</p>
					<p class="slideInUp slideInUp3">It is intended to be the most beautiful and functional open sourced ColdFusion based blog in the world.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide01" class="slide fs">
			<div class="bcg"></div>
			<!-- We need an empty header on this particular slide for two reasons. 1) I don't want text to be shown (I only want the arch), and 2) as the main.js uses each header to determine the index dynamically, we need to have something here, even if it is empty. -->
			<div class="wrapper">
				<header class="slideInUp">
					
				</header>
				<section>

				</section>
			</div> <!-- .wrapper -->
			
			<!-- We will show the arch here unlike the rest of normal scenes which has it's text content above and a background setting in the css. -->
			<div class="container">
				<p class="title slideInUp">
					If you're a ColdFusion developer, come back to a ColdFusion based Blog....
				</p>
				<p class="title slideInUp">
					Galaxie Blog is a completely modernized version of BlogCfc...
				</p>
				<div class="images">
					<!-- The entire image. The fastest moving layer. -->
					<div class="image-wrapper" id="first">
						<img src="/images/parallax/blog/arch/1.png" />
					</div>
					<!--The horizon is cropped out. -->
					<div class="image-wrapper" id="second">
						<img src="/images/parallax/blog/arch/2.png" />
					</div>
					<!-- More of the horizon is cropped out... -->
					<div class="image-wrapper" id="third">
						<img src="/images/parallax/blog/arch/3.png" />
					</div>
					<!-- ... -->
					<div class="image-wrapper" id="forth">
						<img src="/images/parallax/blog/arch/4.png" />
					</div>
					<!-- ... -->
					<div class="image-wrapper" id="fifth">
						<img src="/images/parallax/blog/arch/5.png" />
					</div>
					<!-- And only the focal point is left. -->
					<div class="image-wrapper" id="sixth">
						<img src="/images/parallax/blog/arch/6.png" />
						<div class="parallaxDivider"></div>
					</div>
					
				</div>
			</div>
		</article>
		
		
		<article id="cb02" class="content-block1 burntOrangeGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Stunning Mobile Interface...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Galaxie Blog is a responsive website that offers nearly identical functionality for both desktop and mobile devices.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide02" class="slide fs">
			<div class="bcg"></div>
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Galaxie Blog is Eminently Themeable</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Galaxie Blog has dozens of professionally designed pre-defined themes.</p>
					<p class="slideInUp slideInUp3">Changing the look and feel of you blog does not require any coding, you can use web based interfaces to perfectly adjust each theme.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>
		
		
		<article id="cb03" class="content-block2 greenGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Versatile Post Formats...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Add podcasts, thumbnails, images, and enclosures. Blog entries support using inline .css, scripts, and HTML.</p>
					
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide03" class="slide fs">
			<div class="bcg"></div>
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Add Engaging Content and Special Effects...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Includes a HTML5 media player as well as a Flash player to allow users to add various media. </p>
					<p class="slideInUp slideInUp3">Galaxie Blog also has built in support for animations using the <b>Green Sock Animation Platform.</b></p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		
		<article id="cb04" class="content-block3 blueGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Display Your Code....</h2>
				</header>
				<section>
					<div class="slideInUp slideInUp2">
						Easilly display your code by wrapping your posts with "code" tags. The code will be displayed and will be automatically adjusted to match your theme.
					</div>
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide04" class="slide fs">
			<div class="bcg"></div>
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Interact With Your Users...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Galaxie Blog allows users to add comments and use their own gravatar.</p>
					<p class="slideInUp slideInUp3">Captcha support and blog moderation capabilities are included.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		
		<article id="cb05" class="content-block4 burntOrangeGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Share Your Content...</h2>
				</header>
				<section>
					<div class="slideInUp slideInUp2">
						Allow readers to share your blog content with built-in social media sharing.</p>
					</div>
					<p class="slideInUp slideInUp3">Users can subscribe to your blog or subscribe to a selected post. Galaxie Blog also can share your content with various communities via RSS feeds.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide05" class="slide fs">
			<div class="bcg"></div>
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Organize And Find Your Posts...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">Categories and tag support are built-in. You can also associate your blog entries and related posts.</p>
					<p class="slideInUp slideInUp3">Find your posts using a search engine at the top of the site. Posts are also  automatically displayed by date and can be selected using a calendar control.</p>
				</section>
			</div> <!-- .wrapper -->
		</article>

		
		<article id="cb06" class="content-block5 greenGradient">
			<div class="wrapper">
				<header class="slideInUp">
					<h2>Optimized for Search Engines</h2>
				</header>
				<section>
					<div class="slideInUp slideInUp2">
						Galaxie Blog is SEO friendly and has a 100% google SEO score. 
					</div>
				</section>
			</div> <!-- .wrapper -->
		</article>

		<article id="slide06" class="slide fs">
			<div class="bcg"></div>
			<div class="wrapper">
				<header class="slideInUp">
					<h2>The Future of Galaxie Blog...</h2>
				</header>
				<section>
					<p class="slideInUp slideInUp2">I intend using Galaxie Blog for my own personal blog, and it is a key component of my own personal portfolio.</p>
					<p class="slideInUp slideInUp3">I am adding capabilities to use a rich editor within a mobile interface to quickly share my personal photography while out in the field.</p>
				</section>
			</div> <!-- .wrapper -->
			
		</article>
		
		<a id="slide6"></a>

	</div>

	<div id="lowerDividerImage" style="background-image: url(/images/borders/grey.png); height: 6px;">&nbsp;</div>

	<div class="footer-container">
		<footer>
			<br/><br/>
			<div class="blogFeaturesWrapper">
			Galaxie Blog Features:
			<ul class="blogFeatures">
			  <li>Beautiful modern interface</li>
			  <li>Responsive website with a stunning mobile interface</li>
			  <li>Proportions are adjusted for 8 different device sizes</li>
			  <li>Works with all modern devices.</li>
			  <li>Dozens of pre-installed proffesionally designed themes</li>
			  <li>Themes can be completely customized using web interfaces</li>
			  <li>Code formatting adjusts to match your selected theme</li>
			  <li>Web based installation</li>
			  <li>Setup Social Media sharing in minutes without any coding</li>
			  <li>Autmotically adds open graph facebook and twitter meta tags</li>
			  <li>Add images and enclosures with a click of a button</li>
			  <li>Thumbnail support</li>
			  <li>Related entries</li>
			  <li>Add engaging animations using theGreenSock Animation Platform</li>
			  <li>HTML 5 based media player</li>
			  <li>Flash player for legacy support </li>
			  <li>Podcasting</li>
			  <li>Supports inline .CSS, scripts and HTML within blog posts</li>
			  <li>Users may subscribe to the blog or to a given post</li>
			  <li>Built in captcha</li>
			  <li>Comment moderation</li>
			  <li>Preview your entry prior to posting</li>
			  <li>SEO optimization</li>
			  <li>Automatic google site map creation</li>
			  <li>Search functionality</li>
			  <li>Update notifications</li>
			  <li>Site statistics</li>
			  <li>RSS feeds </li>
			  <li>CFBlogger integration</li>
			  <li>Textblock support</li>
			  <li>Print Blog Entry</li>
			  <li>Extensible plug-in architecture</li>
			  <li>Built on top of BlogCfc for easy ColdFusion integration</li>
			</ul>
			</div>
			<p>Photography and design by Gregory Alexander | Copyright &copy; 2019 Gregory Alexander</p>
		</footer>
		<div align="center">
			<img src="/images/logo/gregoryAlexanderLogo125_190.png" />
		</div>	
	</div>

	<!-- Custom sroll magic js (and custom kendo notifications from my extended notification UI library) -->
	<script  type="<cfoutput>#scriptTypeString#</cfoutput>">
	$( document ).ready(function() {
		(function ($) {

			// Init ScrollMagic
			var controller = new ScrollMagic.Controller();
			// Get all slides
			var slides = ["#slide01", "#slide02", "#slide03", "#slide04", "#slide05", "#slide06"];
			// Get all headers in slides that trigger animation
			var headers = ["#slide01 header", "#slide02 header", "#slide03 header", "#slide04 header", "#slide05 header", "#slide06 header"];
			// Get all break up sections
			var breakSections = ["#cb01", "#cb02", "#cb03", "#cb04", "#cb05", "#cb06"];

			// Headers. Create scenes for each of the headers.
			headers.forEach(function (header, index) {
				// number for highlighting scenes
				var num = index+1;
				// make scene
				var headerScene = new ScrollMagic.Scene({
					triggerElement: header, // trigger CSS animation when header is in the middle of the viewport 
					offset: -95 // offset triggers the animation 95 earlier then middle of the viewport, adjust to your liking
				})
				.setClassToggle('#slide0'+num, 'is-active') // set class to active slide
				.on("leave", function (event) {
					// Don't handle events until the page is loaded.
				})
				//.addIndicators() // add indicators; used for debugging
				.addTo(controller);
			});

			// Break sections. Here we will set initial properties to change the color of the nav for dark content blocks.
			breakSections.forEach(function (breakSection, index) {
				// number for highlighting scenes
				var breakID = $(breakSection).attr('id');
				// make scene
				var breakScene = new ScrollMagic.Scene({
					triggerElement: breakSection, // trigger CSS animation when header is in the middle of the viewport 
					triggerHook: 0.75
				})
				// For each breakSection, change the color of the nav when scrolling down. Note: we don't enter a break section when scrolling up.
				.on("enter", function (event) {
					// Don't handle events until the page is loaded.
				})
				// Reset nav elements when we leave a break. The nav dot names in order are navDotSlide1, navDotBreak1, etc..
				.on('leave', function (event) {
					// Don't handle events until the page is loaded.
				})
				.setClassToggle('#'+breakID, 'is-active') // set class to active slide
				//.addIndicators() // add indicators; used for debugging
				.addTo(controller);
			});

			// Logic for all slides.
			slides.forEach(function (slide, index) {
				var slideScene = new ScrollMagic.Scene({
					triggerElement: slide // trigger CSS animation when header is in the middle of the viewport
				})
				.on("enter", function (event) {
					// Don't handle events until the page is loaded.
				})
				.on("leave", function (event) {
					// Don't handle events until the page is loaded.
				})
				//.addIndicators() // add indicators; used for debugging
				.addTo(controller);
			});

			// Slides 2. Parallax effect on each of the slides with bcg
			// Move bcg container when slide gets into the view
			slides.forEach(function (slide, index) {
				var $bcg = $(slide).find('.bcg');
				var slideParallaxScene = new ScrollMagic.Scene({
					triggerElement: slide, 
					triggerHook: 1,
					duration: "100%"
				})
				.setTween(TweenMax.from($bcg, 1, {y: '-40%', autoAlpha: 0.3, ease:Power0.easeNone}))
				// Event management.
				.on('leave', function (event) {
					// Don't handle events until the page is loaded.
				})
				//.addIndicators() // add indicators; used for debugging
				.addTo(controller);
			});


			// Change behaviour of controller to animate scroll instead of jump
			controller.scrollTo(function (newpos) {
				setTimeout(
					TweenMax.to(window, 1, {scrollTo: {y: newpos, autoKill: false}, ease:Power1.easeInOut})
				,100);
			});

			//  Bind scroll to anchor links
			$(document).on("click", "a[href^='#']", function (e) {
				var id = $(this).attr("href");
				if ($(id).length > 0) {
					// iPhones are having problems scrolling using anition. I will only use animations on the desktop.
					if (!navigator.userAgent.match(/(iPod|iPhone|iPad|Android)/)) { 
						e.preventDefault();
						// trigger scroll
						setTimeout(
							controller.scrollTo(id)
						,100);

						// if supported by the browser we can even update the URL.
						if (window.history && window.history.pushState) {
							history.pushState("", document.title, id);
						}
					}
				}
			});

		}(jQuery));
	});//..$( document ).ready(function() {
	</script>

	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		// Note: if you don't defer loading, typically we would have the following line 'document.addEventListener('DOMContentLoaded', () => {'
			// The 'let' keyword is a variable that has 'block' scope. These vars reside within the parallax block.
			let controller = new ScrollMagic.Controller();
			// Create the timeline.
			let timeline = new TimelineMax();
			// Set the increment. The parallax effect is more pronounced on mobile due to the aspect ratio of the screen. We want to double the effect on the desktop to match the mobile site.
			if (isMobile){
				yIncrement = 1;
			} else {
				yIncrement = 2;
			}

			timeline
			/* Descending order */
			.to('#sixth', 6, {
				y: -700 * yIncrement
			})
			.to('#fifth', 6, {
				y: -500 * yIncrement
			}, '-=6')
			.to('#forth', 6, {
				y: -400 * yIncrement
			}, '-=6')
			.to('#third', 6, {
				y: -300 * yIncrement
			}, '-=6')
			.to('#second', 6, {
				y: -200 * yIncrement
			}, '-=6')
			.to('#first', 6, {
				y: -100 * yIncrement
			}, '-=6')
			/* Pull the any elements within the parallax block and attach it to the next layer (cb02) */
			.to('#cb02', 6, {
				top: '0%'
			}, '-=6')
			/* And pull up the next sections underneath the parallax effect. */
			.to('#aboutThisParallax, #parallaxLocation, .parallaxDivider, #cb02, #slide02, #cb03, #slide03, #cb04, #slide04, #cb05, #slide05, #cb06, #slide06, #lowerDividerImage, .footer-container', 6, {
				y: -600,
			}, '-=6')
			/* Ascending order */
			.from('.one', 3, {
				top: '40px',
				autoAlpha: 0
			}, '-=4')
			.from('.two', 3, {
				top: '40px',
				autoAlpha: 0
			}, '-=3.5')
			.from('.three', 3, {
				top: '40px',
				autoAlpha: 0
			}, '-=3.5')
			.from('.four', 3, {
				top: '40px',
				autoAlpha: 0
			}, '-=3.5')
			.from('.text', 3, {
				y: 60,
				autoAlpha: 0
			}, '-=4')

			let scene = new ScrollMagic.Scene({
				triggerElement: 'section',
				duration: '400%', /* Note: this is typically set for 200% for parallax, however, that setting will extend the scene and make the content block really long. */
				triggerHook: 0
			})
			.setTween(timeline)
			.setPin('section')
			//.addIndicators() // add indicators; used for debugging
			.addTo(controller);
		//})
	</script>
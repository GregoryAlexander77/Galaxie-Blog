<cfset scriptTypeString = "deferjs"><!---deferjs text/javascript--->
<cfset parallaxName = "galaxie357">
<cfset webpImageSupported = true>
	
<!--- Notes: this template can be reused. However, we need to keep track if the template was loaded prior to the current scene in order not to duplicate the logic. We will be setting a gsapTemplateLoaded var which will be set to true at the end of the page. --->
<cfparam name="gsapTemplateLoaded" type="boolean" default="false">

<!--- Do webp? --->
<cfif webpImageSupported>
	<cfset imageExtension = ".webp">
<cfelse>
	<cfset imageExtension = ".jpg">
</cfif>
<!--- We are using smaller image sizes for mobile. --->
<cfif session.isMobile>
	<cfset imageWidth = "640">
<cfelse>
	<cfset imageWidth = "980">
</cfif>
	
<cfset h2FontSize = "1.8em">
<cfset h3FontSize = "1.4em">
<cfset paragraphFontSize = "1.2em">
	
<!--- Set the text and parallax images --->	
<cfset cb01Header = "Galaxie Blog 3.57 Released...">
<cfset cb01Text1 = "Galaxie Blog 3.57 has many new features...">
<cfset cb01Text2 = "And works with CF2023, the latest version of ColdFusion...">
	
<cfset cb02Header = "Galaxie Blog is fast....">
<cfset cb02Text1 = "Galaxie Blog consistently averages 94% in Google lighthouse scores.">
<cfset cb02Text2 = "For comparison, the industry average performance score of the top ecommerce sites is is around 60%.">
	
<cfset slide02Header = "Visually Appealing With Rich Media...">
<cfset slide02Text1 = "In addition to being fast, Galaxie Blog is visually appealing and supports a variety of rich media.">
<cfset slide02Text2 = "You can also add Bing static maps and map routes, hardware-accelerated carousels, image galleries, videos from various sources.">
	
<cfset cb03Header = "User-Friendly Drag and Drop Editors...">
<cfset cb03Text1 = "These editors allow you to craft the perfect post and use drag-and-drop interfaces to add various types of rich media.">
<cfset cb03Text2 = "The editors can upload files, images, videos, carousels, galleries, embed Bing Maps to a post and more.">
	
<cfset slide03Header = "Attractive Design...">
<cfset slide03Text1 = "Posts are laid out in an attractive card layout.">
<cfset slide03Text2 = "The most popular posts are available at the top of the page as a scrolling widget, and you can filter the posts by category.">
	
<cfset cb04Header = "Stunning Mobile Interface...">
<cfset cb04Text1 = "Galaxie Blog is a responsive website offering nearly identical functionality for desktop and mobile devices.">
<cfset cb04Text2 = "Much emphasis has been placed on perfecting the mobile experience so you can manage the blog and create stunning posts with a tablet or a phone.">
	
<cfset slide04Header = "Galaxie Blog is Eminently Themeable...">
<cfset slide04Text1 = "It has nearly 40 pre-built themes; you can edit or develop a new theme within minutes.">
<cfset slide04Text2 = "">
	
<cfset cb05Header = "Supports all Modern Databases...">
<cfset cb05Text1 = "Galaxie Blog uses Hibernate ORM underneath the hood and can support all modern databases!">
<cfset cb05Text2 = "">
	
<cfset slide05Header = "Perfect Google Lighthouse SEO Scores...">
<cfset slide05Text1 = "There is no reason to buy costly third-party plugins to promote your blog; Galaxie Blog has a perfect SEO score.">
<cfset slide05Text2 = "Galaxie Blog is also integrated with Google Analytics to analyze traffic and trends.">
	
<cfset cb06Header = "Free and Open Source...">
<cfset cb06Text1 = "Galaxie Blog includes everything needed to create a beautiful blog.">
<cfset cb06Text2 = "Unlike other blogging platforms, there is no additional upcharge for additional functionality that should have been initially built in.">
	
<cfset slide06Header = "Future of Galaxie Blog...">
<cfset slide06Text1 = "In the next version, Galaxie Blog will be a complete CMS system.">
<cfset slide06Text2 = "And Lucee support is coming soon.">
	
<!--- Content block gradients. --->
<cfset contentBlock1Gradient = "sunset-delicate-arch"><!---blueGradient--->
<cfset contentBlock2Gradient = "sunset-delicate-arch-base">
<cfset contentBlock3Gradient = "burntOrangeGradient">
<cfset contentBlock4Gradient = "sunset-delicate-arch-base">
<cfset contentBlock5Gradient = "burntOrangeGradient">
<cfset contentBlock6Gradient = "sunset-delicate-arch-base">
	
<!--- Parallax images --->
<cfset parallaxImage1 = "/images/parallax/blog/arch/1.png">
<cfset parallaxImage2 = "/images/parallax/blog/arch/2.png">
<cfset parallaxImage3 = "/images/parallax/blog/arch/3.png">
<cfset parallaxImage4 = "/images/parallax/blog/arch/4.png">
<cfset parallaxImage5 = "/images/parallax/blog/arch/5.png">
<cfset parallaxImage6 = "/images/parallax/blog/arch/6.png">
<!--- Set the parallax divider at the end of the scene. This is the color immediately underneath the parallax scene and should match the last image of the parallax scene and the top of the contentBlock2Gradient. --->
<cfset parallaxDividerColor = "853800">
	
<!--- Background images --->
<cfset slide02BgImage = "/blog/includes/postContent/parallax/images/canyonLands">
<cfif session.isMobile>
	<cfset slide02BgImage = slide02BgImage & "Small" & imageExtension>
<cfelse>
	<cfset slide02BgImage = slide02BgImage & "Large" & imageExtension>
</cfif> 
<cfset slide03BgImage = "/blog/includes/postContent/parallax/images/subway">
<cfif session.isMobile>
	<cfset slide03BgImage = slide03BgImage & "Small" & imageExtension>
<cfelse>
	<cfset slide03BgImage = slide03BgImage & "Large" & imageExtension>
</cfif> 
<cfset slide04BgImage = "/blog/includes/postContent/parallax/images/archangelFalls">
<cfif session.isMobile>
	<cfset slide04BgImage = slide04BgImage & "Small" & imageExtension>
<cfelse>
	<cfset slide04BgImage = slide04BgImage & "Large" & imageExtension>
</cfif> 
<cfset slide05BgImage = "/blog/includes/postContent/parallax/images/horseShoeBend">
<cfif session.isMobile>
	<cfset slide05BgImage = slide05BgImage & "Small" & imageExtension>
<cfelse>
	<cfset slide05BgImage = slide05BgImage & "Large" & imageExtension>
</cfif> 
<cfset slide06BgImage = "/blog/includes/postContent/parallax/images/monumentValley">
<cfif session.isMobile>
	<cfset slide06BgImage = slide06BgImage & "Small" & imageExtension>
<cfelse>
	<cfset slide06BgImage = slide06BgImage & "Large" & imageExtension>
</cfif> 
	
<!--- Note: this template should have all of the variables on the index.cfm present. --->
<br/>
<cfif not gsapTemplateLoaded>
<style>

	:root {
		--scrollViewWidth: 80%;
	}
</style>
</cfif>
<!-- Preload the fonts -->
<style rel="preload" as="font">
	<!--- Special fonts --->
	@font-face {
		font-family: "Eras Light";
		src: url(/blog/common/fonts/erasLight.woff2) format("woff2");
	}
	@font-face {
		font-family: "Eras Book";
		src: url(/blog/common/fonts/erasBook.woff2) format("woff2");
	}
	@font-face {
		font-family: "Eras Bold";
		src: url(/blog/common/fonts/erasBold.woff2) format("woff2");
	}			
	@font-face {
		font-family: "Eras Demi";
		src: url(/blog/common/fonts/erasDemi.woff2) format("woff2");
	}
	@font-face {
		font-family: "Eras Med";
		src: url(/blog/common/fonts/erasMed.woff2) format("woff2");
	}
	@font-face {
		font-family: "Kaufmann Script Bold";
		src: url(/blog/common/fonts/kaufmannScriptBold.woff2) format("woff2");
	}
</style> 
<!--- Include the css. --->
<style>
	<cfif not session.isMobile>
	h2  {
		font-size: <cfoutput>#h2FontSize#</cfoutput> !important;
	}
	
	h3 {
		font-size: <cfoutput>#h3FontSize#</cfoutput> !important;
	}
	
	p {
		font-size: <cfoutput>#paragraphFontSize#</cfoutput> !important;
	}
	</cfif>
	
	.burntOrangeGradient {
		<!--- Burnt orange gradient --->
		background: rgb(98,55,30);
		background: -webkit-linear-gradient(bottom, rgba(98,55,30,1) 25%, rgba(157,89,49,1) 100%);
		background: -o-linear-gradient(bottom, rgba(98,55,30,1) 25%, rgba(157,89,49,1) 100%);
		background: linear-gradient(to top, rgba(98,55,30,1) 25%, rgba(157,89,49,1) 100%);
	}

	.greenGradient {
		<!--- Green background color of the transition blocks --->
		background: rgb(40,52,31);
		background: -webkit-linear-gradient(bottom, rgba(40,52,31,1) 25%, rgba(74,98,57,1) 100%);
		background: -o-linear-gradient(bottom, rgba(40,52,31,1) 25%, rgba(74,98,57,1) 100%);
		background: linear-gradient(to top, rgba(40,52,31,1) 25%, rgba(74,98,57,1) 100%);
	}

	.blueGradient {
		background: rgb(1,35,52);
		background: -webkit-linear-gradient(bottom, rgba(1,35,52,1) 0%, rgba(4,111,161,1) 100%);
		background: -o-linear-gradient(bottom, rgba(1,35,52,1) 0%, rgba(4,111,161,1) 100%);
		background: linear-gradient(to top, rgba(1,35,52,1) 0%, rgba(4,111,161,1) 100%);
	}
	
	.nightSkyGradient {
		background: rgb(52,36,76);
        background: -webkit-linear-gradient(95deg, rgba(52,36,76,1) 29%, rgba(4,27,38,1) 100%);
        background: -o-linear-gradient(95deg, rgba(52,36,76,1) 29%, rgba(4,27,38,1) 100%);
        background: linear-gradient(185deg, rgba(52,36,76,1) 29%, rgba(4,27,38,1) 100%);
	}
	
	<!--- Delicate Arch Sunset #792D47 #BC4B71 #09467F #C3D7E9 --->
	.sunset-delicate-arch { 
		background: #09467F;  /* fallback for old browsers */
		background: -webkit-linear-gradient(to bottom, #09467F, #8BA0BF);  /* Chrome 10-25, Safari 5.1-6 */
		background: linear-gradient(to bottom, #09467F, #8BA0BF); /* W3C, IE 10+/ Edge, Firefox 16+, Chrome 26+, Opera 12+, Safari 7+ */
	}
	
	.sunset-delicate-arch-base { 
		background: #A43D0C;  /* fallback for old browsers */
		background: -webkit-linear-gradient(to bottom, #853800, #A43D0C);  /* Chrome 10-25, Safari 5.1-6 */
		background: linear-gradient(to bottom, #853800, #A43D0C); /* W3C, IE 10+/ Edge, Firefox 16+, Chrome 26+, Opera 12+, Safari 7+ */
	}


	<!--- Common classes --->
	.clear:before, .clear:after {
	  content: ' ';
	  display: table; 
	}

	.clear {
	  *zoom: 1; 
	}

	.clear:after {
		clear: both; 
	}

	<!--- Page content --->
	html, body
	{
		overflow-x: hidden;
	}

	article, aside, details, figcaption, figure, footer, header, hgroup, main, menu, nav, section, summary {
	  display: block; 
	}

	[hidden], template {
	  display: none; 
	}

	dfn {
	  font-style: italic; 
	}

	mark {
	  background: #ff0;
	  color: #000; 
	}

	svg:not(:root) {
	  overflow: hidden; 
	}

	figure {
	  margin: 1em 40px; 
	}

	::-moz-selection {
	  background: #b3d4fc;
	  text-shadow: none; 
	}

	::selection {
	  background: #b3d4fc;
	  text-shadow: none; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-fs {
		<!--- Note: removing the height will collapse all of the screens. This may prove to be useful when modifying this --->
		height: 100vh; 
		width: 100%;
		overflow-x: hidden;
	}

	.mediaPlayer {
		white-space: nowrap;
		overflow: hidden;
		<!--- The players z-index must be set lower than the rest of the elements, or the media player will bleed through the other elements that should be on top of this --->
		z-index: 0;

		widows: 640px;
		height: 480px;
	}

	<!--- Styles for text containers --->
	.splashTitle {

	}

	.splashTitleWithShadow {
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: 1.6em;
		text-shadow: 
			5px 5px 20px #000,
			10px 10px 50px #000,
			20px 20px 100px #000;
	}

	<!--- Blurb on home page --->
	.splashContentFont {
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: var(--splashTitleFontSize);
		text-shadow: 
			5px 5px 20px #000,
			10px 10px 50px #000,
			20px 20px 100px #000;
	}

	<!--- General styles --->

	<!--- Header --->
	.header-container {
		text-align: var(--scrollViewTextAlign);
		color: #ffffff; 
	}

	.header-container .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding-top: 120px;
		z-index: 2;
		position: relative;
	}

	<!--- Css for main layers --->
	.bcg {
		background: no-repeat center center;
		background-size: cover;
		position: absolute;
		width: 100%;
		height: 100%;
		z-index: 1;
		<!--- Main opacity (this is no longer needed for desktop, and it makes things ugly on mobile devices). opacity: 0.5; --->
	}

	<!--- Images: note- if you use center, the image may not be at full screen and show a white artifact when using smaller displays. --->
	.header-container .bcg {
		<!--- The parallax arch is here --->
	}

	<!--- Slide 1 is a parallax --->
	#<cfoutput>#parallaxName#</cfoutput>-slide01 .bcg {
		<!--- background-color: #000; --->
	}
	
	#<cfoutput>#parallaxName#</cfoutput>-slide02 .bcg {
		background: url("<cfoutput>#slide02BgImage#</cfoutput>") no-repeat center top;
		background-size: cover; 
			-webkit-background-size: cover;
			-moz-background-size:  cover;
			-o-background-size: cover;
	}

	#<cfoutput>#parallaxName#</cfoutput>-slide03 .bcg {
		background: url("<cfoutput>#slide03BgImage#</cfoutput>") no-repeat center center;
		background-size: cover; 
			-webkit-background-size: cover;
			-moz-background-size:  cover;
			-o-background-size: cover;
	}

	#<cfoutput>#parallaxName#</cfoutput>-slide04 .bcg {
		background: url("<cfoutput>#slide04BgImage#</cfoutput>") no-repeat center center;
		background-size: cover;
			-webkit-background-size: cover;
			-moz-background-size:  cover;
			-o-background-size: cover;
		opacity: 0.7; 
	}

	#<cfoutput>#parallaxName#</cfoutput>-slide05 .bcg {
		background: url("<cfoutput>#slide05BgImage#</cfoutput>") no-repeat center center;
		background-size: cover;
			-webkit-background-size: cover;
			-moz-background-size:  cover;
			-o-background-size: cover;
		opacity: 0.7; 
	}

	#<cfoutput>#parallaxName#</cfoutput>-slide06 .bcg {
		background: url("<cfoutput>#slide06BgImage#</cfoutput>") no-repeat center center;
		background-size: cover;
			-webkit-background-size: cover;
			-moz-background-size:  cover;
			-o-background-size: cover;
		opacity: 0.7; 
	}

	<!--- Slides --->
	.<cfoutput>#parallaxName#</cfoutput>-slide {
		<!--- Font properties of the slides --->
		color: #ffffff;
		position: relative; 
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: var(--sceneFontSize) !important;
		<!--- Hard back text shadow --->
		text-shadow: 3px 3px 0 #000000;
		/* <cfoutput>#parallaxName#</cfoutput>-second text shadow with black 18 pixel glow */
		text-shadow: 3px 3px 18px #000000;
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding-top: 30px;
		text-align: var(--scrollViewTextAlign);
		position: relative;
		z-index: 2; 
	}

	<!--- Content Blocks --->
	<!--- Font properties for the content blocks. --->
	.<cfoutput>#parallaxName#</cfoutput>-content-block1 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-content-block2 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-content-block3 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-content-block4 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-content-block5 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-content-block6 .<cfoutput>#parallaxName#</cfoutput>--wrapper {
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: var(--sceneFontSize) !important;
		<!--- Hard back text shadow --->
		text-shadow: 3px 3px 0 #000000;
		/* <cfoutput>#parallaxName#</cfoutput>-second text shadow with black 18 pixel glow */
		text-shadow: 3px 3px 18px #000000;
	}

	<!--- 1 off. This particular content block is before the parallax scene and is a little bit different --->
	.<cfoutput>#parallaxName#</cfoutput>-content-block1 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		height: 450px;/* parallax 1 off */
	}

	/* .<cfoutput>#parallaxName#</cfoutput>-content-block1 .<cfoutput>#parallaxName#</cfoutput>-wrapper does not exist */
	.<cfoutput>#parallaxName#</cfoutput>-content-block1 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding-top: 150px;
		padding-right: 0px;
		padding-bottom: 50px;
		padding-left: 0px;
		text-align: var(--scrollViewTextAlign); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block2 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		<!--- height: 600px; parallax 1 off --->
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block2 .<cfoutput>#parallaxName#</cfoutput>-wrapper { /* Web Development */
		padding: 150px 0;
		text-align: var(--scrollViewTextAlign); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block3 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		<!--- height: 600px; parallax 1 off --->
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block3 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding: 150px 0;
		text-align: var(--scrollViewTextAlign);
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block4 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		<!--- height: 100%; parallax 1 off --->
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block4 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding: 150px 0;
		text-align: var(--scrollViewTextAlign); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block5 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		<!--- height: 100%; parallax 1 off --->
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block5 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding: 150px 0;
		text-align: var(--scrollViewTextAlign); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block6 {
		<!--- Force the width to the viewport. --->
		width: 100%;
		<!--- Text color --->
		color: rgba(255, 255, 255, 0.9); 
		<!--- height: 100%; parallax 1 off --->
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block6 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		padding-top: 20px;
		padding-right: 0px;
		padding-bottom: 75px;
		padding-left: 0px;
		text-align: var(--scrollViewTextAlign);
	}

	<!--- Animations --->
	.<cfoutput>#parallaxName#</cfoutput>-slideInUp.<cfoutput>#parallaxName#</cfoutput>-slideInUp1 {
		-webkit-transition-delay: 0.2s;
			  transition-delay: 0.2s; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slideInUp.<cfoutput>#parallaxName#</cfoutput>-slideInUp2 {
		-webkit-transition-delay: 0.4s;
			  transition-delay: 0.4s; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slideInUp.<cfoutput>#parallaxName#</cfoutput>-slideInUp3 {
		-webkit-transition-delay: 0.6s;
			  transition-delay: 0.6s; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slideInUp.<cfoutput>#parallaxName#</cfoutput>-slideInUp4 {
		-webkit-transition-delay: 0.8s;
			  transition-delay: 0.8s; 
	}

	<!--- Header --->
	.header-container {
		overflow: hidden;
		position: relative; 
	}

	.header-container .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		position: absolute;
		top: 65%; /* The text needs to be in the blue part of the hotspring. */
		left: 50%;
		-webkit-transform: translate(-50%, -120%);
		  -ms-transform: translate(-50%, -120%);
			  transform: translate(-50%, -120%);
		margin: 0;
		padding: 0; 
	}

	.header-container:before {
		font-size: 1em; 
	}

	.bcg {
		opacity: 1; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide {
		overflow: hidden;
		overflow-x: hidden; 
	}

	<!--- Prior to the parallax, this setting used to be .slide section { --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 section {
		/* This setting controls the width of slide 03 (and slide 1 if the #<cfoutput>#parallaxName#</cfoutput>-slide03 is omitted) */
		max-width: 66%; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- element positioning --->
		position: absolute;
		-webkit-transform: translate(-50%, -50%);
		-ms-transform: translate(-50%, -50%);
		  transform: translate(-50%, -50%);
		width: 100%;
		margin: 0; 
		<!--- Font properties for the slides. --->
		vertical-align: middle
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: var(--sceneFontSize) !important; 
		text-shadow: 
			10px 5px 25px #000,
			10px 10px 50px #000,
			20px 20px 100px #000
	}

	<!--- Common properties of slides. The properties may be overrridden later --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide01 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide02 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 .<cfoutput>#parallaxName#</cfoutput>-wrapper, .<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide04 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Transformations --->
		-webkit-transform: translate(0);
			-ms-transform: translate(0);
				transform: translate(0);
	}

	<!--- Independent properties of the slides. The top bottom, and left will adjust the position of the text on the desktop. --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide01 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		top: auto;
		bottom: var(--slideBottomPercent); /*30%*/
		left: 5%;
		text-align: left;
		padding: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide02 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Note: in the blog, we must use the following code to align the text elements as there are multiple blocks. Using text-align middle will not work here. --->
		position: absolute;
 		top: 50%;
 		display: table-cell;
		vertical-align: middle;
		left: 5%;
		text-align: left;
		padding: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Note: in the blog, we must use the following code to align the text elements as there are multiple blocks. Using text-align middle will not work here. --->
		position: absolute;
 		top: 50%;
 		display: table-cell;
		vertical-align: middle;
		left: 5%;
		text-align: left;
		padding: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide04 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Note: in the blog, we must use the following code to align the text elements as there are multiple blocks. Using text-align middle will not work here. --->
		position: absolute;
 		top: 50%;
 		display: table-cell;
		vertical-align: middle;
		left: 5%;
		text-align: left;
		padding: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide05 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Note: in the blog, we must use the following code to align the text elements as there are multiple blocks. Using text-align middle will not work here. --->
		position: absolute;
 		top: 50%;
 		display: table-cell;
		vertical-align: middle;
		left: 55%; /* to do: this is a bug. This should be left: 5, something is off here. */
		text-align: left;
		padding: 0;  
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide06 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		<!--- Note: in the blog, we must use the following code to align the text elements as there are multiple blocks. Using text-align middle will not work here. --->
		position: absolute;
 		top: 50%;
 		display: table-cell;
		vertical-align: middle;
		left: 55%; /* to do: this is a bug. This should be left: 5, something is off here. */
		text-align: left;
		padding: 0; 
	}

	<!--- Text color in the slides --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide01 {
		color: #ffffff; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide02 {
		color: #ffffff; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 {
		color: #ffffff; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide04 {
		color: #ffffff; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide05 {
		color: #ffffff; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide06 {
		color: #ffffff; 
	}

	<!--- Sections (limits the width of the paragraphs) --->
	<!--- Parallax 1 off --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide01 section {
		margin: 0; 
		width: 100%;
		object-fit: cover;
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide02 section {
		margin: 0; 
		max-width: var(--sceneContainerWidth); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 section {
		margin: 0;
		max-width: var(--sceneContainerWidth); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide04 section {
		margin: 0;
		max-width: var(--sceneContainerWidth); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide05 section {
		margin: 0;
		max-width: var(--sceneContainerWidth); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide06 section {
		margin: 0;
		max-width: var(--sceneContainerWidth); 
	}

	<!--- Opacity --->
	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide01 .bcg {
		opacity: 1; 
	}


	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide02 .bcg {
		opacity: 1; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide03 .bcg {
		opacity: 1; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide04 .bcg {
		opacity: 1; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide05 .bcg {
		opacity: 1; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-slide#<cfoutput>#parallaxName#</cfoutput>-slide06 .bcg {
		opacity: 1; 
	}

	nav {
		display: block; 
	}

	<!--- Simple animation up --->
	.<cfoutput>#parallaxName#</cfoutput>-slideInUp {
		visibility: hidden;
		opacity: 1;
		-webkit-transition: all 0.7s ease-out;
			  transition: all 0.7s ease-out;
		-webkit-transform: translate3d(0, 50px, 0);
		transform: translate3d(0, 50px, 0); 
	}

	/* Not used.
	.<cfoutput>#parallaxName#</cfoutput>-slideInUp .sceneHeaderFont {
		We need to make the header font a bit smaller on mobile devices.
		font-size: var(--sceneHeaderFontSize);
	}
	*/

	.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-slideInUp {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
		<!--- This is different here. We need to reduce the width to 85% --->
		width: 85%;
	}

	<!--- Web only content blocks --->
	 .<cfoutput>#parallaxName#</cfoutput>-content-block1 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: hidden;
		opacity: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block1.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block2 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: hidden;
		opacity: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block2.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block3 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: hidden;
		opacity: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block3.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block4 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: hidden;
		opacity: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block4.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block5 .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: hidden;
		opacity: 0; 
	}

	.<cfoutput>#parallaxName#</cfoutput>-content-block5.<cfoutput>#parallaxName#</cfoutput>-is-active .<cfoutput>#parallaxName#</cfoutput>-wrapper {
		visibility: visible;
		opacity: 1;
		-webkit-transform: translate3d(0, 0, 0);
		transform: translate3d(0, 0, 0); 
	}

	<!--- Used on the footer --->
	.<cfoutput>#parallaxName#</cfoutput>-wrapper {
		width: 100%;/* Used to be 80% */
		margin: 0 10%; 
		font-family: "Eras Demi";/*'Kaufmann Script Bold'; */
		font-size: var(--sceneFontSize) !important;
	}

	<!--- ========================================================================== Helper classes ========================================================================== --->
	.hidden {
		display: none !important;
		visibility: hidden; 
	}

	.visuallyhidden {
		border: 0;
		clip: rect(0 0 0 0);
		height: 1px;
		margin: -1px;
		overflow: hidden;
		padding: 0;
		position: absolute;
		width: 1px; 
	}

	.visuallyhidden.focusable:active, .visuallyhidden.focusable:focus {
		clip: auto;
		height: auto;
		margin: 0;
		overflow: visible;
		position: static;
		width: auto; 
	}

	.invisible {
		visibility: hidden; 
	}

	.clearfix:before, .clearfix:after {
		content: " ";
		display: table; 
	}

	.clearfix:after {
		clear: both; 
	}

	.clearfix {
		*zoom: 1; 
	}
		
	<!--- Rules for the delicate arch parallax. --->
	#<cfoutput>#parallaxName#</cfoutput>-mainContainer.section {
		height: 100vh;
		width: 100%;
		overflow-x: hidden
	}

	#<cfoutput>#parallaxName#</cfoutput>-mainContainer.<cfoutput>#parallaxName#</cfoutput>Container {
		width: 100%;
		height: 100vh;
	}

	#<cfoutput>#parallaxName#</cfoutput>-mainContainer.<cfoutput>#parallaxName#</cfoutput>-images {
		width: 100vw;
		height: 100vh;
		position: relative;
		z-index: -1;
		top: -10%;
	}

	#<cfoutput>#parallaxName#</cfoutput>-mainContainer.image-wrapper {
		position: absolute;
		width: 100%;
		height: 100%;
		bottom: 0;
	}

	#<cfoutput>#parallaxName#</cfoutput>-mainContainer.image-wrapper img {
	  display: block;
	  max-width: 100%;
	  height: 100vh;
	  object-fit: cover; 
	  object-position: 50% 50%; /* default value: image is centered*/
	}
	
	<!--- The parallax divider is just below the last image in the parallax sequence. This color will show once the animation has pulled towrards the top of the page. It is important to match the color --->
	.<cfoutput>#parallaxName#</cfoutput>-parallaxDivider {
		width: 120%;
		margin-left: -10%;
		margin-right: -10%;
		height: 1000px;
		background-color: #<cfoutput>#parallaxDividerColor#</cfoutput>;;
		position: absolute;
		bottom: -1000px;
		filter: blur(40px);
		z-index: 999;
	}

	<!--- States for the header menu --->
	ul.k-hover { 
	  background-color: transparent !important;
	  border: 0;
	  border-right: none;
	} 

	ul.k-link { 
	  background-color: transparent !important;
	  border: 0;
	} 
		
	<!--- Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. --->
	.leftTooltipStyle {
		background: #046FA1 !important;   /* Blue matching the left part of the logo */
		width: var(--toolTipWidth);
		height: var(--toolTipHeight);
		font-size: var(--toolTipFontSize);
		border-radius: 10px;
		<!--- Subtle drop shadow on the main layer --->
		box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	}

	<!--- Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. --->
	.rightTooltipStyle {
		background: #698A50 !important; /* Green matching the right part of the logo */
		width: var(--toolTipWidth);
		height: var(--toolTipHeight);
		font-size: var(--toolTipFontSize);
		border-radius: 10px;
		<!--- Subtle drop shadow on the main layer --->
		box-shadow: 0 8px 16px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	}

	.tooltipTemplateWrapper h3 {
		font-size: 1em;
		font-weight: bold;
		padding: 0px 10px 5px;
		border-bottom: 1px solid #e2e2e2;
		text-align: left;
	}

	.tooltipTemplateWrapper p {
		font-size: 1em;
		padding-top: 0px;
		padding-right: 10px;
		padding-bottom: 10px;
		padding-left: 10px;
		text-align: left;
	}

	<!--- Kendo class for the grizzly window --->
	#grizzlyWindow_wnd_title {
		font-size: 18px;
	}

	.blogFeaturesWrapper {
	  left: 0px !important;
	  text-align: left !important;
	}

	.blogFeatures ul {
		padding: 0px;
		list-style-type: none;

	}	
</style>
	  
<!--- Include the css. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '<cfoutput>#application.baseUrl#</cfoutput>/includes/postContent/parallax/parallaxCss.css') );
</script>

<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		
	// Reload if the session is not defined.
	isiPad = navigator.userAgent.match(/iPad/i) != null;
		
	// Resize when a mobile device's orientation has changed.
	// Listen for orientation changes    
	if (!isMobile){
		window.addEventListener("orientationchange", function() {
			// Reload
			this.location.reload(false); /* false to get page from cache */
		}, false);
	}
	
	// Set the content width depending upon the screen size.
	function setCssVarsForParallax() {
			
		document.documentElement.style.setProperty("--sceneFontSize", "18pt");
		document.documentElement.style.setProperty("--sceneHeaderFontSize", "1.5em");
		document.documentElement.style.setProperty("--splashTitleFontSize", getSplashTitleFontSize());
		document.documentElement.style.setProperty("--sceneContainerWidth", "100%");//Used to be set at 80%
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
	
<body onload="setCssVarsForParallax();" onresize="setCssVarsForParallax()">
	
	<!-- Hidden form to indicate the scene. We will use this to prevent duplicate notifications when the user scrolls quickly down the page when we use notification timings. -->
	<input type="hidden" id="<cfoutput>#parallaxName#</cfoutput>-currentScene" name="<cfoutput>#parallaxName#</cfoutput>-currentScene" value="intro">	
	
	<div id="<cfoutput>#parallaxName#</cfoutput>-mainContainer" class="<cfoutput>#parallaxName#</cfoutput>-main-container">

		<article id="<cfoutput>#parallaxName#</cfoutput>-cb01" class="<cfoutput>#parallaxName#</cfoutput>-content-block1 <cfoutput>#contentBlock1Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#cb01Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb01Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb01Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide01" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<!-- We need an empty header on this particular slide for two reasons. 1) I don't want text to be shown (I only want the arch), and 2) as the main.js uses each header to determine the index dynamically, we need to have something here, even if it is empty. -->
			<div class="<cfoutput>#parallaxName#</cfoutput>--wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>--slideInUp">
				</header>
				<section>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>--wrapper -->
			
			<!-- We will show the arch here unlike the rest of normal scenes which has its text content above and a background setting in the css. -->
			<div class="<cfoutput>#parallaxName#</cfoutput>Container">
				<div class="<cfoutput>#parallaxName#</cfoutput>-images">
					<!-- The entire image. The fastest moving layer. -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-first">
						<img src="<cfoutput>#parallaxImage1#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 1" />
					</div>
					<!--The horizon is cropped out. -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-second">
						<img src="<cfoutput>#parallaxImage2#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 2" />
					</div>
					<!-- More of the horizon is cropped out... -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-third">
						<img src="<cfoutput>#parallaxImage3#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 3" />
					</div>
					<!-- ... -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-fourth">
						<img src="<cfoutput>#parallaxImage4#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 4" />
					</div>
					<!-- ... -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-fifth">
						<img src="<cfoutput>#parallaxImage5#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 5" />
					</div>
					<!-- And only the focal point is left. -->
					<div class="image-wrapper" id="<cfoutput>#parallaxName#</cfoutput>-sixth">
						<img src="<cfoutput>#parallaxImage6#</cfoutput>" alt="<cfoutput>#parallaxName#</cfoutput> Parallax Image 6" />
						<div class="<cfoutput>#parallaxName#</cfoutput>-parallaxDivider"></div>
					</div>
				</div>
			</div>
		</article>
		
		<article id="<cfoutput>#parallaxName#</cfoutput>-cb02" class="<cfoutput>#parallaxName#</cfoutput>-content-block1 <cfoutput>#contentBlock2Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>--slideInUp">
					<h2><cfoutput>#cb02Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb02Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#cb02Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide02" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#slide02Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#slide02Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#slide02Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>
		
		
		<article id="<cfoutput>#parallaxName#</cfoutput>-cb03" class="<cfoutput>#parallaxName#</cfoutput>-content-block2 <cfoutput>#contentBlock3Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#cb03Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb03Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#cb03Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide03" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#slide03Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#slide03Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#slide03Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		
		<article id="<cfoutput>#parallaxName#</cfoutput>-cb04" class="<cfoutput>#parallaxName#</cfoutput>-content-block3 <cfoutput>#contentBlock4Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#cb04Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb04Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#cb04Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide04" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#slide04Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#slide04Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#slide04Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		
		<article id="<cfoutput>#parallaxName#</cfoutput>-cb05" class="<cfoutput>#parallaxName#</cfoutput>-content-block4 <cfoutput>#contentBlock5Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#cb05Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb05Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#cb05Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide05" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#slide05Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#slide05Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#slide05Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		
		<article id="<cfoutput>#parallaxName#</cfoutput>-cb06" class="<cfoutput>#parallaxName#</cfoutput>-content-block5 <cfoutput>#contentBlock6Gradient#</cfoutput>">
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#cb06Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#cb06Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#cb06Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
		</article>

		<article id="<cfoutput>#parallaxName#</cfoutput>-slide06" class="<cfoutput>#parallaxName#</cfoutput>-slide <cfoutput>#parallaxName#</cfoutput>-fs">
			<div class="bcg"></div>
			<div class="<cfoutput>#parallaxName#</cfoutput>-wrapper">
				<header class="<cfoutput>#parallaxName#</cfoutput>-slideInUp">
					<h2><cfoutput>#slide06Header#</cfoutput></h2>
				</header>
				<section>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp2"><cfoutput>#slide06Text1#</cfoutput></p>
					<p class="<cfoutput>#parallaxName#</cfoutput>-slideInUp <cfoutput>#parallaxName#</cfoutput>-slideInUp3"><cfoutput>#slide06Text2#</cfoutput></p>
				</section>
			</div> <!-- .<cfoutput>#parallaxName#</cfoutput>-wrapper -->
			
		</article>

	</div>

	<div id="<cfoutput>#parallaxName#</cfoutput>-lowerDividerImage" style="background-image: url(/blog/images/borders/grey.png); height: 6px;">&nbsp;</div>

	<div class="footer-container">
		<footer>
			<br/><br/>
			<div class="blogFeaturesWrapper">
			Galaxie Blog Features:
				
			<ul class="blogFeatures">
			  	<li>Works with the latest version of ColdFusion (CF2023 07.330663)</li>
				<li>Beautiful, fast, modern interface</li>
				<li>Responsive website with a stunning mobile interface</li>
				<li>Layout is adjusted for eight different device sizes</li>
				<li>Works with all modern devices</li>
				
				<li>Galaxie Blog lazy loads resources and media to improve performance</li>
				<li>To minimize network bandwidth, Galaxie Blog will only render the image once it comes into the user's viewport</li>
				<li>To improve performance, Galaxie Blog automatically generates thumbnail previews for all hero media on the Blog landing page</li>

				<li>Your most popular posts are displayed in a sroll widget at the top of the landing page</li> 
				<li>Posts are shown in an attractive three-by-five grid card interface on the landing page</li>
				<li>Breadcrumbs show the category hierarchy on every post, and users can navigate back to the main blog site.</li>
				<li>JSONs-LD Breadcrumb Schema is generated for each page</li>
				
				<li>Dozens of pre-installed, professionally designed themes</li>
				<li>Every post can be assigned its theme</li>
				<li>Themes are customized using web interfaces</li>
				
				<li>Multi-User Blogging Platform with roles and custom capabilities</li>
				<li>There are six built-in roles- administrator, author, designer, editor and guest</li>	
				<li>You can have users fill multiple roles and have multiple blog authors</li>	
				<li>Capabilities can be customized for each user</li>
		
				<li>Add images, image galleries, hardware accelerated carousels, static Bing Maps, Bing Map routes and more.</li>
				<li>Add local hosted videos, or integrate videos from YouTube or Vimeo</li>	
				<li>Add engaging animations using theGreenSock Animation Platform</li>
				<li>Post media are optimized for social media sharing</li>
				<li>Automatically adds open graph Facebook and Twitter meta tags</li>
				<li>Supports inline CSS, JavaScript, and HTML within blog posts</li>
				<li>Built-in support for code formatting for dozens of different languages.</li>
				<li>Posts support using ColdFusion includes (cfinclude)</li>
				<li>Preview your entry prior to posting</li>
				
				<li>HTML5 media player</li>
				<li>Add responsive video</li>
				<li>Podcasting</li>

				<li>Optional Disqus Integration - integrate Disqus with just two settings.</li>

				<li>Emails are automatically sent out to your subscribers when a post is made.</li>
				<li>Other emails are generated automatically by event, for example, when an administrator has added a new user.</li>
				<li>All emails are branded to use your chosen logos and match your chosen theme</li>
				
				<li>Users may subscribe to the blog or to a given post</li>
				<li>Built-in captcha</li>
				<li>Comment moderation</li>
				<li>Web-based installation</li>

				<li>Hiarchacal Categories</li>	
				<li>Tags</li>
				<li>Related entries</li>

				<li>SEO optimization</li>
				<li>JSON-LD is generated for each post to enhance SEO.</li>
				<li>Automatically generates Google site maps</li>
				<li>Search functionality</li>

				<li>Blog Update notifications</li>
				<li>Site Statistics</li>
				<li>Visitor Logs</li>
				<li>RSS feeds</li>
				<li>CFBlogs.org integration</li>
			</ul>
			</div>
			<p>Design by Gregory Alexander | Copyright &copy; 2019 Gregory Alexander</p>
		</footer>
		<div align="center">
			<img src="/blog/images/logo/gregoryAlexanderLogo125_190.png" alt="Gregory Alexander Web Design"/>
		</div>	
	</div>

	<!-- Custom sroll magic js (and custom kendo notifications from my extended notification UI library) -->
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	$( document ).ready(function() {
		(function ($) {

			// Init ScrollMagic
			var <cfoutput>#parallaxName#</cfoutput>Controller = new ScrollMagic.Controller();
			// Get all slides
			var slides = ["#<cfoutput>#parallaxName#</cfoutput>-slide01", "#<cfoutput>#parallaxName#</cfoutput>-slide02", "#<cfoutput>#parallaxName#</cfoutput>-slide03", "#<cfoutput>#parallaxName#</cfoutput>-slide04", "#<cfoutput>#parallaxName#</cfoutput>-slide05", "#<cfoutput>#parallaxName#</cfoutput>-slide06"];
			// Get all headers in slides that trigger animation
			var headers = ["#<cfoutput>#parallaxName#</cfoutput>-slide01 header", "#<cfoutput>#parallaxName#</cfoutput>-slide02 header", "#<cfoutput>#parallaxName#</cfoutput>-slide03 header", "#<cfoutput>#parallaxName#</cfoutput>-slide04 header", "#<cfoutput>#parallaxName#</cfoutput>-slide05 header", "#<cfoutput>#parallaxName#</cfoutput>-slide06 header"];
			// Get all break up sections
			var breakSections = ["#<cfoutput>#parallaxName#</cfoutput>-cb01", "#<cfoutput>#parallaxName#</cfoutput>-cb02", "#<cfoutput>#parallaxName#</cfoutput>-cb03", "#<cfoutput>#parallaxName#</cfoutput>-cb04", "#<cfoutput>#parallaxName#</cfoutput>-cb05", "#<cfoutput>#parallaxName#</cfoutput>-cb06"];

			// Headers. Create scenes for each of the headers.
			headers.forEach(function (header, index) {
				// number for highlighting scenes
				var num = index+1;
				// make scene
				var headerScene = new ScrollMagic.Scene({
					triggerElement: header, // trigger CSS animation when header is in the middle of the viewport 
					offset: -95 // offset triggers the animation 95 earlier then middle of the viewport, adjust to your liking
				})
				.setClassToggle('#<cfoutput>#parallaxName#</cfoutput>-slide0'+num, '<cfoutput>#parallaxName#</cfoutput>-is-active') // set class to active slide
				.on("leave", function (event) {
					// Don't handle events until the page is loaded.
				})
				//.addIndicators() // add indicators; used for debugging
				.addTo(<cfoutput>#parallaxName#</cfoutput>Controller);
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
				.setClassToggle('#'+breakID, '<cfoutput>#parallaxName#</cfoutput>-is-active') // set class to active slide
				//.addIndicators() // add indicators; used for debugging
				.addTo(<cfoutput>#parallaxName#</cfoutput>Controller);
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
				.addTo(<cfoutput>#parallaxName#</cfoutput>Controller);
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
				.addTo(<cfoutput>#parallaxName#</cfoutput>Controller);
			});


			// Change behaviour of controller to animate scroll instead of jump
			<cfoutput>#parallaxName#</cfoutput>Controller.scrollTo(function (newpos) {
				setTimeout(
					TweenMax.to(window, 1, {scrollTo: {y: newpos, autoKill: false}, ease:Power1.easeInOut})
				,100);
			});

			//  Bind scroll to anchor links
			$(document).on("click", "a[href^='#']", function (e) {
				var id = $(this).attr("href");
				if ($(id).length > 0) {
					// iPhones are having problems scrolling using scroll animation. I will only use scroll animations on the desktop.
					if (!navigator.userAgent.match(/(iPod|iPhone|iPad|Android)/)) { 
						e.preventDefault();
						// trigger scroll
						setTimeout(
							<cfoutput>#parallaxName#</cfoutput>Controller.scrollTo(id)
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
			let <cfoutput>#parallaxName#</cfoutput>Controller = new ScrollMagic.Controller();
			// Create the timeline.
			let <cfoutput>#parallaxName#</cfoutput>Timeline = new TimelineMax();
			// Set the increment. The parallax effect is more pronounced on mobile due to the aspect ratio of the screen. We want to double the effect on the desktop to match the mobile site.
			if (isMobile){
				yIncrement = 2;
			} else {
				yIncrement = 4;
			}

			<cfoutput>#parallaxName#</cfoutput>Timeline
			/* Descending order */
			.to('#<cfoutput>#parallaxName#</cfoutput>-sixth', 6, {
				y: -700 * yIncrement
			})
			.to('#<cfoutput>#parallaxName#</cfoutput>-fifth', 6, {
				y: -500 * yIncrement
			}, '-=6')
			.to('#<cfoutput>#parallaxName#</cfoutput>-fourth', 6, {
				y: -400 * yIncrement
			}, '-=6')
			.to('#<cfoutput>#parallaxName#</cfoutput>-third', 6, {
				y: -300 * yIncrement
			}, '-=6')
			.to('#<cfoutput>#parallaxName#</cfoutput>-second', 6, {
				y: -200 * yIncrement
			}, '-=6')
			.to('#<cfoutput>#parallaxName#</cfoutput>-first', 6, {
				y: -100 * yIncrement
			}, '-=6')
			/* Pull the any elements within the parallax block and attach it to the next layer (<cfoutput>#parallaxName#</cfoutput>-cb02) */
			.to('#<cfoutput>#parallaxName#</cfoutput>-cb02', 6, {
				top: '0%'
			}, '-=6')
			/* And pull up the next sections underneath the parallax effect. */
			.to('#<cfoutput>#parallaxName#</cfoutput>-cb02 .<cfoutput>#parallaxName#</cfoutput>-parallaxDivider, #<cfoutput>#parallaxName#</cfoutput>-cb02, #<cfoutput>#parallaxName#</cfoutput>-slide02, #<cfoutput>#parallaxName#</cfoutput>-cb03, #<cfoutput>#parallaxName#</cfoutput>-slide03, #<cfoutput>#parallaxName#</cfoutput>-cb04, #<cfoutput>#parallaxName#</cfoutput>-slide04, #<cfoutput>#parallaxName#</cfoutput>-cb05, #<cfoutput>#parallaxName#</cfoutput>-slide05, #<cfoutput>#parallaxName#</cfoutput>-cb06, #<cfoutput>#parallaxName#</cfoutput>-slide06, #<cfoutput>#parallaxName#</cfoutput>-lowerDividerImage', 6, {
				y: -600,
			}, '-=6')

			let <cfoutput>#parallaxName#</cfoutput>Scene = new ScrollMagic.Scene({
				triggerElement: '#<cfoutput>#parallaxName#</cfoutput>-mainContainer section',
				duration: '400%', /* In pixels. Note: this is typically set for 200 for parallax, however, that setting will extend the scene and make the content block really long. */
				triggerHook: 0
			})
			.setTween(<cfoutput>#parallaxName#</cfoutput>Timeline)
			.setPin('#<cfoutput>#parallaxName#</cfoutput>-mainContainer section')
			//.addIndicators() // add indicators; used for debugging
			.addTo(<cfoutput>#parallaxName#</cfoutput>Controller);
		//})
	</script>
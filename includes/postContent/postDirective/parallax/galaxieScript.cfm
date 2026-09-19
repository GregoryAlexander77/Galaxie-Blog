<cfset scriptTypeString = "deferjs"><!---deferjs text/javascript--->
<cfset parallaxName = "galaxie">
<cfset webpImageSupported = true>
	
<!--- Notes: this template can be reused. However, we need to keep track if the template was loaded prior to the current scene in order not to duplicate the logic. We will be setting a gsapTemplateLoaded var which will be set to true at the end of the page. --->
<cfparam name="gsapTemplateLoaded" type="boolean" default="false">

<!--- Do webp? --->
<cfif webpImageSupported>
	<!--- Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset imageExtension = "webp">
<cfelse>
	<cfset imageExtension = "png">
</cfif>
<!--- We are using smaller image sizes for mobile. --->
<cfif session.isMobile>
	<cfset imageWidth = "640">
<cfelse>
	<cfset imageWidth = "980">
</cfif>
	
<!--- Set the text and parallax images --->
<cfset cb01Header = "Galaxie Blog is a Next Generation Blog Platform">
<cfset cb01Text1 = "Galaxie Blog is the most beautiful and functional open sourced ColdFusion blog in the world.">
<cfset cb01Text2 = "">
<cfset cb02Header = "Galaxie Blog is fast....">
<cfset cb02Text1 = "Galaxie Blog consistently performs above 80% in Google lighthouse scores...">
<cfset cb02Text2 = "For comparison, the industry average performance score of the top ecommerce sites is is around 22%">
<cfset slide02Header = "Galaxie Blog is Accessible...">
<cfset slide02Text1 = "Galaxie Blog has a perfect 100% 'Accessibility' Google Score">
<cfset slide02Text2 = "The industry average sites is around 60%.">
<cfset cb03Header = "Galaxie Blog has a perfect 100% 'Best Practices' Google Score">
<cfset cb03Text1 = "Galaxie Blog uses all of the 'Best Practices' suggested by Google.">
<cfset cb03Text2 = "The industry average score is about 61%">
<cfset slide03Header = "Galaxie Blog has a perfect 'Search Engine Opimization (SEO)' score.">
<cfset slide03Text1 = "Having a perfect SEO ensures that search engines will be able to collect and promote your content.">
<cfset slide03Text2 = "">
<cfset cb04Header = "Galaxie Blog allows you to enforce SSL....">
<cfset cb04Text1 = "Blog owners can specify whether to enforce SSL. If SSL is enforced, all port 80 traffic will be a automatically redirected to an encryted port.">
<cfset cb04Text2 = "">
<cfset slide04Header = "Galaxie Blog delivers next generation media content...">
<cfset slide04Text1 = "Galaxy Blog now delivers webp images if both the client and the server support the new webp format.">
<cfset slide04Text2 = "If webp is not supported, Galaxy Blog will fallback and deliver images using tradional web formats.">
<cfset cb05Header = "Improved Entry Image Support">
<cfset cb05Text1 = "Administrators can easilly add images to their entries by clicking on a button and selecting an image. Galaxie Blog will take care of the rest.">
<cfset cb05Text2 = "To improve performance, Galaxie Blog will only render the image once it comes into the user's viewport.</p>">
<cfset slide05Header = "Improved Social Media Sharing">
<cfset slide05Text1 = "Galaxie Blog now prominently displays social media icons to share your social media at the bottom of each individual blog entry.">
<cfset slide05Text2 = "">
<cfset cb06Header = "You can use dynamic includes within an entry using xml.">
<cfset cb06Text1 = "This very GSAP scene that you're looking at now is acheived using a dynamic cfinclude.">
<cfset cb06Text2 = "">
<cfset slide06Header = "Goals for the next version...">
<cfset slide06Text1 = "Overhaul the original database and add 'Disqus' integration.">
<cfset slide06Text2 = "Galaxie Blog is still using the original BlogCfc database and it must be updated. If feasable, I will add Disqus comment integration.">
	
<!--- Content block gradients. --->
<cfset contentBlock1Gradient = "nightSkyGradient">
<cfset contentBlock2Gradient = "blueGradient">
<cfset contentBlock3Gradient = "nightSkyGradient">
<cfset contentBlock4Gradient = "blueGradient">
<cfset contentBlock5Gradient = "nightSkyGradient">
<cfset contentBlock6Gradient = "blueGradient">
	
<!--- Parallax images --->
<cfset parallaxImage1 = "/blog/images/parallax/galaxie/layer6.png">
<cfset parallaxImage2 = "/blog/images/parallax/galaxie/layer5.png">
<cfset parallaxImage3 = "/blog/images/parallax/galaxie/layer4.png">
<cfset parallaxImage4 = "/blog/images/parallax/galaxie/layer3.png">
<cfset parallaxImage5 = "/blog/images/parallax/galaxie/layer2a.png">
<cfset parallaxImage6 = "/blog/images/parallax/galaxie/layer1a.png">
<!--- Set the parallax divider at the end of the scene. --->
<cfset parallaxDividerColor = "180109">
	
<!--- Background images --->
<cfset slide02BgImage = "/blog/images/parallax/galaxie/background/spiralBlueGalaxy" & imageWidth & "." & imageExtension>
<cfset slide03BgImage = "/blog/images/parallax/galaxie/background/blueFusion" & imageWidth & "." & imageExtension>
<cfset slide04BgImage = "/blog/images/parallax/galaxie/background/blueGears" & imageWidth & "." & imageExtension>
<cfset slide05BgImage = "/blog/images/parallax/galaxie/background/blueSpiral" & imageWidth & "." & imageExtension>
<cfset slide06BgImage = "/blog/images/parallax/galaxie/background/abstractWaves" & imageWidth & "." & imageExtension>
	
<!--- Notes: this template can be reused. However, we need to keep track if the template was loaded prior to the current scene in order not to duplicate the logic. We will be setting a gsapTemplateLoaded var which will be set to true at the end of the page. --->
<cfparam name="gsapTemplateLoaded" type="boolean" default="false">

<!--- Do webp? --->
<cfif webpImageSupported>
	<!---Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset imageExtension = "webp">
<cfelse>
	<cfset imageExtension = "png">
</cfif>
<!--- We are using smaller image sizes for mobile. --->
<cfif session.isMobile>
	<cfset imageWidth = "640">
<cfelse>
	<cfset imageWidth = "980">
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
		width: 80%;
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
		background-color: #<cfoutput>#parallaxDividerColor#</cfoutput>;
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
		
		<a id="<cfoutput>#parallaxName#</cfoutput>-slide6"></a>

	</div>

	<div id="<cfoutput>#parallaxName#</cfoutput>-lowerDividerImage" style="background-image: url(/blog/images/borders/grey.png); height: 6px;">&nbsp;</div>

	<div class="footer-container">
		<footer>
			<br/><br/>
			<div class="blogFeaturesWrapper">
			Google Lighthouse Notes:
			<ul class="blogFeatures">
			  <li>Performance results can vary considerably.</li>
			  <li>Testing was performed using the <b>Abstract Blue</b> Theme and testing was performed on individual entries with large entry images attached.</li>
			  <li>Performance scores are quite a bit lower when using an animated Greensock scene with parallax.</li>
			  <li>Attained a perfect Best Practices score with the commercial Kendo license. The open source Kendo Best Practices score is at 86% due to the Kendo embedded jQuery library. According to Telerik, this should be fixed in the near future.</li>
			</ul>
			</div>
			<p>Copyright &copy; 2019 Gregory Alexander</p>
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
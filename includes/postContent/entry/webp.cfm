<p><b>The next generation webp format is one of the most important image formats to have come along in the last several years.</b></p>
	
<p>My first impression of webp images was 'meh'. I read articles on the next generation webp image format. The articles claim that webp images are about 26% smaller than their png equivalents. What I read was impressive, but not just enough to delve into learning how to use them.</p>
	
<p>I only started playing around with webp to chase a better Google lighthouse score. Google knocked my 'Best Practices' score down a couple of notches, and I finally decided to investigate using them. I'm glad that I did! I did not find a 26% improvement with my own images, but a <b>95%</b> improvement in size than the identical .png images that I had created. <b>Want proof?</b> I'll demonstrate my own results...</p>
	
<p>Please take a look at my Greensock animation introducing the next version of Galaxie Blog at <a href="https://gregoryalexander.com/blog/index.cfm/2019/9/16/Galaxie-Blog-135-Animated-Blurb" aria-label="Introduding Galaxie Blog Version 1.35">https://gregoryalexander.com/blog/index.cfm/2019/9/16/Galaxie-Blog-135-Animated-Blurb</a>. If you're using a modern browser, you should notice that this intense graphical scene renders rather quickly. On a vain note- I also hope that you find the scollmagic scene to be pretty...</p>
	
<p>The scrollmagic scene that you are looking at should deliver images in the webp format if your browser supports them. If the browser does not support webp, png's will be rendered instead. I'll go over the code later on, but right now I will compare the image sizes to show you the improvements. I'll provide the size of each actual image in the grid below so you can take a look yourself.</p>
	
<p>I created the original source images using Adobe Illustrator, and exported them to png's using the 'save as legacy web' option. To create the web images, I took the png images that I had created and used Irfanview to export the png as a webp. Take a look at the size reduction in the table below.</p.>

<attachScript type="deferjs">
var scenes = [{
    sceneId: 1,
    description: "Blue Spiral Galaxy",
    pngImage: "spiralBlueGalaxy980.png",
    pngImageSize: "2,206",
    webpImage: "spiralBlueGalaxy980.webp",
    webpImageSize: "65 KB",
    notes: "65 KB is around the size of a tiny logo"
}, {
    sceneId: 2,
    description: "Blue Fusion",
    pngImage: "blueFusion980.png",
    pngImageSize: "1,218",
    webpImage: "blueFusion980.webp",
    webpImageSize: "26 KB",
    notes: "yes- you're reading that right, twenty six KB!"
}, {
    sceneId: 3,
    description: "Blue Gears",
    pngImage: "blueGears980.png",
    pngImageSize: "1,634",
    webpImage: "blueGears980.webp",
    webpImageSize: "54 KB",
    notes: "This thing is begging to be animated."
}, {
    sceneId: 4,
    description: "Abstract Spiral",
    pngImage: "blueSpiral80.png",
    pngImageSize: "2,626",
    webpImage: "blueSpiral980.webp",
    webpImageSize: "75 KB",
    notes: ""
}, {
    sceneId: 5,
    description: "Abstract Texture",
    pngImage: "abstractWaves980.png",
    pngImageSize: "446 KB",
    webpImage: "abstractWaves980.webp",
    webpImageSize: "57 KB",
    notes: ""
}];
	
</attachScript>

<div id="imageComparisons"></div>

<attachScript type="deferjs">
	$(document).ready(function() {
		$("#imageComparisons").kendoGrid({
			dataSource: {
				data: scenes,
				schema: {
					model: {
						fields: {
							sceneId: { type: "number" },
							description: { type: "string" },
							pngImage: { type: "string" },
							pngImageSize: { type: "string" },
							webpImage: { type: "string" },
							webpImageSize: { type: "string" },
							notes: { type: "string" }
						}
					}
				},
				pageSize: 5
			},
			scrollable: true,
			resizable: true,
			sortable: true,
			filterable: false,
			pageable: false,
			columns: [
				{ field: "sceneId", title: "#", width: "5%" },
				{ field: "pngImage", title: ".Png", width: "33%" },
				{ field: "pngImageSize", title: "Size", width: "15%"},
				{ field: "webpImage", title: ".Webp",  width: "33%" },
				{ field: "webpImageSize", title: "Size", width: "15%" }
			]
		});
	});
</attachScript>

<p>The entire payload of all of the combined webp images is 90% less than one of the actual png images! With this type of extreme size reduction we can vastly improve our loading time, or we can now use full quality images in animated sequences like this!</p>

<p>I am also using webp instead of jpg images. Here the improvements are not as as substantial, but I have shaved about 10-15% of the size of the jpg images.</p>

<p><b>How to get started with webp images.</b></p>

<p><b>Server side code</b></p>

<p>Currently, with the exception of Safari- most modern HTML5 capable browsers support webp images. To determine if a browser supports the next generation format is relatively easy. Thankfully, nearly all modern browsers will include webp support in the header if the browser supports the webp next gen image. Here is the ColdFusion script that I developed.</p>
<code>
<!--- Determine if the http accept header contains webp. The getHttpRequestData().headers is a structure and we are targetting the accept element in the array. Note: nearly all modern browsers will include this if the browser supports the webp next gen image. --->
<cfset acceptHeader = getHttpRequestData().headers["accept"]>
<!--- Does the header accept webp? --->
<cfif findNoCase("webp", acceptHeader) gt 0>
	<cfset clientAcceptsWebP = true>
<cfelse>
	<cfset clientAcceptsWebP = false>
</cfif>
</code>
		
<p><b>A hybrid server side and client side approach</b></p>
		
<p>Most web servers support the webp image format as well. However, on web servers that are not current, you may need to add the webp mime type. Consult with your ISP or server documentation to find out how to add webp mime type on your server. Here is the function that I developed to test webp support on the server and save the result as a persistent application variable. You will have to create a small webp image and upload to your own server for this to work (see headerBodyDivider.webp below).</p
	

<code>
<!--- Determine if the webP mime type is set up on the server. --->
	<cffunction name="serverSupportsWebP" access="public" returntype="boolean" output="yes">
		<!--- Note: we need to eliminate https from the root URL if it exists. I ran into errors trying this with https (a cryptic certificate error). --->
		<cfset thisUrl = replaceNoCase(application.rootUrl, "https", "http")>
		<!--- The headerBodyDivider image is a tiny .webp image (around 1k). We are going to read this, and if it was found and the mime type is correct, we will assumed that the mime type is correct. Otherwise, we will determine that the server does not support the webp mime type. --->
		<cfhttp method="get" URL="#thisUrl#/images/divider/headerBodyDivider.webp">
			
		<!--- Was the webp image found? --->
		<cfif cfhttp.mimeType contains 'webp'>
			<cfset webp = true>
		<cfelse>
			<cfset webp = false>
		</cfif>
		<!--- Return it. --->
		<cfreturn webp>
	</cffunction>	
</code>

<p>In my code, I either use the server side logic above to test both the server and the client for webp support, or I use a hybrid approach where I save the result of the serverSupportsWebP server side function and test for support using javascript on the client like so:</p>
				
<code>
	<InvalidTag>
		// WebP support detection. Revised a script found on stack overflow: https://stackoverflow.com/questions/5573096/detecting-webp-support. It is the quickest loading script to determine webP that I have found so far.
		function webPImageSupport() {
			// Detemine if the webp mime type is on the server. This is saved as a ColdFusion application variable.
			var serverSupportsWebP = <cfoutput>#application.serverSupportsWebP#</cfoutput>;
    		var elem = document.createElement('canvas');
			
    		if (serverSupportsWebP && !!(elem.getContext && elem.getContext('2d'))) {
        		// Is able to get WebP representation?
        		return elem.toDataURL('image/webp').indexOf('data:image/webp') == 0;
    		}
    		// webp is not supported on older browsers such as IE.
    		return false;
		}
	</script>
</code>

<p>Using either approach is valid. However, I typically use server side code to set the paths of my images, and only use the hybrid approach (using the script above) when I am manipulating the DOM with javascript.</p>
				
<p><b>Example server side logic to set the image extension</b></p>

<p>I personally set the default image to be png or jpg, and only change it if both the client and the server support webp:</p>
				
<code>
	<!--- Determine if the http accept header contains webp. The getHttpRequestData().headers is a structure and we are targetting the accept element in the array. Note: nearly all modern browsers will include this if the browser supports the webp next gen image. --->
	<cfset acceptHeader = getHttpRequestData().headers["accept"]>
	<!--- Does the header accept webp? --->
	<cfif findNoCase("webp", acceptHeader) gt 0>
		<cfset clientAcceptsWebP = true>
	<cfelse>
		<cfset clientAcceptsWebP = false>
	</cfif>
		
	<!--- Logic to determine if the server has the necessary webp mime type was done in the application.cfc template. We will use the application.serverSupportsWebP variable that the mime type is installed on the server. Of course, both the client and the server need to support webp images before we can deliver them.---> 
	<cfif application.serverSupportsWebP and clientAcceptsWebP>
		<cfset webpImageSupported = true>
	<cfelse>
		<cfset webpImageSupported = false>
	</cfif>
		
	<cfif webpImageSupported>
		<!--- Overwrite the headerBodyDividerImage var and change the extension to .webp --->
		<cfset headerBodyDividerImage = replaceNoCase(headerBodyDividerImage, '.png', '.webp')>
	</cfif>
</code>

<p><b>Tips</b></p>
		
<p>When saving webp images, don't use the Adobe Photoshop or Illustrator plugin's. There are two of them as of today, and neither of them work well. Instead, just create your images and save them as jpg or png, and use Irfanview 64 to open and save them as a webp image. I have tried many approaches, and this method has proven to be the most reliable.</p>
		
<p>Thanks for reading, and happy coding!</p>
		
<p>Gregory</p>
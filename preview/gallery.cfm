<!DOCTYPE html>
<!--- <cfdump var="#URL#" label="url"> --->
<!---<cfsilent>--->
<!--- Extract the media items for this media id. --->
<cfparam name="URL.galleryId" default="">
<cfparam name="darkTheme" default="false">
	
<!--- Set the page --->
<cfset pageId = 3>
<cfset pageName = "GalleryPreview"><!--- Galler Preview --->
<cfset pageTypeId = 1>
	
<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
<cfobject component="#application.rendererComponentPath#" name="RendererObj">

<!--- Get the HTML for this galleryId --->
<cfset galleryHtml = RendererObj.renderImageGalleryFromDb(URL.galleryId, true)>
	
<html>
    <head>
        <title>Image Gallery Preview</title>
        <meta http-equiv='Content-Type' content='text/html; charset=utf-8'/>
		
		<script
	  		src="https://code.jquery.com/jquery-3.4.1.min.js"
	  		integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo="
	  		crossorigin="anonymous"></script>
		
		<!-- Add fancyBox main JS and CSS files -->
		<script type="text/javascript" src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/fancyBox/v2/source/jquery.fancybox.pack.js?v=2.1.5"></script>
		<link rel="stylesheet" type="text/css" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/fancyBox/v2/source/jquery.fancybox.css?v=2.1.5" media="screen" />
		
		<style>
		/* FancyBox */
		.fancybox-effects img {
			border: 1px solid #808080; /* Gray border */
			border-radius: 3px;  /* Rounded border */
			padding: 5px; 
		}

		/* Add a hover effect (blue shadow) */
		.fancybox-effects img:hover {
		  	box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5);
			opacity: .82;
		}
				
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 3px;
		}
		
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 3px;
		}
			
		/* FancyBox Thumnails */
		.thumbnail {
			position: relative;
			width: <cfif session.isMobile>105<cfelse>225</cfif>px;
			height: <cfif session.isMobile>105<cfelse>128</cfif>px;
			padding: 5px;
			padding-top: 5px;
			padding-left: 5px;
			padding-right: 5px;
			padding-bottom: 5px;
			box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);
			overflow: hidden;
		}
		
		.thumbnail img {
			position: absolute;
			left: 50%;
			top: 50%;
			height: 100%;
			width: auto;
			-webkit-transform: translate(-50%,-50%);
			  -ms-transform: translate(-50%,-50%);
				  transform: translate(-50%,-50%);
		}
		
		.thumbnail img.portrait {
		  width: 100%;
		  height: auto;
		}
		
		/* See https://aaronparecki.com/2016/08/13/4/css-thumbnails */
		.squareThumbnail {
			/* set the desired width/height and margin here */
			width: 128px;
			height: 128px;
			margin-right: 1px;
			position: relative;
			overflow: hidden;
			display: inline-block;
		}
		
		.squareThumbnail img {
			position: absolute;
			left: 50%;
			top: 50%;
			height: 100%;
			width: auto;
			-webkit-transform: translate(-50%,-50%);
			  -ms-transform: translate(-50%,-50%);
				  transform: translate(-50%,-50%);
		}
		.squareThumbnail img.portrait {
			width: 100%;
			height: auto;
		}
		</style>
		
		<script type="text/javascript">
			$(document).ready(function() {

				// Load fancyBox */
				$('.fancybox').fancybox();

				// Set fancybox custom properties (I am over-riding basic functionality).
				$(".fancybox-effects").fancybox({
					wrapCSS    : 'fancybox-custom', //ga
					padding: 5,
					openEffect : 'elastic',
					openSpeed  : 150,
					closeEffect : 'elastic',
					closeSpeed  : 150,
					closeClick : false,
					helpers : {
						title : {
							 type: 'outside'
						},
						overlay : null
					}
				});
			});//..document.ready
		</script>
    </head>
    <body>
	<cfoutput>#galleryHtml#</cfoutput>
	
    </body>
</html>
	
	
		
    </body>
</html>
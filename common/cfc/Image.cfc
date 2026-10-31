<cfcomponent displayname="Image" hint="Cfc to convert ColdFusion objects into proper json objects." name="cfJson">
	
	<cffunction name="getImageUploadDestination" access="public" output="false" returntype="string" 
			hint="Provides information about an image using the built in ColdFusion cfimage function.">
		<cfargument name="mediaProcessType" type="string" required="yes" hint="The mediaProcessType is sent in every ajax request when we upload images.">
		
		<!--- Set our final destination. To reduce potential confilict between the image names, we are saving each type of media in its own folder --->
		<cfswitch expression="#arguments.mediaProcessType#">
			<cfcase value="comment">
				<cfset destination = expandPath("#application.baseUrl#/enclosures/comment")>
			</cfcase>
			<cfcase value="enclosure">
				<cfset destination = expandPath("#application.baseUrl#/enclosures")>
			</cfcase>
			<cfcase value="mediaVideoCoverUrl">
				<cfset destination = expandPath("#application.baseUrl#/enclosures/videos")>
			</cfcase>
			<cfcase value="gallery">
				<cfset destination = expandPath("#application.baseUrl#/enclosures/gallery")>
			</cfcase>
			<cfcase value="carousel">
				<cfset destination = expandPath("#application.baseUrl#/enclosures/carousel")>
			</cfcase>
			<cfcase value="post">
				<cfset destination = expandPath("#application.baseUrl#/enclosures/post")>
			</cfcase>
			<cfcase value="profilePicture">
				<cfset destination = expandPath("#application.baseUrl#/images/photo")>
			</cfcase>
			<cfcase value="userBio">
				<cfset destination = expandPath("#application.baseUrl#/images/photo")>
			</cfcase>
			<!--- Theme related images --->
			<cfcase value="blogBackgroundImage">
				<cfset destination = expandPath("#application.baseUrl#/images/background")>
			</cfcase>
			<cfcase value="blogBackgroundImageMobile">
				<cfset destination = expandPath("#application.baseUrl#/images/background")>
			</cfcase>
			<cfcase value="headerBackgroundImage">
				<cfset destination = expandPath("#application.baseUrl#/images/header")>
			</cfcase>
			<cfcase value="menuBackgroundImage">
				<cfset destination = expandPath("#application.baseUrl#/images/header")>
			</cfcase>
			<cfcase value="logoImage">
				<cfset destination = expandPath("#application.baseUrl#/images/logo")>
			</cfcase>
			<cfcase value="logoImageMobile">
				<cfset destination = expandPath("#application.baseUrl#/images/logo")>
			</cfcase>
			<cfcase value="defaultLogoImageForSocialMediaShare">
				<cfset destination = expandPath("#application.baseUrl#/images/logo")>
			</cfcase>
			<cfcase value="footerImage">
				<cfset destination = expandPath("#application.baseUrl#/images/logo")>
			</cfcase>
			<!--- Page Collection hero images share the plain enclosures folder - matches the imageUrl "Standard
			pathway" fallback in ProxyController.cfc's uploadImage, which already assumes this exact path for any
			mediaProcessType not explicitly listed there. Without this case, destination was left undefined and
			every pageCollectionHero upload threw immediately at the fileExists() check that follows. --->
			<cfcase value="pageCollectionHero">
				<cfset destination = expandPath("#application.baseUrl#/enclosures")>
			</cfcase>
			<!--- 2026-10-01: same plain enclosures folder as a normal enclosure image - createSocialMediaImages()'s
			own relative-path conventions (facebook/twitter/classic/pinterest crop folders alongside this one)
			need the cover image to live here to keep working unmodified. --->
			<cfcase value="heroCoverImage">
				<cfset destination = expandPath("#application.baseUrl#/enclosures")>
			</cfcase>
		</cfswitch>
				
		<!--- The following logic uses or statements --->
		<cfif arguments.mediaProcessType contains 'header'>
			<cfset destination = expandPath("#application.baseUrl#/images/header")>
		<cfelseif arguments.mediaProcessType contains 'window'>	
			<cfset destination = expandPath("#application.baseUrl#/images/windows")>
		<cfelseif arguments.mediaProcessType contains 'pod'>	
			<cfset destination = expandPath("#application.baseUrl#/images/pods")>
		<cfelseif arguments.mediaProcessType contains 'footer'>	
			<cfset destination = expandPath("#application.baseUrl#/images/footer")>
		</cfif>
				
		<!--- Return it. --->
		<cfreturn destination>
		
	</cffunction>
	
	<cffunction name="getImageInfo" access="public" output="false" returntype="struct" hint="Provides information about an image using the built in ColdFusion cfimage function.">
    	<cfargument name="imageUrl" type="string" required="yes" hint="provide the full path to the image.">
		
		<cfimage 
			action = "info"
			source = "#arguments.imageUrl#"
			structname="imageInfo"> 
		
		<!--- Return the structure. --->
		<cfreturn imageInfo>
		
	</cffunction>
			
	<cffunction name="getImageOrientation" access="public" output="false" returntype="string" hint="Returns a string which will be either landscape or portrait.">
		<cfargument name="imageUrl" type="string" required="yes" hint="provide the full path to the image.">

		<cfimage 
			action = "info"
			source = "#arguments.imageUrl#"
			structname="imageInfo"> 

		<cfif imageInfo.width gt imageInfo.height>
			<cfset orientation = "landscape">
		<cfelseif imageInfo.width lt imageInfo.height>
			<cfset orientation = "portrait">
		<cfelse>
			<cfset orientation = "portrait">
		</cfif>

		<!--- Return the orientation. --->
		<cfreturn orientation>

	</cffunction>
			
	<cffunction name="createThumbnail" access="public" output="false" returntype="string" hint="Creates thumbnail images 235 width by 138. These are used in the administrative interface as well as used for gallery thumbnail images when creating a gallery.">
		<cfargument name="imagePath" type="string" required="yes" hint="Provide the path to the image.">
		<cfargument name="imageName" type="string" required="yes" hint="The image name.">
		<cfargument name="destination" type="string" required="no" default="" hint="This has logic to determine the destination, but you can over-ride it.">
			
		<cfset debug = false>
			
		<cfset thumbNailWidth = "235">
		<cfset thumbNailHeight = "138">
			
		<cfif len(arguments.destination)>
			<!--- Set the destination if specified. --->
			<cfset destination = expandPath(arguments.destination)>
		<cfelse>
			<!--- Set the default destination (#application.baseUrl#\enclosures\thumbnails). --->
			<cfset destination = expandPath("#application.baseUrl#\enclosures\thumbnails")>
		</cfif>
		
		<cfif debug>Destination:<cfoutput>#destination#\#arguments.imageName#</cfoutput><br/></cfif>
			
		<cfif debug>Reading image from: <cfoutput>#destination#\#arguments.imagePath#</cfoutput><br/></cfif>
		<!--- Read the image to determine how to scale it --->
		<cfimage 
			action = "info"
			source = "#arguments.imagePath#"
			structname="origImageInfo">
			<cfif debug><cfdump var="#origImageInfo#"></cfif>
			
		<cfif debug>Original image width: <cfoutput>#origImageInfo.width# height: #origImageInfo.height#</cfoutput><br/></cfif>
			
		<!--- Create the new image that we will be working with --->
		<cfset thumbnail = imageNew(arguments.imagePath)>
			
		<!--- If the image is twice as large as the desired thumbnail, shrink it down a bit before we crop it. Without this we will end up cropping tiny portion of the center of the image. --->
		<cfif (origImageInfo.width * 2) gte thumbNailWidth>
			<!--- Precrop the new image. For portrait images, we are going to resize the image to 300 pixels wide (ImageResize(image, width, height). If the height is blank it will resize the image proportionally) --->
			<cfset imageResize(thumbnail, 300, '')>
		</cfif>
			
		<!--- Read the image to determine how to scale it --->
		<cfimage 
			action = "info"
			source = "#thumbnail#"
			structname="thumbnailInfo">
			
		<cfif debug>New thumbnail (before center crop) width: <cfoutput>#thumbnailInfo.width# height: #thumbnailInfo.height#</cfoutput><br/></cfif>
		
		<!--- Handle landscape images. Here we will determine the image ratio to determine the new height while using the known thumbnail width. --->
		<cfif getImageOrientation(imagePath) eq 'landscape'>

			<!--- Determine the new height of the images while preserving the aspect ratio of 235 x 138. --->
			<cfset newHeight = ratioCalculator(thumbnailInfo.width, thumbnailInfo.height, thumbNailWidth)>
			<!--- Crop the image from the center (centerCrop(path, originalWidth, originalHeight, newWidth, newHeight)) --->
			<cfif debug>Invoking centerCrop(thumbnail, <cfoutput>#thumbnailInfo.width#, #thumbnailInfo.height#, #thumbNailWidth#, #newHeight#</cfoutput>)<br/></cfif>
			<cfset thumbnail = centerCrop(thumbnail, thumbnailInfo.width, thumbnailInfo.height, thumbNailWidth, newHeight)>

		<cfelse>
			<!--- Handle portrait images. Here we will determine the image ratio to determine the new width while using the known thumbnail height. --->

			<!--- Determine the new height of the images while preserving the aspect ratio of 235 x 138. --->
			<cfset newHeight = ratioCalculator(thumbnailInfo.width, thumbnailInfo.height, thumbNailWidth)>
			<!--- Crop the top and bottom of the original image from the center (horizontalCrop(path, originalHeight, newHeight). --->
			<cfif debug>Invoking horizontalCrop(thumbnail, <cfoutput>#thumbnailInfo.height#, #thumbNailHeight#, #thumbNailWidth#</cfoutput>)<br/></cfif>
			<cfset thumbnail = horizontalCrop(thumbnail, thumbnailInfo.height, thumbNailHeight, thumbnailWidth)>
		</cfif>
				
		<!--- Save the modified image to a file. --->
		<cftry>
			<cfimage source="#thumbnail#" action="write" destination="#destination#\#arguments.imageName#" overwrite="yes">
			<cfcatch type="any">
				<cfset destination = ""/>
				<cfset error = "Folder permissions issue">
			</cfcatch>
		</cftry>
		<!--- And set permissions on Linux. This should set the following permissions: owner all, group read, other read --->
		<cfset fileSetAccessMode("#destination#\#arguments.imageName#", "644")>
		
		<cfreturn destination>
		
	</cffunction>

	<cffunction name="createCardImage" access="public" output="false" returntype="string"
			hint="The picture for a post's card on the home page and the other card lists (2026-10-31, owner: the cards showed the full-size upload - up to 1580px and 200KB - in a card a few hundred pixels wide). The picture scaled down to 640px wide, its shape kept (the card's CSS crops it), as WebP where the engine writes WebP, else in the picture's own format. Saved in /enclosures/cards/ under the picture's name. Returns its address (application.baseUrl/enclosures/cards/name), or an empty string when it could not be made. A picture already 640px wide or smaller is copied as it is.">
		<cfargument name="imagePath" type="string" required="yes" hint="The full path to the uploaded picture.">
		<cfargument name="quality" type="numeric" required="no" default="0.8">
		<cfset var cardWidth = 640>
		<cfset var folder = expandPath(application.baseUrl & "/enclosures/cards")>
		<cfset var baseName = reReplaceNoCase(getFileFromPath(arguments.imagePath), "\.[^.]+$", "")>
		<cfset var extension = lCase(listLast(getFileFromPath(arguments.imagePath), "."))>
		<cfset var fileName = "">
		<cfset var picture = "">
		<cftry>
			<cfif not directoryExists(folder)><cfdirectory action="create" directory="#folder#"></cfif>
			<!--- An animated GIF keeps its animation only as a GIF, so it is copied as it is. --->
			<cfif extension eq "gif">
				<cfset fileName = getFileFromPath(arguments.imagePath)>
				<cffile action="copy" source="#arguments.imagePath#" destination="#folder#/#fileName#" nameconflict="overwrite">
			<cfelse>
				<!--- WebP where the engine writes it; otherwise JPG (2026-10-31: ColdFusion 2023 can't write WebP, so a WebP picture's
				card failed there - PNG keeps its own format, for transparency). --->
				<cfset fileName = baseName & "." & (application.imageEngineSupportsWebP ? "webp" : (extension eq "png" ? "png" : "jpg"))>
				<cfset picture = imageRead(arguments.imagePath)>
				<cfif imageGetWidth(picture) gt cardWidth>
					<cfset imageResize(picture, cardWidth, "", "highQuality")>
				</cfif>
				<cfset imageWrite(picture, folder & "/" & fileName, arguments.quality, true)>
			</cfif>
			<cftry><cfset fileSetAccessMode(folder & "/" & fileName, "644")><cfcatch type="any"></cfcatch></cftry>
			<cfreturn application.baseUrl & "/enclosures/cards/" & fileName>
			<cfcatch type="any">
				<cfreturn "">
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getCardImageUrl" access="public" output="false" returntype="string"
			hint="The card-sized copy of a post's picture (createCardImage) when it exists, or else the address given. Takes a picture's address (/blog/enclosures/name.jpg) and looks for /enclosures/cards/name.webp, then name.jpg (or the picture's own format).">
		<cfargument name="imageUrl" type="string" required="yes">
		<cfset var fileName = getFileFromPath(arguments.imageUrl)>
		<cfset var baseName = reReplaceNoCase(fileName, "\.[^.]+$", "")>
		<cfset var candidate = "">
		<cfif not len(fileName) or not reFindNoCase("\.(jpe?g|png|webp|gif)$", fileName)><cfreturn arguments.imageUrl></cfif>
		<cfloop list="#baseName#.webp,#fileName#,#baseName#.jpg" index="candidate">
			<cfif fileExists(expandPath(application.baseUrl & "/enclosures/cards/" & candidate))>
				<cfreturn application.baseUrl & "/enclosures/cards/" & candidate>
			</cfif>
		</cfloop>
		<cfreturn arguments.imageUrl>
	</cffunction>
			
	<cffunction name="createSocialMediaImages" access="public" output="false" returntype="any" hint="Creates images for social media sharing.">
		<cfargument name="imagePath" type="string" required="yes" hint="Provide the path to the image.">
		<cfargument name="socialMediaPlatform" type="string" required="yes" hint="Provide the social media platform. The valid arguments are: facebook, twitter, instagram, linkedIn, google, pinterest, and classic. Logic will determine the best size for the image to fit the platform's image share specification. 'classic' is the universal 1200x900 fallback crop, always generated - see seoMetaTags.cfm. 'pinterest' (1000x1500) is only generated when the source image clears that full threshold - there is no smaller fallback tier for it, so createSocialMediaImages() returns false and writes nothing when it doesn't qualify.">
		<cfargument name="socialMediaImageType" type="string" required="no" default="" hint="Unless you're trying to create Google images, this argument is optional in order to over-ride the default logic and force the type of image format that you want. If you specify this argument, it will over-ride the socialMediaPlatform argument. Logic will still be used to see if the images are valid for the large image types and substitute smaller images when necessary. Valid arguments are: facebookSharedImage, facebookLinkSquareImage, facebookLinkRectangleImage, twitterInstreamImage, twitterInstreamMinimumImage, instagramImage, instagramMinimumImage, linkedInImage, linkedInMinimumImage, google16_9Image, google4_3Image, google1_1Image, pinterestImage, and classicGalaxieBlogImage. This argument must be present when creating google images.">
		<cfargument name="quality" type="numeric" required="no" default="0.8" hint="Passed straight through to every cfimage write's own quality attribute (0.1-1.0) - both the original-format file and its webp companion. Defaults to match BlogOption's own DefaultImageQuality default, so a caller that doesn't pass this explicitly still gets sensible site-wide compression rather than CF's own unrelated default.">

		<!--- Set output to true when debugging --->
		<cfset imageDebug = false>

		<!--- None of this function's locals are var-scoped (pre-existing), so they persist on the CFC instance
		between calls - ProxyController.cfc's upload flow instantiates ImageObj once and calls this function
		repeatedly (facebook, twitter, google x3, pinterest, classic) in the same request. Every other variable here
		gets unconditionally reassigned before use each call, but skipSocialMediaImage is only conditionally SET (in
		the pinterestImage/qualifying-check cfcase) and never explicitly cleared - without this reset, a Pinterest
        call that skips would leave skipSocialMediaImage=true lingering for classic (or any call after it) to
		incorrectly bail out on too. --->
		<cfset skipSocialMediaImage = false>

		<!--- Set the arguments. These may need to be updated anually. --->
		<!--- Facebook shared image. --->
		<cfset facebookSharedImageWidth = 1200>
		<cfset facebookSharedImageHeight = 630>
		<!--- Shared links--->
		<cfset facebookLinkSquareImageWidth = 116>
		<cfset facebookLinkSquareImageHeight = 116>
		<cfset facebookLinkRectangleImageWidth = 484>
		<cfset facebookLinkRectangleImageHeight = 252>
		<!--- Twitter instream photo. Used to be a 2x1 ratio. Now at 1:91x1--->
		<cfset twitterInstreamImageWidth = 1200><!---Used to be 1024--->
		<cfset twitterInstreamImageHeight = 628><!---Used to be 512--->
		<cfset twitterInstreamMinimumImageWidth = 518>
		<cfset twitterInstreamMinimumImageHeight = 226>
		<!--- Instagram photo size --->
		<cfset instagramImageWidth = 1080>
		<cfset instagramImageHeight = 1080>	

		<cfset instagramMinimumImageWidth = 600>
		<cfset instagramMinimumImageHeight = 315>
		<!--- Linked in --->
		<cfset linkedInImageWidth = 1128>
		<cfset linkedInImageHeight = 376>
		<cfset linkedInMinimumImageWidth = 502>
		<cfset linkedInMinimumImageHeight = 282>
		<!--- Google images for structured data --->
		<cfset google16_9ImageWidth = 1200>
		<cfset google16_9ImageHeight = 675>
		<cfset google4_3ImageWidth = 1100>
		<cfset google4_3ImageHeight = 825>
		<cfset google1_1ImageWidth = 630><!---I can't find the mimimum size other than having a certain number of pixels (minimum of 50K pixels) --->
		<cfset google1_1ImageHeight = 630>
		<!--- Pinterest pin image (2:3 portrait) - no smaller "minimum" fallback tier like the other platforms get.
		A looser/smaller crop from a landscape source doesn't fix the actual problem (wrong shape, not too few
		pixels) - it just makes the same bad crop at lower resolution. So this either clears the full threshold or
		Pinterest generation is skipped for that image entirely - see the pinterest cfcase below. --->
		<cfset pinterestImageWidth = 1000>
		<cfset pinterestImageHeight = 1500>
		<!--- The universal fallback/default crop - matches the "classic" 1200x900 (4:3) master image convention used
		before the site moves to a higher-res master. Always generated (no qualifying gate, unlike Pinterest) - see
		the classic cfcase below - since its whole purpose is to be the thing seoMetaTags.cfm falls back to when no
		platform-specific crop exists, instead of silently serving the full uncropped original. --->
		<cfset classicGalaxieBlogImageWidth = 1200>
		<cfset classicGalaxieBlogImageHeight = 900>

		<!--- Read the image to determine how to scale it --->
		<cfimage 
			action = "info"
			source = "#imagePath#"
			structname="imageInfo">
			
		<cfif imageDebug>Original image width: <cfoutput>#imageInfo.width# height: #imageInfo.height#</cfoutput><br/></cfif>
			
		<!--- If the socialMediaImageType was not specified in the arguments, determine the type of image format that should be used. ---> 
		<cfif arguments.socialMediaImageType eq ''>
			<cfswitch expression="#socialMediaPlatform#">
				<cfcase value="facebook">
					<!--- Is the original image larger or smaller than Facebook's large image size? If larger, use the larger image dimensions specified by the social media platform. If the original image is smaller, use a smaller sized image. We are going to use similiar logic for every social media platform. --->
					<cfif imageInfo.width gte facebookSharedImageWidth and imageInfo.height gte facebookSharedImageHeight>
						<!--- Use the larger social media format. --->
						<cfset socialMediaImageType = "facebookSharedImage">
					<cfelse>
						<cfif imageInfo.width gte facebookLinkRectangleImageWidth and imageInfo.height gte facebookLinkRectangleImageHeight>
							<cfset socialMediaImageType = "facebookLinkRectangleImage">
						<cfelse><!---<cfif imageInfo.width gte facebookLinkRectangleImageWidth and imageInfo.height gte facebookLinkRectangleImageHeight>--->
							<!--- Use the facebookLinkSquareImage --->
							<cfset socialMediaImageType = "facebookLinkSquareImage">
						</cfif><!---<cfif imageInfo.width gte facebookLinkRectangleImageWidth and imageInfo.height gte facebookLinkRectangleImageHeight>--->
					</cfif>
				</cfcase>
				<cfcase value="twitter">
					<cfif imageInfo.width gte twitterInstreamImageWidth and imageInfo.height gte twitterInstreamImageHeight>
						<!--- Large twitter format --->
						<cfset socialMediaImageType = "twitterInstreamImage">
					<cfelse><!---<cfif imageInfo.width gte twitterInstreamImageWidth and imageInfo.height gte twitterInstreamImageHeight>--->
						<!--- Minumum twitter format. --->
						<cfset socialMediaImageType = "twitterInstreamMinimumImage">
					</cfif><!---<cfif imageInfo.width gte twitterInstreamImageWidth and imageInfo.height gte twitterInstreamImageHeight>--->
				</cfcase>
				<cfcase value="instagram">
					<cfif imageInfo.width gte twitterInstreamImageWidth and imageInfo.height gte twitterInstreamImageHeight>
						<!--- Large twitter format --->
						<cfset socialMediaImageType = "instagramImage">
					<cfelse>
						<!--- Minumum twitter format. --->
						<cfset socialMediaImageType = "instagramMinimumImage">
					</cfif>
				</cfcase>
				<cfcase value="linkedIn">
					<cfif imageInfo.width gte linkedInImageWidth and imageInfo.height gte linkedInImageHeight>
						<cfset socialMediaImageType = "linkedInImage">
					<cfelse>
						<cfset socialMediaImageType = "linkedInMinimumImage">
					</cfif>
				</cfcase>
				<cfcase value="pinterest">
					<!--- The real qualify-or-skip check happens below (socialMediaImageType switch), same place every
					other platform's real check happens - this just names the intended type. --->
					<cfset socialMediaImageType = "pinterestImage">
				</cfcase>
				<cfcase value="classic">
					<cfset socialMediaImageType = "classicGalaxieBlogImage">
				</cfcase>
			</cfswitch>
		</cfif>
					
		<!--- Preset the preCrop var. --->
		<cfset preCrop = false>
		
		<!--- We are going to replicate the same logic as above even if the socialMediaImageType is specified to make sure that the size of the image matches the chosen social media image type.--->
		<cfswitch expression="#socialMediaImageType#">
			<cfcase value="facebookSharedImage">
				<!--- Is the original image larger or smaller than the large image size? If larger, use the larger image dimensions specified by the social media platform. If the original image is smaller, use the miniumum size. We are going to use the same logic for every social media type. --->
				<cfif imageInfo.width gte facebookSharedImageWidth and imageInfo.height gte facebookSharedImageHeight>
					<!--- Use the larger social media format. --->
					<cfset thisImageWidth = facebookSharedImageWidth>
					<cfset thisImageHeight = facebookSharedImageHeight>
				<cfelse>
					<!--- Use the rectangular facebook format. --->
					<cfset thisImageWidth = facebookLinkRectangleImageWidth>
					<cfset thisImageHeight = facebookLinkRectangleImageHeight>
					<cfset preCrop = true>
				</cfif>
			</cfcase>
			<!--- Intermediate sized facebook rectangular image. --->
			<cfcase value="facebookLinkRectangleImage">
				<cfset preCrop = true>
				<cfif imageInfo.width gte facebookLinkRectangleImageWidth and imageInfo.height gte facebookLinkRectangleImageHeight>
					<cfset thisImageWidth = facebookLinkRectangleImageWidth>
					<cfset thisImageHeight = facebookLinkRectangleImageHeight>
				<cfelse>
					<!--- Use the facebookLinkSquareImage --->
					<cfset thisImageWidth = facebookLinkSquareImageWidth>
					<cfset thisImageHeight = facebookLinkSquareImageHeight>
				</cfif>
			</cfcase>
			<!--- The smallest facebook image. --->
			<cfcase value="facebookLinkSquareImage">
				<cfset preCrop = true>
				<!--- This does not need any checking. It is already the smallest image format for Facebook. --->
				<cfset thisImageWidth = facebookLinkSquareImageWidth>
				<cfset thisImageHeight = facebookLinkSquareImageHeight>
			</cfcase>
			<!--- Large twitter image. --->
			<cfcase value="twitterInstreamImage">
				<cfif imageInfo.width gte twitterInstreamImageWidth and imageInfo.height gte twitterInstreamImageHeight>
					<!--- Large twitter format --->
					<cfset thisImageWidth = twitterInstreamImageWidth>
					<cfset thisImageHeight = twitterInstreamImageHeight>
				<cfelse>
					<!--- Minumum twitter format. --->
					<cfset preCrop = true>
					<cfset thisImageWidth = twitterInstreamMinimumImageWidth>
					<cfset thisImageHeight = twitterInstreamMinimumImageHeight>
				</cfif>
			</cfcase>
			<!--- Smallest twitter image. --->
			<cfcase value="twitterInstreamMinimumImage">
				<!--- Minumum twitter format. --->
				<cfset preCrop = true>
				<cfset thisImageWidth = twitterInstreamMinimumImageWidth>
				<cfset thisImageHeight = twitterInstreamMinimumImageHeight>
			</cfcase>
			<cfcase value="instagramImage">
				<cfif imageInfo.width gte instagramImageWidth and imageInfo.height gte instagramImageHeight>
					<cfset thisImageWidth = instagramImageWidth>
					<cfset thisImageHeight = instagramImageHeight>
				<cfelse>
					<cfset preCrop = true>
					<cfset thisImageWidth = instagramMinimumImageWidth>
					<cfset thisImageHeight = instagramMinimumImageHeight>
				</cfif>
			</cfcase>
			<cfcase value="instagramMinimumImage">
				<cfset preCrop = true>
				<cfset thisImageWidth = instagramMinimumImageWidth>
				<cfset thisImageHeight = instagramMinimumImageHeight>
			</cfcase>
			<!--- Large twitter image. --->
			<cfcase value="linkedInImage">
				<!--- Linked in images can't be pre-cropped. They're too narrow and wide. --->
				<cfif imageInfo.width gte linkedInImageWidth and imageInfo.height gte linkedInImageHeight>
					<cfset thisImageWidth = linkedInImageWidth>
					<cfset thisImageHeight = linkedInImageHeight>
				<cfelse>
					<cfset thisImageWidth = linkedInMinimumImageWidth>
					<cfset thisImageHeight = linkedInMinimumImageHeight>
				</cfif>
			</cfcase>
			<!--- Smallest linkedin image. --->
			<cfcase value="linkedInMinimumImage">
				<!--- Linked in images can't be pre-cropped. They're too narrow and wide. --->
				<cfset thisImageWidth = linkedInMinimumImageWidth>
				<cfset thisImageHeight = linkedInMinimumImageHeight>
			</cfcase>
			<!--- Google images. ---> 
			<!--- 16x9 format. --->
			<cfcase value="google16_9Image">
				<cfset thisImageWidth = google16_9ImageWidth>
				<cfset thisImageHeight = google16_9ImageHeight>
			</cfcase>
			<!--- 4x3 format. --->
			<cfcase value="google4_3Image">
				<cfset thisImageWidth = google4_3ImageWidth>
				<cfset thisImageHeight = google4_3ImageHeight>
			</cfcase>
			<cfcase value="google1_1Image">
				<!--- Don't precrop this, even though it is small, the 630 height will cause an error on landscape images. --->
				<cfset thisImageWidth = google1_1ImageWidth>
				<cfset thisImageHeight = google1_1ImageHeight>
			</cfcase>
			<!--- Pinterest - the real qualify-or-skip check. Unlike every other platform above, there is no smaller
			fallback tier: if the source doesn't clear the full 1000x1500 threshold, we skip Pinterest for this image
			entirely (see the skipSocialMediaImage check just below) rather than force a crop that would just be the
			same bad shape at a lower resolution. --->
			<cfcase value="pinterestImage">
				<cfif imageInfo.width gte pinterestImageWidth and imageInfo.height gte pinterestImageHeight>
					<cfset thisImageWidth = pinterestImageWidth>
					<cfset thisImageHeight = pinterestImageHeight>
				<cfelse>
					<cfset skipSocialMediaImage = true>
				</cfif>
			</cfcase>
			<!--- The universal default/fallback crop - always generated, no qualifying gate. If the source is smaller
			than 1200x900 the shared landscape/portrait branch below already clamps to the source's own native size
			(see its "imageInfo.width gte thisImageWidth" check) rather than failing, so this never needs to skip. --->
			<cfcase value="classicGalaxieBlogImage">
				<cfset thisImageWidth = classicGalaxieBlogImageWidth>
				<cfset thisImageHeight = classicGalaxieBlogImageHeight>
			</cfcase>
		</cfswitch>

		<!--- Bail out cleanly (no crop, no file written) rather than falling through to the pre-crop/crop logic below
		with thisImageWidth/thisImageHeight still undefined, which would throw. --->
		<cfif isDefined("skipSocialMediaImage") and skipSocialMediaImage>
			<cfreturn false>
		</cfif>

		<!--- Before we proceed, make one final check to see if the larger facebook or twitter images are really big and determine if we should crop them too. In my testing, I uploaded large images that were 4032 pixels in width and the center cropped image only got a tiny portion of the original image. Here we are checking to see if the image is twice as large as the final image that we want to crop to- if it is, we're going to pre-crop these large images too. Excludes pinterestImage/classicGalaxieBlogImage: that check assumes a wide/landscape target (like every other case here), and would trigger it by coincidence (1000*2 >= 1200, 1200*2 >= 1200) even though both of those types' own thresholds above already guarantee enough real resolution - the plain landscape/portrait branch below (which uses the real original dimensions via getImageOrientation/centerCrop/horizontalCrop) handles both correctly without a preCrop pass. --->
		<cfif listFindNoCase("pinterestImage,classicGalaxieBlogImage", socialMediaImageType) eq 0 and (thisImageWidth * 2) gte facebookSharedImageWidth>
			<cfset preCrop = true>
		</cfif>
				
		<cfif imageDebug><cfoutput>socialMediaImageType: #socialMediaImageType# thisImageWidth: #thisImageWidth# thisImageHeight: #thisImageHeight#</cfoutput><br/></cfif>

		<!--- Handle small image formats- facebook squares and rectangles, the twitter and instagram minimum images, and really large images. We will pre-crop these images to get a larger part of the image, and then crop it again in the center. --->
		<cfif preCrop>

			<!--- Create a new image --->
			<cfset shareImage = imageNew(imagePath)>
					
			<!--- Handle small images. --->
			<!--- This logic is only invoked for Facebook rectangle links. --->
			<cfif socialMediaImageType eq 'facebookLinkRectangleImage'>
				
				<!--- Resize the new image. For portrait images, we are going to resize the image to 550 pixels wide (ImageResize(image, width, height). If the height is blank it will resize the image proportionally) --->
				<cfset imageResize(shareImage, 550, '')>
				<!--- We know the width of the new image that was just created (550), now get its height --->
				<cfset shareImageHeight = imageGetHeight(shareImage)>
				<!--- Crop the resized image from the center (centerCrop(path/image, originalWidth, originalHeight, newWidth, newHeight). We don't need to determine an aspect ratio. It is a square. --->
				<cfset shareImage = centerCrop(shareImage, 550, shareImageHeight, thisImageWidth, thisImageHeight)>
			
			<cfelse><!---<cfif (socialMediaImageType eq 'facebookLinkRectangleImage'>--->
				
				<!--- Determine how tiny we should pre-crop the image. We're going to crop this thing twice. --->
				<cfif socialMediaImageType eq 'facebookLinkSquareImage'>
					<!--- Handle Facebook link square images. These are very small and are 116x116. ---> 
					<cfset preCropSize = 250>
				<cfelseif socialMediaImageType eq 'twitterInstreamMinimumImage'>
					<!--- Handle twitter minumum. This is not as tiny as the facebook squre image. --->
					<cfset preCropSize = 550>
				<cfelseif socialMediaImageType eq 'instagramMinimumImage'>
					<!--- The instagram minimum is the largest small image from them all. --->
					<cfset preCropSize = 750>
				<cfelseif socialMediaImageType eq 'linkedInImage'>
					<!--- The linked in images are very narrow and wide --->
					<cfset preCropSize = 1000>
				<!--- Crop the larger sized images if necessary --->
				<cfelseif socialMediaImageType eq 'facebookSharedImage' or socialMediaImageType eq 'twitterInstreamImage'>
					<!--- Both the facebook and twitter large images are at 1200 wide. We need to crop it at 1500 in case if it is a portrait image --->
					<cfset preCropSize = 1500>	
				<cfelse>
					<!--- The Google types (google16_9Image, google4_3Image, google1_1Image) are pre-cropped by the "really large image" check above but had no case of their own here, so preCropSize was never set for them. This function's locals aren't var-scoped, so they silently reused whatever the previous call on the same Image object left behind (1500 from Twitter in ProxyController.cfc's upload flow). Set it explicitly - 1500 matches what they always got in practice. --->
					<cfset preCropSize = 1500>
				</cfif>
				<!--- Make sure the resized image is still tall enough for the target height, otherwise centerCrop() returns nothing and no file is written (without an error). Resizing to a fixed width only works for images that aren't too wide: a 1676x900 source resized to 1500 wide is only 805 high, short of google4_3Image's 825, so the 4:3 crop was silently skipped for wide images while a 1350x900 source (1500x1000 after the resize) worked (found 2026-10-12). Widen the pre-crop just enough to cover the target height (the +1 absorbs the resize's rounding). --->
				<cfset preCropMinimumWidth = ceiling(thisImageHeight * imageInfo.width / imageInfo.height) + 1>
				<cfif preCropSize lt preCropMinimumWidth>
					<cfset preCropSize = preCropMinimumWidth>
				</cfif>
				<!--- We are going to resize the new image to the precrop size and then crop it again. I want extra space to make sure that it fits our target size. We are putting in a blank argument for the height in order to keep the aspect ratio of the original image (ImageResize(image, width, height). If the height is blank it will resize the image proportionally) --->
				<cfset imageResize(shareImage, preCropSize, '')>
				<!--- We know the width of the new image that was just created (250), now get its height --->
				<cfset shareImageHeight = imageGetHeight(shareImage)>
				<!--- Crop the resized image from the center (centerCrop(path/image, originalWidth, originalHeight, newWidth, newHeight). We don't need to determine an aspect ratio. It is a square. --->
				<cfset shareImage = centerCrop(shareImage, preCropSize, shareImageHeight, thisImageWidth, thisImageHeight)>
				
			</cfif><!---<cfif (socialMediaImageType eq 'facebookLinkRectangleImage'>--->

			<!--- Save the modified image to a file. --->
			<cfif isDefined("shareImage")>
				<cfif imageDebug>
					<cfdump var="#shareImage#">
					<cfoutput>
					Source: #shareImage# Destination: #getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#
					</cfoutput>
				</cfif>
			
				<!--- Ensure the destination directory exists - other Galaxie Blog installations (or a brand new
				platform folder like pinterest/classic on this one) may not have it pre-created. --->
				<cfset socialMediaDestinationDir = getDirectoryFromPath(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType))>
				<cfif not directoryExists(socialMediaDestinationDir)>
					<cfdirectory action="create" directory="#socialMediaDestinationDir#">
				</cfif>

				<!--- Write the image --->
				<cfimage source="#shareImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes" quality="#arguments.quality#">
				<!--- And set permissions on Linux. This should set the following permissions: owner all, group read, other read --->
				<cfset fileSetAccessMode("#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#", "644")>

				<!--- Also write a webp companion, matching the master enclosure image's own jpg+webp convention.
				Fixes seoMetaTags.cfm's fallback chain silently serving the full uncropped original whenever a
				post's MediaUrl points to a .webp file - these crop folders never had a matching .webp file for
				that lookup to find. --->
				<!--- Guarded: WebP write support is Lucee (2.0 image extension+) and ColdFusion 2025+ only - a
				CF2023-or-earlier install has no native WebP support at all and would throw here. Skip cleanly
				rather than error and abort the rest of this function's caller-side cftry (which would otherwise
				also skip every social platform queued up after this one in the same request). --->
				<cfif application.imageEngineSupportsWebP>
					<cfset webpDestination = reReplaceNoCase(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType), "\.[^.]+$", ".webp")>
					<!--- imageWrite with a .webp file name, not <cfimage format="webp">: Lucee's cfimage tag only accepts gif, jpg, png, tiff and bmp for its format attribute even though Lucee writes WebP fine, so on Lucee this threw, the upload's cftry swallowed it, and every crop after the first (Twitter, Google, classic) was silently skipped (found in the 4.8 install test, 2026-10-11). A WebP copy that can't be written is skipped rather than stopping the other crops. --->
					<cftry>
						<cfset imageWrite(shareImage, webpDestination, arguments.quality, true)>
						<cfset fileSetAccessMode("#webpDestination#", "644")>
						<cfcatch type="any"></cfcatch>
					</cftry>
				</cfif>

			</cfif>

		<cfelse><!---<cfif precrop>--->
			
			<!--- Handle landscape images. --->
			<cfif getImageOrientation(imagePath) eq 'landscape'>
				
				<cfif imageDebug>
					<cfdump var="#cfimageData#">
					<cfoutput>#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#</cfoutput>
				</cfif>

				<!--- Determine the new width --->
				<cfif imageInfo.width gte thisImageWidth>
					<cfset newWidth = thisImageWidth>
				<cfelse>
					<cfset newWidth = imageInfo.width>
				</cfif>

				<!--- Determine the new height of the images while preserving the aspect ratio of 1200 x 630. --->
				<cfset newHeight = ratioCalculator(thisImageWidth, thisImageHeight, newWidth)>

				<!--- Create a new image --->
				<cfset thisImage = imageNew(imagePath)>
				<!--- Crop the image from the center (centerCrop(path, originalWidth, originalHeight, newWidth, newHeight)) --->
				<cfset thisImage = centerCrop(imagePath, imageInfo.width, imageInfo.height, newWidth, newHeight)>
				<!--- Ensure the destination directory exists - other Galaxie Blog installations (or a brand new
				platform folder like pinterest/classic on this one) may not have it pre-created. --->
				<cfset socialMediaDestinationDir = getDirectoryFromPath(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType))>
				<cfif not directoryExists(socialMediaDestinationDir)>
					<cfdirectory action="create" directory="#socialMediaDestinationDir#">
				</cfif>
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes" structName="cfimageData" quality="#arguments.quality#">
				<!--- And set permissions on Linux. This should set the following permissions: owner all, group read, other read --->
				<cfset fileSetAccessMode("#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#", "644")>
				<!--- Also write a webp companion, matching the master enclosure image's own jpg+webp convention - see
				the preCrop branch's own copy of this comment for why. --->
				<!--- Guarded: WebP write support is Lucee (2.0 image extension+) and ColdFusion 2025+ only - see the
				preCrop branch's own copy of this comment for why. --->
				<cfif application.imageEngineSupportsWebP>
					<cfset webpDestination = reReplaceNoCase(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType), "\.[^.]+$", ".webp")>
					<!--- imageWrite with a .webp file name, not <cfimage format="webp">: Lucee's cfimage tag only accepts gif, jpg, png, tiff and bmp for its format attribute even though Lucee writes WebP fine, so on Lucee this threw, the upload's cftry swallowed it, and every crop after the first (Twitter, Google, classic) was silently skipped (found in the 4.8 install test, 2026-10-11). A WebP copy that can't be written is skipped rather than stopping the other crops. --->
					<cftry>
						<cfset imageWrite(thisImage, webpDestination, arguments.quality, true)>
						<cfset fileSetAccessMode("#webpDestination#", "644")>
						<cfcatch type="any"></cfcatch>
					</cftry>
				</cfif>

			<cfelse>
				<!--- Handle portrait images --->
				
				<cfif imageDebug>
					<cfdump var="#cfimageData#">
					<cfoutput>#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#</cfoutput>
				</cfif>
					
				<!--- Determine the new width --->
				<cfif imageInfo.width gte thisImageWidth>
					<cfset newWidth = thisImageWidth>
				<cfelse>
					<cfset newWidth = imageInfo.width>
				</cfif>

				<!--- Determine the new size of the images while preserving the aspect ratio of 1200 x 630. --->
				<cfset newHeight = ratioCalculator(thisImageWidth, thisImageHeight, newWidth)>
				<!--- Crop the top and bottom of the original image from the center (horizontalCrop(path, originalHeight, newHeight, newWidth). --->
				<cfset thisImage = horizontalCrop(imagePath, imageInfo.height, newHeight, newWidth)>
				<!--- Ensure the destination directory exists - other Galaxie Blog installations (or a brand new
				platform folder like pinterest/classic on this one) may not have it pre-created. --->
				<cfset socialMediaDestinationDir = getDirectoryFromPath(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType))>
				<cfif not directoryExists(socialMediaDestinationDir)>
					<cfdirectory action="create" directory="#socialMediaDestinationDir#">
				</cfif>
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes" structName="cfimageData" quality="#arguments.quality#">
				<!--- And set permissions on Linux. This should set the following permissions: owner all, group read, other read --->
				<cfset fileSetAccessMode("#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#", "644")>
				<!--- Also write a webp companion, matching the master enclosure image's own jpg+webp convention - see
				the preCrop branch's own copy of this comment for why. --->
				<!--- Guarded: WebP write support is Lucee (2.0 image extension+) and ColdFusion 2025+ only - see the
				preCrop branch's own copy of this comment for why. --->
				<cfif application.imageEngineSupportsWebP>
					<cfset webpDestination = reReplaceNoCase(getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType), "\.[^.]+$", ".webp")>
					<!--- imageWrite with a .webp file name, not <cfimage format="webp">: Lucee's cfimage tag only accepts gif, jpg, png, tiff and bmp for its format attribute even though Lucee writes WebP fine, so on Lucee this threw, the upload's cftry swallowed it, and every crop after the first (Twitter, Google, classic) was silently skipped (found in the 4.8 install test, 2026-10-11). A WebP copy that can't be written is skipped rather than stopping the other crops. --->
					<cftry>
						<cfset imageWrite(thisImage, webpDestination, arguments.quality, true)>
						<cfset fileSetAccessMode("#webpDestination#", "644")>
						<cfcatch type="any"></cfcatch>
					</cftry>
				</cfif>

			</cfif>

		</cfif><!---<cfif socialMediaImageType contain 'link'>--->
			
		<cfreturn true>

	</cffunction>
				
	<cffunction name="getSocialMediaDestination" access="public" output="false" returnType="string" hint="Determines the destination to store the images for social media sharing.">
		<cfargument name="socialMediaImagePath" required="yes" hint="Specify the path of the original image.">
		<cfargument name="socialMediaPlatform" required="yes" hint="Specify the social media platform.">
		<cfargument name="socialMediaImageType" required="no" default="" hint="Required for google images as we are creating 3 types. Not used for the other social media platforms.">
		
		<cfif arguments.socialMediaPlatform neq 'google'>
			<cfset socialMediaDestination = replaceNoCase(arguments.socialMediaImagePath, 'enclosures\', 'enclosures\' & arguments.socialMediaPlatform & '\', 'all')>
		<cfelse>
			<!--- We either need to save the Google images to the 16_9, 4_3, or 1_1 folder. --->
			<cfif arguments.socialMediaImageType eq 'google16_9Image'>
				<cfset socialMediaDestination = replaceNoCase(arguments.socialMediaImagePath, 'enclosures\', 'enclosures\' & arguments.socialMediaPlatform & '\16_9\', 'all')>
			<cfelseif arguments.socialMediaImageType eq 'google4_3Image'>
				<cfset socialMediaDestination = replaceNoCase(arguments.socialMediaImagePath, 'enclosures\', 'enclosures\' & arguments.socialMediaPlatform & '\4_3\', 'all')>
			<cfelseif arguments.socialMediaImageType eq 'google1_1Image'>
				<cfset socialMediaDestination = replaceNoCase(arguments.socialMediaImagePath, 'enclosures\', 'enclosures\' & arguments.socialMediaPlatform & '\1_1\', 'all')>
			</cfif>
		</cfif>
		
		<cfreturn socialMediaDestination>
	</cffunction>
				
	<cffunction name="ratioCalculator" access="public" output="false" returnType="numeric" hint="This is used to determine the new dimensions needed to fit a certain width while maintaining the specified aspect ratio. I am using this to determine how to resize an image to meet the aspect ratio used by varius social media sites.">
		<cfargument name="aspectRatioWidth" required="yes" hint="Specify the original width of the image.">
		<cfargument name="aspectRatioHeight" required="yes" hint="Specify the original height of the image.">
		<cfargument name="newWidth" required="yes" hint="Specify the desired width of the new image.">
			
		<cfset newHeight = (arguments.aspectRatioHeight / arguments.aspectRatioWidth) * arguments.newWidth>
		
		<cfreturn newHeight>
	</cffunction>
			
	<cffunction name="centerCrop" access="public" output="false" returnType="string" hint="Used to crop an image with a desired size that is smaller both horizontally and vertically than the original image. This will crop the image from the center.">
		<cfargument name="imagePath" required="yes" hint="Provide either the full original path of the image, or the actual ColdFusion image using the newImage function.">
		<cfargument name="originalWidth" required="yes" hint="Provide the original width of the image.">
		<cfargument name="originalHeight" required="yes" hint="Provide the original width of the image.">
		<cfargument name="newWidth" required="yes" hint="Provide the desired width of the cropped image.">
		<cfargument name="newHeight" required="yes" hint="Provide the desired height of the new cropped image.">
		<!--- Local debugging carriage. If something goes awry, set this to true. --->
		<cfset debug = false>
		
		<!--- This algorithm was found at https://www.raymondcamden.com/2010/02/03/Cropping-to-the-center-of-an-image --->
		<cfset originalImage = "#arguments.imagePath#"> 
		<!--- Make a copy of the original image. --->
		<cfset croppedImage = imageNew(originalImage)> 
		<!--- Get the coordinates. We will subtract the orinal width minus the new width to grab the center of the new image.  --->
		<cfset xCoordinate = (originalWidth - newWidth) / 2>
		<cfset yCoordinate  = (originalHeight - newHeight) / 2>
			
		<cfif debug>
			<cfoutput>
				<b>CenterCrop:</b><br/>
				originalWidth: #originalWidth#<br/>
				originalHeight: #originalHeight#<br/>
				newWidth: #newWidth#<br/>
				newHeight: #newHeight#<br/>
				xCoordinate #xCoordinate#<br/> 
				yCoordinate" #yCoordinate#<br/>
			</cfoutput>
		</cfif>
			
		<!--- Crop the image if the new width and height are less than or equal to the original image. Was strict "gt"
		- silently returned nothing (leaving the caller's thisImage undefined) whenever the computed target exactly
		matched the source's own native size, eg. a small same-aspect-ratio source clamped down to its own size
		rather than genuinely cropped. A no-op "crop" (0,0 offset, full original dimensions) is still a valid result
		here, not an error. --->
		<cfif originalWidth gte newWidth and originalHeight gte newHeight>
			<cfset imageCrop(croppedImage, xCoordinate, yCoordinate, newWidth, newHeight)>
			<!--- And return it. --->
			<cfreturn croppedImage>
		</cfif>
			
	</cffunction>
			
	<cffunction name="horizontalCrop" access="public" output="false" returnType="string" hint="Used to crop a horizontal image that has a horizontally size that is greater than the desired size of the new image. This will crop the image from the horizontal center.">
		<cfargument name="imagePath" required="yes" hint="Provide the full original path of the image.">
		<cfargument name="originalHeight" required="yes" hint="Provide the original width of the image.">
		<cfargument name="newHeight" required="yes" hint="Provide the desired height of the new cropped image.">
		<cfargument name="newWidth" required="yes" hint="Provide the desired width of the new cropped image.">	
		<!--- Local debugging carriage. If something goes awry, set this to true. --->
		<cfset debug = false>
		
		<!--- This algorithm was found at https://www.raymondcamden.com/2010/02/03/Cropping-to-the-center-of-an-image --->
		<cfset originalImage = "#arguments.imagePath#"> 
		<!--- Make a copy of the original image. --->
		<cfset croppedImage = imageNew(originalImage)> 
		<!--- Get the coordinates. The x coordinate starts at 0. The image only needs to be cropped vertically.  --->
		<cfset xCoordinate = 0>
		<cfset yCoordinate  = (originalHeight - newHeight) / 2>
			
		<cfif debug>
			<cfoutput>
				originalHeight: #originalHeight#<br/>
				newHeight: #newHeight#<br/>
				newWidth: #newWidth#<br/>
				xCoordinate #xCoordinate#<br/> 
				yCoordinate" #yCoordinate#<br/>
			</cfoutput>
		</cfif>
			
		<!--- Try to crop the image. --->
		<cftry>
			<!--- Image crop is a native ColdFusion function. --->
			<cfset imageCrop(croppedImage, xCoordinate, yCoordinate, newWidth, newHeight)>
			<cfcatch type="any">
				<cfset error = "Aborted crop. Image is too small to crop.">
			</cfcatch>
		</cftry>
			
		<!--- And return it. --->
		<cfreturn croppedImage>
			
	</cffunction>

	<cffunction name="generateHeroArt" access="public" output="false" returntype="string"
			hint="Deterministic per-post gradient SVG for BlogOption.NoImageFallbackMode='generated' (and as the graceful fallback for 'pool' mode when the pool carousel has no items yet). Seeded off postId alone, never the title, so the art never changes when a post is edited. Generated once and written to disk as a static .svg - every call after the first is just a fileExists() check, not a re-generation.">
		<cfargument name="postId" type="numeric" required="yes">

		<cfset var kendoTheme = application.blog.getSelectedKendoTheme()>
		<cfset var destination = expandPath("#application.baseUrl#/images/heroArt")>
		<!--- 2026-10-01: the theme name is part of the cache filename (not just the postId) specifically so
		switching the site's Kendo theme naturally produces fresh on-theme art for every post instead of silently
		keeping stale colors from whatever theme was selected the first time a post's art was generated - no
		explicit cache-flush step needed, matching this project's "which cache file do I flush" being a
		recurring pain point elsewhere. Old themes' files just become harmlessly orphaned on disk. --->
		<!--- "-v2" (2026-10-09): bumped when grey-accent themes got vivid colors (see below), so art already
		generated as a flat grey box is replaced instead of reused. Bump again whenever the art itself changes. --->
		<cfset var filePath = destination & "/" & arguments.postId & "-" & kendoTheme & "-v2.svg">
		<cfset var publicUrl = application.baseUrl & "/images/heroArt/" & arguments.postId & "-" & kendoTheme & "-v2.svg">
		<cfset var svgContent = "">
		<cfset var colorPair = "">
		<cfset var angle = 0>
		<cfset var baseHue = "">
		<!--- 2026-10-01: replaces the earlier fixed 8-pair palette (hardcoded hex, unrelated to the live theme)
		with blog.cfc's getRotatedThemeColors()/getComplementaryColor() - each post gets a different hue rotated
		off the theme's own accentColor (java.awt.Color's RGBtoHSB/HSBtoRGB, confirmed live via
		TestUtility.cfc's testComplementaryColors()), paired with its computed complement, so generated art now
		actually matches whichever theme is selected instead of a generic palette. --->
		<cfset var rotatedColors = application.blog.getRotatedThemeColors(kendoTheme=kendoTheme, count=8)>

		<cfif fileExists(filePath)>
			<cfreturn publicUrl>
		</cfif>

		<!--- mode 755/644 (2026-10-09): on Linux, Lucee runs as root and some new files came out unreadable to
		Apache, which answered 403 Forbidden - two docs pages on galaxieblog.org showed a broken picture where this
		art belonged. Same fix getCachedMapThumbnail (Renderer.cfc) got for map previews. Ignored on Windows. --->
		<cfif not directoryExists(destination)>
			<cfdirectory action="create" directory="#destination#" mode="755">
		</cfif>

		<cfset baseHue = rotatedColors[(arguments.postId mod arrayLen(rotatedColors)) + 1]>
		<!--- 2026-10-09: a theme whose accent color is grey (Uniform's is #747474) has no hue to rotate, so every post
		came out as a flat grey box, and so did its complement. For those themes, pick a vivid color per post
		instead, spread around the color wheel by the golden ratio so neighboring posts don't look alike. Still
		seeded off postId alone, so a post's art never changes when it's edited. --->
		<cfset var javaColor = createObject("java", "java.awt.Color")>
		<cfset var baseRgb = javaColor.decode("##" & baseHue)>
		<cfset var baseHsb = javaColor.RGBtoHSB(baseRgb.getRed(), baseRgb.getGreen(), baseRgb.getBlue(), javaCast("null", ""))>
		<cfset var vividHue = 0>
		<cfif baseHsb[2] lt 0.2>
			<cfset vividHue = arguments.postId * 0.618033988749895>
			<cfset vividHue = vividHue - int(vividHue)>
			<cfset baseHue = right("000000" & formatBaseN(bitAnd(javaColor.HSBtoRGB(javaCast("float", vividHue), javaCast("float", 0.6), javaCast("float", 0.75)), 16777215), 16), 6)>
		</cfif>
		<cfset colorPair = ["##" & baseHue, "##" & application.blog.getComplementaryColor(baseHue)]>
		<cfset angle = (arguments.postId mod 8) * 45>

		<!--- 2026-10-01: gradientTransform="rotate(angle)" on the default objectBoundingBox gradient space
		rotates inside a 1x1 unit square *before* that square gets non-uniformly stretched to fit this rect's
		1200x630 (~1.9:1) aspect ratio - for several of the 8 angles that stretch squashes the visible gradient
		line almost entirely outside the box, rendering as a flat single color instead of a two-tone blend
		(confirmed live: angle 225/270 looked flat, 315 looked correct, same SVG markup before this fix, so it
		was the angle math, not the color choice). Fixed by computing the gradient line's actual endpoints in
		real pixel space (gradientUnits="userSpaceOnUse") instead of rotating in a space that gets stretched
		afterward - a line through the rect's center, long enough to clear the far corners regardless of angle. --->
		<cfset var angleRadians = angle * 3.14159265358979 / 180>
		<cfset var centerX = 600>
		<cfset var centerY = 315>
		<!--- Half the rect's diagonal (~677) rounded up, so the line's endpoints always land outside the
		visible box no matter which angle - stop colors still read as a clean edge-to-edge blend. --->
		<cfset var halfLineLength = 700>
		<cfset var lineDeltaX = cos(angleRadians) * halfLineLength>
		<cfset var lineDeltaY = sin(angleRadians) * halfLineLength>
		<cfset var gradientX1 = centerX - lineDeltaX>
		<cfset var gradientY1 = centerY - lineDeltaY>
		<cfset var gradientX2 = centerX + lineDeltaX>
		<cfset var gradientY2 = centerY + lineDeltaY>

		<cfsavecontent variable="svgContent"><cfoutput><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630"><defs><linearGradient id="g" gradientUnits="userSpaceOnUse" x1="#gradientX1#" y1="#gradientY1#" x2="#gradientX2#" y2="#gradientY2#"><stop offset="0%" stop-color="#colorPair[1]#"/><stop offset="100%" stop-color="#colorPair[2]#"/></linearGradient></defs><rect width="1200" height="630" fill="url(##g)"/></svg></cfoutput></cfsavecontent>

		<cffile action="write" file="#filePath#" output="#svgContent#" addnewline="false" mode="644">
		<cftry>
			<cfset fileSetAccessMode(filePath, "644")>
			<cfcatch type="any"><!--- Not supported on every platform (eg. Windows) - the file is still usable. ---></cfcatch>
		</cftry>

		<cfreturn publicUrl>

	</cffunction>

	<cffunction name="generateAnimationDefault" access="public" output="false" returntype="struct"
			hint="Deterministic per-post animation effect+color pick (currently Vanta.js) for
			BlogOption.NoImageFallbackMode='animation', used only when a post hasn't picked its own
			HeroAnimationEffect override and the global BlogOption.AnimationEffect default is also blank. Seeded
			off postId alone, same reasoning as generateHeroArt - never changes on an edit. Unlike
			generateHeroArt, there is nothing to pre-render/cache to disk: this is a live canvas, not a generated
			image, so this only returns which effect + which options to hand to VANTA.{effect}(...) client-side -
			see Renderer.cfc's renderHeroAnimationHtml() and head.cfm's galaxieLoader.heroAnimationEngine().
			2026-10-03: renamed from generateVantaDefault/'vanta'/HeroVantaEffect/VantaEffect while still
			dev-only/unmigrated.">
		<cfargument name="postId" type="numeric" required="yes">

		<!--- TOPOLOGY dropped 2026-09-30 - throws a constructor error on init regardless of Three.js revision, a
		real upstream bug in the vanta.js library for this one effect (confirmed against multiple Three.js
		builds; matches a multi-year history of the same class of issue in the library's own GitHub issues).
		BIRDS/FOG/CLOUDS2/GLOBE added 2026-10-03 - see heroAnimationEditor.cfm's header comment for the same
		verification method and GLOBE's NET-like animation caveat. --->
		<cfset var effects = ["WAVES","NET","RINGS","CLOUDS","BIRDS","FOG","CLOUDS2","GLOBE"]>
		<!--- One curated color (or color pair, for the two-tone effects) per palette slot - same "looks good
		together" curation intent as generateHeroArt's palette, not random RGB values that can clash. --->
		<cfset var palette = [
			{color: "##4facfe", backgroundColor: "##0f2027"},
			{color: "##43e97b", backgroundColor: "##1a2a3a"},
			{color: "##fa709a", backgroundColor: "##2d1b3a"},
			{color: "##30cfd0", backgroundColor: "##0b132b"},
			{color: "##a18cd1", backgroundColor: "##1e1a33"},
			{color: "##ff9a9e", backgroundColor: "##2b1b24"},
			{color: "##5ee7df", backgroundColor: "##11221f"},
			{color: "##f6d365", backgroundColor: "##2a2313"}
		]>
		<cfset var chosenEffect = effects[(arguments.postId mod arrayLen(effects)) + 1]>
		<cfset var chosenColors = palette[(arguments.postId mod arrayLen(palette)) + 1]>
		<cfset var options = {}>

		<!--- 2026-10-03: real, confirmed-per-effect option shapes (verified against both the vendored
		vanta.*.min.js source and the live vantajs.com customizer - an earlier guess here had WAVES taking a
		backgroundColor it doesn't support at all, and CLOUDS taking sky/cloud/sun keys that don't match this
		library's real names). WAVES only takes "color" - no background concept exists for it. RINGS takes only
		"backgroundColor" - its own ring colors are generated internally, not a settable option. CLOUDS is a
		7-color sky/sun scene that doesn't suit per-post palette variation the way a simple 2-tone background
		does, so this uses Vanta's own documented defaults directly rather than trying to derive 7 colors from a
		2-color palette slot. --->
		<cfif chosenEffect eq "CLOUDS">
			<cfset options = {backgroundColor: "##ffffff", skyColor: "##68b8d7", cloudColor: "##adc1de", cloudShadowColor: "##183550", sunColor: "##ff9919", sunGlareColor: "##ff6633", sunlightColor: "##ff9933"}>
		<cfelseif chosenEffect eq "WAVES">
			<cfset options = {color: chosenColors.color}>
		<cfelseif chosenEffect eq "RINGS">
			<cfset options = {backgroundColor: chosenColors.backgroundColor}>
		<cfelseif chosenEffect eq "BIRDS">
			<!--- colorMode intentionally omitted - never part of any saved/generated options struct, always
			hardcoded at the render boot script level (tailEndScripts.cfm/preview/heroAnimation.cfm) instead, same
			reasoning as heroAnimationEditor.cfm's applyEffectSpecificVantaOptions(). --->
			<cfset options = {backgroundColor: "##07192f", color1: "##ff0000", color2: "##00d1ff"}>
		<cfelseif chosenEffect eq "FOG">
			<cfset options = {baseColor: "##ffebeb", highlightColor: "##ffc300", lowlightColor: "##2d00ff", midtoneColor: "##ff1f00"}>
		<cfelseif chosenEffect eq "CLOUDS2">
			<!--- texturePath intentionally omitted - always hardcoded to the vendored noise.png's real absolute
			URL at the render boot script level, same reasoning as colorMode above. --->
			<cfset options = {backgroundColor: "##000000", cloudColor: "##334d80", lightColor: "##ffffff", skyColor: "##5ca6ca"}>
		<cfelseif chosenEffect eq "GLOBE">
			<cfset options = {color: chosenColors.color, color2: "##ffffff", backgroundColor: chosenColors.backgroundColor}>
		<cfelse><!--- NET --->
			<cfset options = {color: chosenColors.color, backgroundColor: chosenColors.backgroundColor}>
		</cfif>

		<cfreturn {effect: chosenEffect, options: options}>
	</cffunction>

</cfcomponent>
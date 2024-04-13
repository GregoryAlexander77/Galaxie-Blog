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
		</cfswitch>
				
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
			
	<cffunction name="createThumbnail" access="public" output="true" returntype="string" hint="Creates thumbnail images 235 width by 138. These are used in the administrative interface as well as used for gallery thumbnail images when creating a gallery.">
		<cfargument name="imagePath" type="string" required="yes" hint="Provide the path to the image.">
		<cfargument name="imageName" type="string" required="yes" hint="The image name.">
			
		<cfset debug = false>
			
		<cfset thumbNailWidth = "235">
		<cfset thumbNailHeight = "138">
			
		<!--- Set our final destination (#application.baseUrl#\enclosures\thumbnails). --->
		<cfset destination = expandPath("#application.baseUrl#\enclosures\thumbnails")>
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
		
		<cfreturn destination>
		
	</cffunction>
			
	<cffunction name="createSocialMediaImages" access="public" output="true" returntype="any" hint="Creates images for social media sharing.">
		<cfargument name="imagePath" type="string" required="yes" hint="Provide the path to the image.">
		<cfargument name="socialMediaPlatform" type="string" required="yes" hint="Provide the social media platform. The valid arguments are: facebook, twitter, instagram, linkedIn, and google. Logic will determine the best size for the image to fit the platform's image share specification.">
		<cfargument name="socialMediaImageType" type="string" required="no" default="" hint="Unless you're trying to create Google images, this argument is optional in order to over-ride the default logic and force the type of image format that you want. If you specify this argument, it will over-ride the socialMediaPlatform argument. Logic will still be used to see if the images are valid for the large image types and substitute smaller images when necessary. Valid arguments are: facebookSharedImage, facebookLinkSquareImage, facebookLinkRectangleImage, twitterInstreamImage, twitterInstreamMinimumImage, instagramImage, instagramMinimumImage, linkedInImage, linkedInMinimumImage, google16_9Image, google4_3Image, and google1_1Image. This argument must be present when creating google images.">
		
		<!--- Set output to true when debugging --->
		<cfset imageDebug = false>
			
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
		</cfswitch>
				
		<!--- Before we proceed, make one final check to see if the larger facebook or twitter images are really big and determine if we should crop them too. In my testing, I uploaded large images that were 4032 pixels in width and the center cropped image only got a tiny portion of the original image. Here we are checking to see if the image is twice as large as the final image that we want to crop to- if it is, we're going to pre-crop these large images too. --->
		<cfif (thisImageWidth * 2) gte facebookSharedImageWidth>
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
				<cfelseif socialMediaImageType eq 'facebookSharedImage' or socialMediaImageType eq 'twitterInstreamImageWidth'>
					<!--- Both the facebook and twitter large images are at 1200 wide. We need to crop it at 1500 in case if it is a portrait image --->
					<cfset preCropSize = 1500>	
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
			
				<!--- Write the image --->
				<cfimage source="#shareImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes">
				
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
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes" structName="cfimageData">

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
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes" structName="cfimageData">

			</cfif>
				
		</cfif><!---<cfif socialMediaImageType contain 'link'>--->
			
		<cfreturn true>

	</cffunction>
				
	<cffunction name="getSocialMediaDestination" access="public" output="true" returnType="string" hint="Determines the destination to store the images for social media sharing.">
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
				
	<cffunction name="ratioCalculator" access="public" output="true" returnType="numeric" hint="This is used to determine the new dimensions needed to fit a certain width while maintaining the specified aspect ratio. I am using this to determine how to resize an image to meet the aspect ratio used by varius social media sites.">
		<cfargument name="aspectRatioWidth" required="yes" hint="Specify the original width of the image.">
		<cfargument name="aspectRatioHeight" required="yes" hint="Specify the original height of the image.">
		<cfargument name="newWidth" required="yes" hint="Specify the desired width of the new image.">
			
		<cfset newHeight = (arguments.aspectRatioHeight / arguments.aspectRatioWidth) * arguments.newWidth>
		
		<cfreturn newHeight>
	</cffunction>
			
	<cffunction name="centerCrop" access="public" output="true" returnType="string" hint="Used to crop an image with a desired size that is smaller both horizontally and vertically than the original image. This will crop the image from the center.">
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
			
		<!--- Crop the image if the new width and heighth are less than the original image. --->
		<cfif originalWidth gt newWidth and originalHeight gt newHeight>
			<cfset imageCrop(croppedImage, xCoordinate, yCoordinate, newWidth, newHeight)> 
			<!--- And return it. --->
			<cfreturn croppedImage>
		</cfif>
			
	</cffunction>
			
	<cffunction name="horizontalCrop" access="public" output="true" returnType="string" hint="Used to crop a horizontal image that has a horizontally size that is greater than the desired size of the new image. This will crop the image from the horizontal center.">
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
						
</cfcomponent>
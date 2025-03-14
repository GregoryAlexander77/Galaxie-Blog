<!---
	More information can be found at: https://gregoryalexander.com/blog/2019/11/1/How-to-make-the-perfect-social-media-sharing-image--part-3-Using-ColdFusion-to-generate-the-image-

	Example Usage:
			
	<cfset socialMediaImagePath = "D:\home\gregoryalexander.com\wwwroot\blog\enclosures\aspectRatio1.jpg">

	<cfset createSocialMediaImages(socialMediaImagePath, 'facebook', '')>
	<cfset createSocialMediaImages(socialMediaImagePath, 'twitter', '')>
	<cfset createSocialMediaImages(socialMediaImagePath, 'instagram', '')>
	<cfset createSocialMediaImages(socialMediaImagePath, 'linkedIn', '')>
	--->
	
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
			
	<cffunction name="createSocialMediaImages" access="public" output="false" returntype="string" hint="Creates images for social media sharing.">
		<cfargument name="imagePath" type="string" required="yes" hint="Provide the path to the image.">
		<cfargument name="socialMediaPlatform" type="string" required="yes" hint="Provide the social media platform. The valid arguments are: facebook, twitter, instagram, linkedIn, and google. Logic will determine the best size for the image to fit the platform's image share specification.">
		<cfargument name="socialMediaImageType" type="string" required="no" default="" hint="Unless you're trying to create Google images, this argument is optional in order to over-ride the default logic and force the type of image format that you want. If you specify this argument, it will over-ride the socialMediaPlatform argument. Logic will still be used to see if the images are valid for the large image types and substitute smaller images when necessary. Valid arguments are: facebookSharedImage, facebookLinkSquareImage, facebookLinkRectangleImage, twitterInstreamImage, twitterInstreamMinimumImage, instagramImage, instagramMinimumImage, linkedInImage, linkedInMinimumImage, google16_9Image, google4_3Image, and google1_1Image. This argument must be present when creating google images.">
			
		<cfset debug = true>
			
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
			source = "#socialMediaImagePath#"
			structname="imageInfo">
			
		<cfif debug>Original image width: <cfoutput>#imageInfo.width# height: #imageInfo.height#</cfoutput><br/></cfif>
			
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
				
		<cfif debug><cfoutput>socialMediaImageType: #socialMediaImageType# thisImageWidth: #thisImageWidth# thisImageHeight: #thisImageHeight#</cfoutput><br/></cfif>

		<!--- Handle small image formats- facebook squares and rectangles, the twitter and instagram minimum images, and really large images. We will pre-crop these images to get a larger part of the image, and then crop it again in the center. --->
		<cfif preCrop>

			<!--- Create a new image --->
			<cfset shareImage = imageNew(socialMediaImagePath)>
					
			<!--- Handle small images. --->
			<!--- This logic is only invoked for Facebook rectangle links. --->
			<cfif socialMediaImageType eq 'facebookLinkRectangleImage'>
				
				<!--- Resize the new image. For portrait images, we are going to resize the image to 550 pixels wide. --->
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
				<!--- We are going to resize the new image to the precrop size and then crop it again. I want extra space to make sure that it fits our target size. We are putting in a blank argument for the height in order to keep the aspect ratio of the original image. --->
				<cfset imageResize(shareImage, preCropSize, '')>
				<!--- We know the width of the new image that was just created (250), now get its height --->
				<cfset shareImageHeight = imageGetHeight(shareImage)>
				<!--- Crop the resized image from the center (centerCrop(path/image, originalWidth, originalHeight, newWidth, newHeight). We don't need to determine an aspect ratio. It is a square. --->
				<cfset shareImage = centerCrop(shareImage, preCropSize, shareImageHeight, thisImageWidth, thisImageHeight)>
				
			</cfif><!---<cfif (socialMediaImageType eq 'facebookLinkRectangleImage'>--->

			<!--- Save the modified image to a file. --->
			<cfimage source="#shareImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes">
			
			<cfif debug><cfoutput>#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#</cfoutput></cfif>
			
		<cfelse><!---<cfif socialMediaImageType contain 'link'>--->
			
			<!--- Handle landscape images. --->
			<cfif getImageOrientation(socialMediaImagePath) eq 'landscape'>

				<!--- Determine the new width --->
				<cfif imageInfo.width gte thisImageWidth>
					<cfset newWidth = thisImageWidth>
				<cfelse>
					<cfset newWidth = imageInfo.width>
				</cfif>

				<!--- Determine the new height of the images while preserving the aspect ratio of 1200 x 630. --->
				<cfset newHeight = ratioCalculator(thisImageWidth, thisImageHeight, newWidth)>

				<!--- Create a new image --->
				<cfset thisImage = imageNew(socialMediaImagePath)>
				<!--- Crop the image from the center (centerCrop(path, originalWidth, originalHeight, newWidth, newHeight)) --->
				<cfset thisImage = centerCrop(socialMediaImagePath, imageInfo.width, imageInfo.height, newWidth, newHeight)>
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes">
				
				<cfif debug><cfoutput>#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#</cfoutput></cfif>

			<cfelse>
				<!--- Handle portrait images --->

				<!--- Determine the new width --->
				<cfif imageInfo.width gte thisImageWidth>
					<cfset newWidth = thisImageWidth>
				<cfelse>
					<cfset newWidth = imageInfo.width>
				</cfif>

				<!--- Determine the new size of the images while preserving the aspect ratio of 1200 x 630. --->
				<cfset newHeight = ratioCalculator(thisImageWidth, thisImageHeight, newWidth)>
				<!--- Crop the top and bottom of the original image from the center (horizontalCrop(path, originalHeight, newHeight). --->
				<cfset thisImage = horizontalCrop(socialMediaImagePath, "#imageInfo.height#","#newHeight#")>
				<!--- Save the modified image to a file. --->
				<cfimage source="#thisImage#" action="write" destination="#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#" overwrite="yes">
				
				<cfif debug><cfoutput>#getSocialMediaDestination(imagePath, arguments.socialMediaPlatform, socialMediaImageType)#</cfoutput></cfif>

			</cfif>
				
		</cfif><!---<cfif socialMediaImageType contain 'link'>--->
			
		<cfreturn "success">

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
		<cfset debug = true>
		
		<!--- This algorithm was found at https://www.raymondcamden.com/2010/02/03/Cropping-to-the-center-of-an-image --->
		<cfset originalImage = "#arguments.imagePath#"> 
		<!--- Make a copy of the original image. --->
		<cfset croppedImage = imageNew(originalImage)> 
		<!--- Get the coordinates. We will subtract the orinal width minus the new width to grab the center of the new image.  --->
		<cfset xCoordinate = (originalWidth - newWidth) / 2>
		<cfset yCoordinate  = (originalHeight - newHeight) / 2>
			
		<cfif debug>
			<cfoutput>
				originalWidth: #originalWidth#<br/>
				originalHeight: #originalHeight#<br/>
				newWidth: #newWidth#<br/>
				newHeight: #newHeight#<br/>
				xCoordinate #xCoordinate#<br/> 
				yCoordinate" #yCoordinate#<br/>
			</cfoutput>
		</cfif>
			
		<!--- Crop the image. --->
		<cfset imageCrop(croppedImage, xCoordinate, yCoordinate, newWidth, newHeight)> 
			
		<!--- And return it. --->
		<cfreturn croppedImage>
	</cffunction>
			
	<cffunction name="horizontalCrop" access="public" output="false" returnType="string" hint="Used to crop a horizontal image that has a horizontally size that is greater than the desired size of the new image. This will crop the image from the horizontal center.">
		<cfargument name="imagePath" required="yes" hint="Provide the full original path of the image.">
		<cfargument name="originalHeight" required="yes" hint="Provide the original width of the image.">
		<cfargument name="newHeight" required="yes" hint="Provide the desired height of the new cropped image.">
		<!--- Local debugging carriage. If something goes awry, set this to true. --->
		<cfset debug = true>
		
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
				xCoordinate #xCoordinate#<br/> 
				yCoordinate" #yCoordinate#<br/>
			</cfoutput>
		</cfif>
			
		<!--- Crop the image. --->
		<cfset imageCrop(croppedImage, xCoordinate, yCoordinate, newWidth, newHeight)>
			
		<!--- And return it. --->
		<cfreturn croppedImage>
			
	</cffunction>
			
<!---facebookSharedImage, facebookLinkSquareImage, facebookLinkRectangleImage, twitterInstreamImage, twitterInstreamMinimumImage, instagramImage, instagramMinimumImage, linkedInImage, and linkedInMinimumImage.--->
			
<cfset socialMediaImagePath = "D:\home\gregoryalexander.com\wwwroot\blog\enclosures\delicateArch.jpg">
<!--- createSocialMediaImages(socialMediaImagePath, socialMediaImageType) --->	
<cfset createSocialMediaImages(socialMediaImagePath, 'facebook', '')>
<cfset createSocialMediaImages(socialMediaImagePath, 'twitter', '')>
<!---<cfset createSocialMediaImages(socialMediaImagePath, 'instagram', '')>
<cfset createSocialMediaImages(socialMediaImagePath, 'linkedIn', '')>--->
<cfset createSocialMediaImages(socialMediaImagePath, 'google', 'google16_9Image')>
<cfset createSocialMediaImages(socialMediaImagePath, 'google', 'google4_3Image')>
<cfset createSocialMediaImages(socialMediaImagePath, 'google', 'google1_1Image')>
	
<cfset enclosureUrl = application.rootUrl & "/enclosures/">
<cfset enclosurePath = expandPath("/enclosures")>
	
<cfoutput>enclosurePath: #enclosurePath#</cfoutput>


	

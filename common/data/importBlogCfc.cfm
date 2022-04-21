<!--- Don't allow anyone who is not authorized to consume this page as it may overwrite current data. --->
<cfif application.Udf.isLoggedIn() and find('EditServerSetting', session.capabilityList)>

	<!---<cfsilent>--->
	<!--- This is consumed from the Application.cfm template after ORM creates the initial database. --->

	<!--- Setting this to true will delete data from the tables and reseed the index. Only use in development. This only works with SQL Server. I may use ORM's truncate statement if this causes any issues. --->
	<cfset resetTables = false>
	<cfset tablesToPopulate = 'all'><!---all--->
	<cfset dsn = ''>
	<cfif dsn eq ''>
		<p>Please type in the DSN at the top of this template.</p>
		<cfabort>
	</cfif>
	<cfset debug = false>

	<!--- What is the directory of the blogCfc data files? --->
	<cfset dir = expandPath( "../../" ) & "common\data\files\blogCfcImport\" />
	

	<!--- See if the files exist. --->
	<cfif not fileExists(dir & "getBlogCfcCategories.txt")>
		<p>Please run the generateBlogCfcDateFiles.cfm template to generate the necessary WDDX files and upload them to the <cfoutput>#application.baseUrl#</cfoutput>/common/data/files/blogCfcImport directory.</p>
	<cfelse>

		<!---<cffile action="read" file="#dir##fileName#" variable="QueryObj">--->


		<!--- Let's insert the data. First we need to populate the database. --->

		<!--- ******************************************************************************************
			Categories
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Category' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<!--- Delete post category lookup first --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM PostCategoryLookup;
					DBCC CHECKIDENT ('[PostCategoryLookup]', RESEED, 0);
				</cfquery>
				
				<!--- Now delete the categories --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM Category;
					DBCC CHECKIDENT ('[Category]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcCategories.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcCategories">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcCategories">
				<!--- Save the category. This function will not insert duplicate categories. --->
				<cfinvoke component="#application.blog#" method="saveCategory" returnvariable="categoryId">
					<cfinvokeargument name="categoryUuid" value="#categoryid#">
					<cfinvokeargument name="category" value="#categoryname#">
				</cfinvoke>
			</cfoutput>

			<cfif debug><cfdump var="#getBlogCfcCategories#"></cfif>

		</cfif>	

		<!---****************************************************************************************
		Posts
		*****************************************************************************************--->

		<cfif tablesToPopulate eq 'Post' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<!--- Delete comments first --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM Comment;
					DBCC CHECKIDENT ('[Comment]', RESEED, 0);
				</cfquery>
				
				<!--- Delete related posts --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM RelatedPost;
					DBCC CHECKIDENT ('[RelatedPost]', RESEED, 0);
				</cfquery>
				
				<!--- Delete Post Media --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM PostMedia;
					DBCC CHECKIDENT ('[PostMedia]', RESEED, 0);
				</cfquery>
				
				<!--- Now delete the post --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM Post;
					DBCC CHECKIDENT ('[Post]', RESEED, 0);
				</cfquery>
				
				<!--- Delete Media --->
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM Media;
					DBCC CHECKIDENT ('[Media]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcPosts.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcPosts">

			<!--- Get the base template path and remove the common\data\, then append the enclosure folder --->
			<cfset newEnclosurePath = getDirectoryFromPath( replaceNoCase( getBaseTemplatePath(), "common\data\", "" ) ) & "enclosures\">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcPosts"><!---startRow="1" maxRows="10"--->
				<!--- Debugging
				Processing record #currentRow#<br/>
				id: #id#<br/>
				title: #title#<br/>
				enclosure: #enclosure#<br/>
				--->
				<!--- Invoke the insertNewPost function. This will return the new postId --->
				<cfinvoke component="#application.blog#" method="insertNewPost" returnvariable="postId">
					<cfinvokeargument name="postUuid" value="#id#">
					<cfinvokeargument name="author" value="1">
					<cfinvokeargument name="title" value="#title#">
					<cfinvokeargument name="description" value="#left(body, 125)#">
					<cfinvokeargument name="datePosted" value="#dateFormat(posted, 'medium')#">
					<cfinvokeargument name="timePosted" value="#timeFormat(posted, 'medium' )#">
				</cfinvoke>
				<!---new postId: #postId#<br/>--->

				<!--- Now that the new post was made, update the mediaUrl if there is an enclosure --->
				<!--- Get the image from the path. We are going to remove the oldEnclosurePath from the enclosure --->
				<cfset imageName = listLast(getBlogCfcPosts.enclosure[currentRow], '\')>
				<!--- Get rid of the '/enclosures' if it exists --->
				<cfset imageName = replaceNoCase(imageName, 'enclosures/', '')>
				<cfset newImageUrl = application.baseUrl & "/enclosures/">
				<cfset newImagePath = expandPath(newImageUrl)>
				<!---#enclosure#<br/> #imageName#<br/>#newImageUrl#<br/> #newImagePath#<br/>--->

				<!--- See if the media already exists. This will return a numeric value of the mediaId. If it does not exist, it will return a 0 --->
				<cfinvoke component="#application.blog#" method="getPostEnclosureMediaIdByUrl" returnvariable="mediaId">
					<cfinvokeargument name="postId" value="#postId#">
					<cfinvokeargument name="mediaUrl" value="#newImageUrl##imageName#">
				</cfinvoke>

				<cfif mediaId gt 0>
					<!--- update the record. --->
					<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
						<cfinvokeargument name="mediaId" value="#mediaId#" />
						<cfinvokeargument name="postId" value="#postId#" />
						<cfinvokeargument name="mediaPath" value="#newImagePath##imageName#" />
						<cfinvokeargument name="mediaUrl" value="#newImageUrl##imageName#" />
						<cfinvokeargument name="mediaType" value="image" />
						<!--- The mime type may not be available --->
						<cfif len(mimeType)>
							<cfinvokeargument name="mimeType" value="#mimeType#" />
						</cfif>
						<cfinvokeargument name="enclosure" value="true" />
					</cfinvoke>
				<cfelse><!---<cfif mediaId gt 0>--->
					<!--- Insert the record to the database. --->
					<cfinvoke component="#application.blog#" method="insertMediaRecord" returnvariable="mediaId">
						<cfinvokeargument name="postId" value="#postId#" />
						<cfinvokeargument name="mediaPath" value="#newImagePath##imageName#" />
						<cfinvokeargument name="mediaUrl" value="#newImageUrl##imageName#" />
						<cfinvokeargument name="mediaType" value="image" />
						<!--- The mime type may not be available --->
						<cfif len(mimeType)>
							<cfinvokeargument name="mimeType" value="#mimeType#" />
						</cfif>
						<cfinvokeargument name="enclosure" value="true" />
					</cfinvoke>
				</cfif><!---<cfif mediaId gt 0>--->

				<!---****************************************************************************************
				Inspect and modify the post content.
				*****************************************************************************************--->

				<!--- Include our objects to manipulate strings --->
				<cfobject component="#application.jsoupComponentPath#" name="JSoupObj">
				<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">

				<!--- Handle the code issues from previous versions. We need to put a script and pre tags around the code tags when importing. --->
				<cfset newBody = body>

				<!--- Grab the keywords that may be present in the post. --->
				<cfset xmlKeywords = application.blog.inspectPostContentForXmlKeywords(newBody)>
				<!---xmlKeywords: #xmlKeywords#<br/>--->

				<!--- See if the description is set in the body with a keyword --->
				<cfif findNoCase("titleMetaTag", xmlKeywords) gt 0> 
					<!--- Overwrite the title variable. --->
					<cfset title = application.blog.getXmlKeywordValue(newBody, 'titleMetaTag')>
					<!--- Sanitize the string --->
					<cfinvoke component="#application.jsoupComponentPath#" method="jsoupConvertHtmlToText2" returnvariable="title">
						<cfinvokeargument name="html" value="#title#">
					</cfinvoke>
					<!---title: #title#<br/>--->
					<!--- Remove it from the body --->
					<cfset newBody = StringUtilsObj.removeXmlDirective(str=newBody, xmlDirective='titleMetaTag')>
				</cfif>

				<cfif findNoCase("descMetaTag", xmlKeywords) gt 0> 
					<!--- Set the desc variable. --->
					<cfset desc = application.blog.getXmlKeywordValue(newBody, 'descMetaTag')>
					<!--- Sanitize the string --->
					<cfset desc = JSoupObj.jsoupConvertHtmlToText2(desc)>
					<!--- Now that we have gotten the description from the body- delete it. It is no longer used in this version --->
					<cfset newBody = StringUtilsObj.removeXmlDirective(str=newBody, xmlDirective='descMetaTag')>
				<cfelse>
					<!--- Grab the first few sentences from the body --->
					<cfset desc = left(body, 125)>
				</cfif>	

				<!--- Remove Galaxie Blogs 1x LD Json string --->
				<cfif newBody contains 'application/ld+json'>
					<!--- Include the string utilities cfc. --->
					<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
					<!--- Remove the ld+json --->
					<cfset newBody = StringUtilsObj.replaceStringInContent(newBody, '<script type="application/ld+json">', '</script>')>
					<cfset newBody = StringUtilsObj.replaceStringInContent(newBody, '<attachScript type="application/ld+json">', '</attachScript>')>
				</cfif>

				<!--- Get the scripts and save them as the header and then remove them --->
				<cfif newBody contains 'attachScript'>
					<!--- Get the scripts --->
					<cfset getPostHeader = JSoupObj.getTagFromPost(post=newBody, tag='attachScript')>
					<!--- *Don't* remove attachScripts from body. I want them to remain here for now. --->
					<cfset newBody = StringUtilsObj.removeXmlDirective(str=newBody, xmlDirective='attachScript')>
				</cfif>

				<!--- If the postData tag is empty, get rid of them --->
				<cfset postDataContent = JSoupObj.getTagFromPost(post=newBody, tag="postData")>
				<cfif not len(postDataContent)>
					<!--- Remove the XML and google structured content from the post between the postData tag --->
					<cfset newBody = StringUtilsObj.removeTag(str=newBody, tag='postData')>
				</cfif>

				<!--- Add pretags and a script tag for proper PrismJs highlighting. We must to this at the end of other xml directive logic as Jsoup will reformat the code! --->
				<cfif findNoCase('<code>', newBody) and findNoCase('</code>', newBody)>
					<!--- Render the pretags around the code blocks --->
					<cfset newBody = RendererObj.renderPreTagsForPrism(newBody)>
					<!--- Remove the opening and closing tags between the code blocks --->
					<cfset newBody = RendererObj.renderCodeForPrism(newBody)>
				</cfif>

				<!---****************************************************************************************
				Update the post with the rest of the post data.
				*****************************************************************************************--->

				<cfinvoke component="#application.blog#" method="savePost" returnvariable="postId">
					<cfinvokeargument name="postId" value="#postId#">
					<cfinvokeargument name="postUuid" value="#id#">
					<cfinvokeargument name="author" value="1">
					<cfinvokeargument name="title" value="#title#">
					<cfinvokeargument name="description" value="#desc#">
					<!---<cfinvokeargument name="jsonLd" value="#jsonLd#">
					<cfinvokeargument name="postHeader" value="#getPostHeader#">--->
					<cfinvokeargument name="post" value="#newBody#">
					<cfinvokeargument name="datePosted" value="#dateFormat(posted, 'medium')#">
					<cfinvokeargument name="timePosted" value="#timeFormat(posted, 'medium' )#">
					<cfinvokeargument name="mediaId" value="#mediaId#">
					<cfinvokeargument name="numViews" value="#views#">
					<cfinvokeargument name="released" value="#released#">
					<cfinvokeargument name="emailSubscriber" value="false">
				</cfinvoke>

				<!---****************************************************************************************
				Populate the LD JSON
				*****************************************************************************************--->

				<!--- Instantiate our renderer obj --->
				<cfobject component="#application.rendererComponentPath#" name="RendererObj">

				<!--- Get the post by the postId --->
				<cfset getPost = application.blog.getPostByPostId(postId)>
				<!--- Render the JsonLD --->
				<cfset jsonLd = RendererObj.renderLdJson(getPost, true)>

				<!--- Save it --->
				<cfinvoke component="#application.blog#" method="saveJsonLd" returnvariable="postId">
					<cfinvokeargument name="postId" value="#postId#" />
					<cfinvokeargument name="jsonLd" value="#jsonLd#" />
				</cfinvoke>
			</cfoutput>

			<cfif debug><cfdump var="#getBlogCfcPosts#"></cfif>

		</cfif>	

		<!---****************************************************************************************
		Related Posts
		*****************************************************************************************--->

		<cfif tablesToPopulate eq 'RelatedPost' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<!--- The related post records were deleted when deleting posts. --->
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcRelatedPosts.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcRelatedPosts">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcRelatedPosts"> <!---maxrows="10"--->
				<!--- Get the post by the postId --->
				<cfset getPost = application.blog.getPostByPostUuid(entryid)>
				<!--- Get the related post --->
				<cfset getRelatedPost = application.blog.getPostByPostUuid(relatedid)>
				<cfif arrayLen(getPost) and arrayLen(getRelatedPost)>
					<!--- Save the related posts --->
					<!---postId: #getPost[1]["PostId"]# relatedPostId: #getRelatedPost[1]["PostId"]#<br/>--->
					<cfset saveRelatedPost = application.blog.saveRelatedPost(postId=getPost[1]["PostId"], relatedPostId=getRelatedPost[1]["PostId"])>
					<!---saveRelatedPost: #saveRelatedPost#<br/>--->
				</cfif>
			</cfoutput>

			<cfif debug><cfdump var="#getBlogCfcRelatedPosts#"></cfif>

		</cfif>	

		<!---****************************************************************************************
		Post Categories
		*****************************************************************************************--->

		<cfif tablesToPopulate eq 'PostCategory' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<!--- The post category lookup table has already been deleted prior to deleting the category records. --->
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcPostCategories.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcPostCategories">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcPostCategories"> <!---maxrows="10"--->
				<!--- Get the post by the postId --->
				<cfset getPost = application.blog.getPostByPostUuid(entryidfk)>
				<!--- Get the category --->
				<cfset getCategory = application.blog.getCategory(categoryUuid=categoryidfk)>

				<cfif arrayLen(getPost) and arrayLen(getCategory)>
					<!--- We need to get all of the categories in the array --->
					<cfloop from="1" to="#arrayLen(getCategory)#" index="i">
						<!--- Assign the category to the post --->
						<cfset assignCategoryToPost = application.blog.assignCategory(postId=getPost[1]["PostId"], categoryId=getCategory[i]["CategoryId"])>
					</cfloop>			
				</cfif>
			</cfoutput>

			<cfif debug><cfdump var="#getBlogCfcPostCategories#"></cfif>

		</cfif>	

		<!---****************************************************************************************
		Comments
		*****************************************************************************************--->

		<cfif tablesToPopulate eq 'Comment' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<!--- The comment table was deleted in the post logic. --->
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcPostComments.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcPostComments">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcPostComments">
				<!---dateTimeFormat(posted, 'medium'): #dateTimeFormat(posted, 'medium')#<br/>--->
				<!--- Get the postId --->
				<cfset postId = getPostIdByUuiId(entryidfk)>
				<!--- Convert the posted date to a SQL Server date time --->
				<cfset datePosted = dateTimeFormat(posted, 'medium')>
				<!--- See if the comment exists. This gets the comment to the millisecond. --->
				<cfset getComment = application.blog.getCommentByDate(datePosted=datePosted)>

				<cfif not arrayLen(getComment)>
					<!--- Save the comment --->
					<cfinvoke component="#application.blog#" method="addComment" returnvariable="addComment">
						<cfinvokeargument name="postId" value="#postId#">
						<cfinvokeargument name="name" value="#name#">
						<cfinvokeargument name="email" value="#email#">
						<cfinvokeargument name="website" value="#website#">
						<cfinvokeargument name="comments" value="#comment#">
						<cfinvokeargument name="subscribe" value="false">
						<cfinvokeargument name="overrideModeration"  value="true">
						<cfinvokeargument name="sendEmail"  value="false">
						<cfinvokeargument name="datePosted"  value="#posted#">
					</cfinvoke>
				</cfif>
			</cfoutput>

			<cfif debug><cfdump var="#getBlogCfcPostComments#"></cfif>

		</cfif>	

		<!---****************************************************************************************
		Subscribers
		*****************************************************************************************--->

		<cfif tablesToPopulate eq 'Subscriber' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset" datasource="#dsn#">
					DELETE FROM Subscriber;
					DBCC CHECKIDENT ('[Subscriber]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogCfcSubscribers.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "getBlogCfcSubscribers">

			<!--- Loop through the data --->
			<cfoutput query="getBlogCfcSubscribers">
				<!--- Add the subscribers. --->
			<cfset addSubscriber = application.blog.addSubscriber(email=#email#)>
			</cfoutput>

			<cfif debug><cfdump var="#Data#"></cfif>

		</cfif>	

		<p>Data import complete.</p>

	</cfif>
				
</cfif>
	
<!---****************************************************************************************
Helper functions
*****************************************************************************************--->	
	
<!--- Post functions --->
<cffunction name="getPostIdByUuiId" returntype="string" output="true"
		hint="Gets the post title by the post.id">
	<cfargument name="postUuid" type="string" required="yes" hint="Pass in the BlogCfc tblblogentries id. This is the Post.PostUuid">

	<cfquery name="Data" datasource="#dsn#">
		SELECT
			PostId,
			Title
		FROM Post
		WHERE PostUuid = <cfqueryparam value="#arguments.postUuid#" cfsqltype="varchar">
	</cfquery>
		
	<cfreturn Data.PostId>
</cffunction>
	
<!--- Category functions --->
<cffunction name="getBlogCfcCategoryById" returntype="string" output="true"
		hint="Gets the category name by the category.id">
	<cfargument name="blogCfcCategoryId" type="string" required="yes" hint="Pass in the BlogCfc tblblogentries id.">

	<cfquery name="Data" datasource="#dsn#">
		SELECT 
			CategoryId,
			CategoryName,
			CategoryAlias
		FROM Category
		WHERE CategoryUuid = <cfqueryparam value="#arguments.blogCfcCategoryId#" cfsqltype="varchar">
	</cfquery>
		
	<cfreturn Data.CategoryName>
</cffunction>
	


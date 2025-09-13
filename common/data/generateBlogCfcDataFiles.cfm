<!--- Common destination --->
<cfset destination = expandPath("#application.baseUrl#/common/data/files/blogCfcImport")>
<!--- Set the dsn --->
<cfset dsn = "blogCfc">
<cfset oldEnclosurePath = "D:\home\gregorysblog.org\wwwroot\enclosures\">
	
<cfset debug = false>
	
<!---****************************************************************************************
Categories
*****************************************************************************************--->
	
<cfset dataName = "getBlogCfcCategories">
	
<cfquery name="getBlogCfcCategories" datasource="#dsn#">
	SELECT 
		categoryid,
		categoryname,
		categoryalias
	FROM tblblogcategories
</cfquery>
		
<cfif debug><cfdump var="#getBlogCfcCategories#"></cfif>
	
<cfoutput query="getBlogCfcCategories">
	<!--- Save the category. This function will not insert duplicate categories. --->
	<cfinvoke component="#application.blog#" method="saveCategory" returnvariable="categoryId">
		<cfinvokeargument name="category" value="#categoryname#">
	</cfinvoke>
</cfoutput>
	
<cfwddx
	action="cfml2wddx"
	input="#getBlogCfcCategories#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Posts
*****************************************************************************************--->
	
<cfset dataName = "getBlogCfcPosts">
	
<cfquery name="getBlogCfcPosts" datasource="#dsn#">
	SELECT 
	   [id]
      ,[title]
      ,[body]
      ,[posted]
      ,[morebody]
      ,[alias]
      ,[username]
      ,[allowcomments]
      ,[enclosure]
      ,[filesize]
      ,[mimetype]
      ,[views]
      ,[released]
      ,[mailed]
  FROM tblblogentries
</cfquery>
		
<cfoutput query="getBlogCfcPosts">
	
	<!--- Invoke the insertNewPost function. This will return the new postId --->
	<cfinvoke component="#application.blog#" method="insertNewPost" returnvariable="postId">
		<cfinvokeargument name="author" value="1">
		<cfinvokeargument name="title" value="#title#">
		<cfinvokeargument name="description" value="#left(body, 125)#">
		<cfinvokeargument name="datePosted" value="#dateFormat( posted, 'yyyy-mm-dd' )#">
		<cfinvokeargument name="timePosted" value="#timeFormat( posted, 'HH:mm:ss' )#">
	</cfinvoke>
			
	<!--- Now that the new post was made, update the mediaUrl if there is an enclosure --->
	<!--- Get the image from the path. We are going to remove the oldEnclosurePath from the enclosure --->
	<cfset imageName = replaceNoCase(enclosure, oldEnclosurePath, '')>
	<cfset newImageUrl = application.baseUrl & "/enclosures/">
	<cfset newImagePath = expandPath(newImageUrl)>
		
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
		
	<!--- Update the post with the rest of the post data. --->
	<cfinvoke component="#application.blog#" method="savePost" returnvariable="postId">
		<cfinvokeargument name="postId" value="#postId#">
		<cfinvokeargument name="author" value="1">
		<cfinvokeargument name="title" value="#title#">
		<cfinvokeargument name="description" value="#left(body, 125)#">
		<cfinvokeargument name="post" value="#body#">
		<cfinvokeargument name="mediaId" value="#mediaId#">
		<cfinvokeargument name="numViews" value="#views#">
		<cfinvokeargument name="released" value="#released#">
		<cfinvokeargument name="emailSubscriber" value="false">
	</cfinvoke>

</cfoutput>

<cfif debug><cfdump var="#getBlogCfcPosts#"></cfif>
	
<cfwddx
	action="cfml2wddx"
	input="#getBlogCfcPosts#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Post Categories
*****************************************************************************************--->
	
<cfset dataName = "getBlogCfcPostCategories">
	
<cfquery name="getBlogCfcPostCategories" datasource="#dsn#">
	SELECT 
		[categoryidfk]
      	,[entryidfk]
  FROM [tblblogentriescategories]
</cfquery>
	
<!--- Loop through the post categories --->
<cfoutput query="getBlogCfcPostCategories">
	<!--- Get the BlogCfc post title --->
	<cfset postTitle = getBlogCfcPostTitleById(entryidfk)>
	<!--- Get the Galaxie postId by the title. This returns an array. --->
	<cfset getPost = application.blog.getPosts(title=postTitle)>
		
	<!--- Get the category title --->
	<cfset blogCfcCategoryTitle = getBlogCfcCategoryById(categoryidfk)>
	<!--- Note: this will either update or insert the category and returns the categoryId --->
	<cfset categoryId = application.blog.saveCategory(category=blogCfcCategoryTitle)>
	<!--- Assign the category to the post --->
	<cfset assignCategoryToPost = application.blog.assignCategory(postId=getPost[1]["PostId"], categoryId=categoryId)>
</cfoutput>
	
<cfif debug><cfdump var="#getBlogCfcPostCategories#"></cfif>
	
<cfwddx
	action="cfml2wddx"
	input="#getBlogCfcPostCategories#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataName#.txt" output="#blogDataXml#">
		
<!---****************************************************************************************
Related Entries
*****************************************************************************************--->
		
<cfset dataName = "getBlogCfcRelatedPosts">
	
<cfquery name="getBlogCfcRelatedPosts" datasource="#dsn#">
	SELECT [entryid]
	  ,[relatedid]
	FROM [tblblogentriesrelated]
</cfquery>
	
<cfoutput query="getBlogCfcRelatedPosts">
	
	<!--- Get the post title --->
	<cfset blogCfcPostTitle = getBlogCfcPostTitleById(entryid)>
	<!--- Get the related post title --->
	<cfset blogCfcRelatedPostTitle = getBlogCfcPostTitleById(relatedid)>
	<!--- Get the postId --->
	<cfset getPostId = application.blog.getPosts(title=blogCfcPostTitle)>
	<!--- And the related postId --->
	<cfset getRelatedPostId = application.blog.getPosts(title=blogCfcRelatedPostTitle)>
	<!--- Save the related posts --->
	<cfset relatedPosts = application.blog.saveRelatedPosts(getPostId[1]["PostId"], getRelatedPostId[1]["PostId"]) />
	
</cfoutput>
		
<!---****************************************************************************************
Comments
*****************************************************************************************--->
	
<cfset dataName = "getBlogCfcPostComments">
	
<cfquery name="getBlogCfcPostComments" datasource="#dsn#">
	SELECT [id]
      ,[entryidfk]
      ,[name]
      ,[email]
      ,[comment]
      ,[posted]
      ,[subscribe]
      ,[website]
      ,[moderated]
      ,[subscribeonly]
      ,[killcomment]
  FROM [tblblogcomments]
</cfquery>
	
<cfoutput query="getBlogCfcPostComments">
	
	<!--- Get the post title --->
	<cfset blogCfcPostTitle = getBlogCfcPostTitleById(entryidfk)>
	<!--- Get the postId --->
	<cfset getPostId = application.blog.getPosts(title=blogCfcPostTitle)>
	<!--- See if the comment exists. This gets the comment to the millisecond. --->
	<cfset getComment = application.blog.getCommentByDate(datePosted=posted)>
	blogCfcPostTitle: #blogCfcPostTitle# postId: #getPostId[1]["PostId"]# posted: #posted#<br/>
	<cfdump var="#getComment#">
		
	<cfif not arrayLen(getComment)>
		Inserting comment<br/>
		<!--- Save the comment --->
		<cfinvoke component="#application.blog#" method="addComment" returnvariable="addComment">
			<cfinvokeargument name="postId" value="#getPostId[1]['PostId']#">
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
	
<cfwddx
	action="cfml2wddx"
	input="#getBlogCfcPostComments#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Subscribers
*****************************************************************************************--->
	
<cfset dataName = "getBlogCfcSubscribers">
	
<cfquery name="getBlogCfcSubscribers" datasource="#dsn#">
	SELECT [email]
      ,[token]
      ,[blog]
      ,[verified]
  	FROM [tblblogsubscribers]
</cfquery>
	
<cfif debug><cfdump var="#getBlogCfcSubscribers#"></cfif>
	
<cfoutput query="getBlogCfcSubscribers">
	<!--- Add the subscribers. --->
	<cfset addSubscriber = application.blog.addSubscriber(email=#email#)>
	<!---email: #email# addSubscriber: #addSubscriber#<br/>--->
</cfoutput>
	
<cfwddx
	action="cfml2wddx"
	input="#getBlogCfcSubscribers#"
	output="blogDataXml"
	/>
	
<cffile action="write" file="#destination#/#dataName#.txt" output="#blogDataXml#">
	
<!---****************************************************************************************
Helper functions
*****************************************************************************************--->	
	
<!--- Post functions --->
<cffunction name="getBlogCfcPostTitleById" returntype="string" output="false"
		hint="Gets the post title by the post.id">
	<cfargument name="blogCfcPostId" type="string" required="yes" hint="Pass in the BlogCfc tblblogentries id.">

	<cfquery name="Data" datasource="#dsn#">
		SELECT
			[id],
			[title]
		FROM [tblblogentries]
		WHERE id = <cfqueryparam value="#arguments.blogCfcPostId#" cfsqltype="varchar">
	</cfquery>
		
	<cfreturn Data.title>
</cffunction>
	
<!--- Category functions --->
<cffunction name="getBlogCfcCategoryById" returntype="string" output="false"
		hint="Gets the category name by the category.id">
	<cfargument name="blogCfcCategoryId" type="string" required="yes" hint="Pass in the BlogCfc tblblogentries id.">

	<cfquery name="Data" datasource="#dsn#">
		SELECT 
			[categoryid]
			,[categoryname]
			,[categoryalias]
		FROM [tblblogcategories]
		WHERE categoryid = <cfqueryparam value="#arguments.blogCfcCategoryId#" cfsqltype="varchar">
	</cfquery>
		
	<cfreturn Data.categoryname>
</cffunction>
	


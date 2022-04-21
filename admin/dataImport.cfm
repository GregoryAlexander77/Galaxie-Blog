<!--- Save the categories --->
<cfinvoke component="#application.blog#" method="saveCategory" returnvariable="categoryId">
	<cfinvokeargument name="category" value="Category">
</cfinvoke>

<!--- Invoke the insertNewPost function. This will return the new postId --->
<cfinvoke component="#application.blog#" method="insertNewPost" returnvariable="postId">
	<cfinvokeargument name="author" value="1">
	<cfinvokeargument name="title" value="Test import post">
	<cfinvokeargument name="description" value="Test of the national broadcast system">
	<cfinvokeargument name="datePosted" value="2/11/2022">
	<cfinvokeargument name="timePosted" value="11:00 AM">
</cfinvoke>
		
<!--- Save the enclosure image if it exists. This returns the mediaId --->
<cfinvoke component="#application.proxyControllerComponentPath#" method="saveExternalMediaEnclosure" returnvariable="mediaId">
	<cfinvokeargument name="csrfToken" value="1">
	<cfinvokeargument name="externalUrl" value="/galaxieBlog/enclosures/foo.png">
	<cfinvokeargument name="postId" value="#postId#">
	<cfinvokeargument name="mediaType" value="image">
</cfinvoke>
		
<!--- Save the post. This returns the mediaId --->
<cfinvoke component="#application.blog#" method="savePost" returnvariable="postId">
	<cfinvokeargument name="postId" value="#postId#">
	<cfinvokeargument name="post" value="blah blah blah">
	<cfinvokeargument name="mediaId" value="#mediaId#">
	<cfinvokeargument name="released" value="true">
	<cfinvokeargument name="postCategories" value="11:00 AM">
	<cfinvokeargument name="relatedPosts" value="11:00 AM">
	<cfinvokeargument name="emailSubscriber" value="false">
</cfinvoke>
			
			
		
			
		
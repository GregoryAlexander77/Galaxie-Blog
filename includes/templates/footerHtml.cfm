	<br/><br/><br/>
	<div id="footerDiv" name="footerDiv" class="k-content">
		<span id="footerInnerContainer">
			
			<img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo"/>
			
			<h4 style="display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h4>
			<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

			<h4>Images and Photography:</h4>
			<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>
			
			<h4>Credits:</h4>
			<p>
				Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. 
			</p>
			<h4>Version:</h4>
			<p>
				Galaxie Blog Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput>
			</p>
		</span>
	</div>
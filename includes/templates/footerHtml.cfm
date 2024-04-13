	<br/><br/><br/>
	<div id="footerDiv" name="footerDiv" class="k-content">
		<footer>
			<span id="footerInnerContainer">

				<img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo"/>

				<h2 style="font-size:14pt; display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h2>
				<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

				<h2 style="font-size:14pt">Images and Photography:</h2>
				<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>

				<h2 style="font-size:14pt">Credits:</h2>
				<p>
					Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. 
				</p>
				<h2 style="font-size:14pt">Version:</h2>
				<p>
					Galaxie Blog Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput>
				</p>
				<p>
					<a href="https://www.media3.net"><img src="/images/logo/m3/m3-cloud-logo-hosting-small.gif" alt="Hosting provided by www.media3.net"></a>
				</p>
				</span>
		</footer>
	</div>
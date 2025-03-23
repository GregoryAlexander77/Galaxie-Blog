<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "compositeFooter">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getPageContent function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
</cfsilent>

<br/><br/><br/>
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database. Note: the footer and span tags are removed by tinymce so we need to manually include them --->
	<div id="footerDiv" name="footerDiv" class="k-content">
		<footer>
			<span id="footerInnerContainer">
				<cfoutput>#contentOutputData#</cfoutput>
			</span>
		</footer>
	</div>
<cfelse>
	<div id="footerDiv" name="footerDiv" class="k-content">
		<footer>
			<span id="footerInnerContainer">
				<a href="https://www.gregoryalexander.com/"><img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo"/></a>
			<cfif application.serverProduct eq 'Lucee'>
				<h2 id="galaxie-blog-4-ready-set-go-">Why Galaxie Blog?</h2>
				<p>Galaxie Blog is a wickedly fast, full-featured, free, open-source blog that supports Lucee and Adobe ColdFusion.</p>
				<ul>
					<li>
						<strong>Free and Open Source</strong><br>Galaxie Blog includes everything needed to create a beautiful blog. Unlike other blogging platforms, there is no additional upcharge for additional functionality that should have been initially built in.
					</li>
					<li>
						<strong>Galaxie Blog is Wickedly Fast</strong><br>
						Out of the box, Galaxie Blog consistently <a href="https://www.gregoryalexander.com/blog/2024/4/29/lighthouse-scores-of-blog-sites-driven-by-coldfusion">averages above 90%</a> in Google lighthouse scores, even when the page is decked out with large images.&nbsp;<span style="box-sizing: border-box; margin: 0px; padding: 0px;"><a href="https://galaxieblog.org/">If you're judicious with your images, Galaxie Blog for Lucee</a> can often attain a perfect 100% score</span>.
					</li>
					<li>
						<strong>Galaxie Blog Has Perfect Google Lighthouse SEO Scores!</strong><br>
						Galaxie Blog is optimized for search engines. It has built-in features such as meta tags, <a href="https://galaxieblog.org/2025/3/9/changing-the-jsonld-that-galaxie-blog-automatically-generates-for-your-posts">JSON-LD,</a> SEO-friendly URLs, and sitemaps to help search engines crawl your site effectively. Galaxie Blog easily integrates with <a href="https://developers.google.com/analytics/devguides/collection/ga4">Google Analytics</a> to analyze traffic and trends.
					</li>
					<li><strong>Exceptional Media Support</strong><br>
						Galaxie Blog supports a variety of rich media. Galaxie Blog allows users to upload various media for hero images and optimizes them for social media sites. You can <a href="https://www.gregoryalexander.com/blog/2024/2/22/implementing-client-side-file-uploading-with-uppy">upload </a>files, photos, videos, <a href="https://www.gregoryalexander.com/blog/2024/4/14/building-image-sliders-with-stunning-transitions-using-swiper">carousels</a>, <a href="https://galaxieblog.org/2025/3/10/creating-beautiful-galleries-within-a-blog-post-using-galaxie-blog">galleries</a>, embed <a href="https://galaxieblog.org/2025/3/10/adding-dynamic-bing-maps-to-a-blog-post">Bing Maps</a> to a post, and more.</li>
					<li>
						<strong>No Code Content Management System (CMS)</strong><br>
						Galaxie Blog provides intuitive visual interfaces with pre-built theme templates, allowing non-technical users to create and manage content effortlessly. Users who like to code can switch views to see the backend code using a full-featured code editor.
					</li>
					<li>
						<strong>User-Friendly Drag and Drop Editors</strong><br>
						Galaxie Blog uses a highly customized version of <a href="https://www.tiny.cloud/">TinyMCE </a>that is intuitive and easy to use. These editors allow you to craft the perfect post and add various types of rich media using drag-and-drop interfaces.
					</li>
					<li>
						<strong>Galaxie Blog is Eminently Themeable</strong><br>It has over 30 themed templates; you can edit or develop a new theme within minutes. Every post can have its unique <a href="https://galaxieblog.org/2025/3/9/assign-post-to-theme">theme</a>!
					</li>
					<li>
						<strong>Attractive Design</strong><br>
						Posts are laid out in a beautiful card layout on the landing page. The most popular posts are available at the top of the page, and you can filter the posts by category. Breadcrumbs are automatically created at the top of each page.
					</li>
					<li>
						<strong>Stunning Mobile Interface</strong><br>
						Galaxie Blog is a responsive website offering nearly identical functionality for desktop and mobile devices. Galaxie Blog was created using a mobile-first design strategy. It allows you to manage the blog and create stunning posts with a tablet or phone.
					</li>
					<li>
						<strong>Supports all Modern Databases</strong><br>
						Galaxie Blog uses <a href="https://hibernate.org/orm/">Hibernate ORM</a> underneath the hood and can support all modern databases!
					</li>
					<li>
						<strong>Mature and Proven Platform</strong><br>
						Galaxie Blog has had four major releases since <a href="https://www.gregoryalexander.com/blog/2018/10/30/introductory-purpose">2018</a>. Galaxie Blog was initially based on <a href="https://github.com/teamcfadvance/BlogCFC5">BlogCFC</a>, which was first released in 2005.
					</li>
				</ul>
			<cfelse><!---<cfif application.serverProduct eq 'Lucee'>--->
				<h2 style="font-size:14pt; display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h2>
				<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

				<h2 style="font-size:14pt">Images and Photography:</h2>
				<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>

				<h2 style="font-size:14pt">Credits:</h2>
				<p>
					Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. 
				</p>
			</cfif><!---<cfif application.serverProduct eq 'Lucee'>--->
				<h2 style="font-size:14pt">Version:</h2>
				<p>
					Galaxie Blog Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput>
				</p>
				<p>
				<cfif application.serverProduct eq 'Lucee'>
					<a href="https://www.viviotech.net/"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/viviotech/vivioTechSmallLogo.<cfif application.serverSupportsWebP>webp<cfelse>png</cfif>" alt="Lucee Linux Hosting provided by www.viviotech.net"></a>
				<cfelse>
					<a href="https://www.media3.net"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/m3/m3-cloud-logo-hosting-small.gif" alt="ColdFusion Windows Hosting provided by www.media3.net"></a>
				</cfif>
				</p>
			</span>
		</footer>
	</div><!---<div id="footerDiv" name="footerDiv" class="k-content">--->
</cfif>
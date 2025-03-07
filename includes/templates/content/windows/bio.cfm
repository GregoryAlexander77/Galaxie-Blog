<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "bioWindow">
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
				
<cfif displayContentOutputData>
	<!--- Include the content template for the navigation script --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
	<!--- Get the user information for the person who installed the blog. If you want a different user, change the blog.ini.cfm file and reinit the blog using the following URL arg: ?reinit=1 --->
	<cfset authorData = application.blog.getBlogOwner()>
	<table align="center" class="k-content" width="100%" cellpadding="5" cellspacing="5" border="0">
		<tr>
			<td width="150">
				<img src="<cfoutput>#authorData[1]['ProfilePicture']#</cfoutput>" title="<cfoutput>#authorData[1]['FullName']#</cfoutput>'s' Profile" alt="<cfoutput>#authorData[1]['FullName']#</cfoutput>'s' Profile" border="0" class="avatar avatar-64 photo" height="135" width="135" align="left" style="padding: 10px">
			</td>
			<td>
				<div class="author-bio k-content flexItem">
					<h3 class="topContent"><cfoutput>#authorData[1]['FullName']#</cfoutput></h3>
				</div>
				<div class="author-bio k-content flexItem">
				<cfif structKeyExists(authorData[1], "FacebookUrl") and len(authorData[1]['FacebookUrl'])>
					<a href="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" class="k-content"><button id="facebookUrl" aria-label="facebook" class="k-button" style="#kendoIconButtonStyle#">
						&nbsp;<i class="fa-brands fa-facebook"></i>&nbsp;
					</button></a>
				</cfif><cfif structKeyExists(authorData[1], "LinkedInUrl") and len(authorData[1]['LinkedInUrl'])>
					<a href="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" class="k-content"><button id="linkedInUrl" aria-label="linkedIn" class="k-button" style="#kendoIconButtonStyle#">
						&nbsp;<i class="fa-brands fa-linkedin"></i>&nbsp;
					</button></a>
				</cfif><cfif structKeyExists(authorData[1], "InstagramUrl") and len(authorData[1]['InstagramUrl'])>
					<a href="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="instagramUrl" aria-label="instagram" class="k-button" style="#kendoIconButtonStyle#">
						&nbsp;<i class="fa-brands fa-instagram"></i>&nbsp;
					</button></a>
				</cfif><cfif structKeyExists(authorData[1], "TwitterUrl") and len(authorData[1]['InstagramUrl'])>
					<a href="<cfoutput>#authorData[1]['TwitterUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="twitterUrl" aria-label="twitter" class="k-button" style="#kendoIconButtonStyle#">
						&nbsp;<i class="fa-brands fa-twitter"></i>&nbsp;
					</button></a>
				</cfif><cfif structKeyExists(authorData[1], "DisplayEmailOnBio") and authorData[1]["DisplayEmailOnBio"]>
					<a href="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" aria-label="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" class="k-content"><button id="email" aria-label="email" class="k-button" style="#kendoIconButtonStyle#">
						&nbsp;<i class="fa-solid fa-envelope"></i>&nbsp;
					</button></a>
				</cfif>
				</div>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<p>I have over 23 years of web development experience. After serving in the Navy- I went to college in the mid-90s and obtained several degrees in computer graphics and multimedia authoring. My timing was terrific; as soon as I had graduated, the web exploded onto the scene.</p>

				<p>I started developing with ColdFusion 2.5, which was the original middle-ware tool to drive database-driven websites. Later, I also learned classic ASP. Soon, I became the lead web developer at Boeing’s Everett site and helped to build the largest intranet site in the world at the time.</p>

				<p>I moved on to the University of Washington Genome Center, where I worked in Bioinformatics and built collaborative web applications for the Human Genome Project. After completing the Human Genome Project in the mid-2000s, I started developing critical web applications for Harborview Medical Center.</p>

				<p>At Harborview, I developed and maintained a web application used in every hospital ICU for multiple states to deliver critical care patients to the nearest hospital en route. If I had made a bug, someone could have very well died. I am happy to say I never made a bug on that production site there!</p>

				<p>Currently, I am working at the University of Washington Medical developing web applications used at various hospitals. I am working on developing this application for the open-source community in my off time.</p>

				<p>My passions include photography, cooking, building and engineering mountain trail systems (I started building trail systems as a kid), long road trips, and hiking!</p>

			</td>
		</tr>
	</table>
	<br/>
</cfif><cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "bioWindow">
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
				
<cfif displayContentOutputData>
	<!--- Include the content template for the navigation script --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="5" border="0">
		<tr>
			<td width="150">
				<img src="https://www.gravatar.com/avatar/c4b88bfa9e70906d0f36166dd315c2a2?s=64&amp;r=pg&amp;d=<cfoutput>#application.baseUrl#</cfoutput>/images/defaultAvatar.gif" title="gregory's Gravatar" alt="gregory's Gravatar" border="0" class="avatar avatar-64 photo" height="135" width="135" align="left" style="padding: 10px">
			</td>
			<td>
				<div class="author-bio k-content flexItem">
					<h3 class="topContent">Gregory Alexander</h3>
				</div>
				<div class="author-bio k-content flexItem">
					<button id="facebookLink" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
						&nbsp;<i class="fa-brands fa-facebook"></i>&nbsp;
					</button>
					<button id="linkedInLink" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
						&nbsp;<i class="fa-brands fa-linkedin"></i>&nbsp;
					</button>
					<button id="twitterLink" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
						&nbsp;<i class="fa-brands fa-twitter"></i>&nbsp;
					</button>
					<button id="instaGram" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
						&nbsp;<i class="fa-brands fa-instagram"></i>&nbsp;
					</button>
					<button id="emailLink" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
						&nbsp;<i class="fa-solid fa-envelope"></i></i>&nbsp;
					</button>
					
				</div>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<p>I have over 23 years of web development experience. After serving in the Navy- I went to college in the mid 90’s and obtained several degrees in computer graphics and multimedia authoring. My timing was terrific, as soon as a had graduated, the web exploded onto the scene. </p>
				<p>I started developing with ColdFusion 2.5, which was the original ‘middle-ware’ tool to drive database driven websites. Later, I also learned classic ASP. Soon, I became the lead web developer at Boeing’s Everett site, and helped to build the largest intranet site in the world at the time. </p>
				<p>I moved on to the University of Washington Genome Center, where I worked in Bioinformatics and built collaborative web applications for the Human Genome Project. After the Human Genome Project was completed in the mid 2000’s, I started developing critical web applications for Harborview Medical Center.</p>
				At Harborview, I developed and maintained a web application that was used in every hospital ICU for multiple states, and was used to deliver critical care patients to the nearest hospital while enroute. If I had made a bug, someone could have very well died. I am happy to say that I had never made a bug in that production site there!</p>
				<p>Currently, I am working at the University of Washington Medical developing web applications that are used at various hospitals, and in my off time, I am working on developing this application for the open source community.</p>
				<p>My personal passions include photography, cooking, building and engineering moutain trail systems (I started building trail systems as a kid), long road trips, and of course hiking!</p>
			</td>
		</tr>
	</table>
</cfif>
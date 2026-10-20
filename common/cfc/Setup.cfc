<cfcomponent displayName="Setup" output="false" hint="The Site Setup wizard's saves (Galaxie 5, 2026-10-19): admin/setup.cfm, through ProxyController.cfc saveSetup*. One function per screen. Each marks its screen done in BlogOption.SetupStepsDone, so the wizard can show what is finished and pick up where the owner left off.">

<!---
	The screens: site (name, description, email, time zone), look (theme), logo, about (the owner's profile and the About and
	Bio windows), home (home page layout and post hero style), starter (a welcome post and an About page), then Done.

	Nothing here changes a blog that never ran the wizard: the About window shows the owner's text because it is saved as the
	About window's content (ContentOutput), and the Bio window shows the owner's biography only once SetupStepsDone includes
	"about" (includes/templates/content/windows/bio.cfm). Without them both windows keep their built-in text.
--->

<cfset variables.steps = "site,look,logo,about,home,starter">

<!---//*****************************************************************************************************
		State
//******************************************************************************************************--->

<cffunction name="getState" access="public" returntype="struct" output="false" hint="What the wizard shows on opening: the blog's current settings, the owner's profile and the screens already done.">
	<cfset var blogObj = application.BlogDbObj>
	<cfset var optionObj = application.BlogOptionDbObj>
	<cfset var owner = getOwner()>
	<cfset var selected = ormExecuteQuery("SELECT ThemeAlias FROM Theme WHERE SelectedTheme = 1")>
	<cfset var state = {
		title = blogObj.getBlogTitle() ?: "",
		description = blogObj.getBlogDescription() ?: "",
		email = blogObj.getBlogEmail() ?: "",
		timeZone = blogObj.getBlogTimeZone() ?: "",
		theme = arrayLen(selected) ? selected[1] : "",
		stepsDone = optionObj.getSetupStepsDone() ?: "",
		finished = optionObj.getSetupFinished() ?: "",
		homeLayout = optionObj.getSetupHomeLayout() ?: "",
		heroStyle = optionObj.getPostHeroStyle() ?: "classic",
		firstName = "", lastName = "", displayName = "", biography = "", profilePicture = "",
		facebookUrl = "", linkedInUrl = "", instagramUrl = "", twitterUrl = ""
	}>
	<cfif not isNull(owner)>
		<cfset state.firstName = owner.getFirstName() ?: "">
		<cfset state.lastName = owner.getLastName() ?: "">
		<cfset state.displayName = owner.getDisplayName() ?: "">
		<cfset state.biography = owner.getBiography() ?: "">
		<cfset state.profilePicture = owner.getProfilePicture() ?: "">
		<cfset state.facebookUrl = owner.getFacebookUrl() ?: "">
		<cfset state.linkedInUrl = owner.getLinkedInUrl() ?: "">
		<cfset state.instagramUrl = owner.getInstagramUrl() ?: "">
		<cfset state.twitterUrl = owner.getTwitterUrl() ?: "">
	</cfif>
	<cfreturn state>
</cffunction>

<cffunction name="isStepDone" access="public" returntype="boolean" output="false">
	<cfargument name="step" type="string" required="true">
	<cfreturn listFindNoCase(application.BlogOptionDbObj.getSetupStepsDone() ?: "", arguments.step) gt 0>
</cffunction>

<cffunction name="usesOwnText" access="public" returntype="boolean" output="false" hint="Whether the About and Bio windows show the owner's own details rather than the built-in text: after the wizard's About screen, or on any blog installed with 5.0 or later (the installer marks it 'new').">
	<cfreturn isStepDone("about") or isStepDone("new")>
</cffunction>

<cffunction name="stepsDoneCount" access="public" returntype="numeric" output="false" hint="How many of the six screens are saved (not counting the installer's 'new' mark).">
	<cfset var count = 0>
	<cfset var step = "">
	<cfloop list="#variables.steps#" index="step"><cfif isStepDone(step)><cfset count++></cfif></cfloop>
	<cfreturn count>
</cffunction>

<cffunction name="shouldAutoOpen" access="public" returntype="boolean" output="false" hint="True on a blog installed with 5.0 or later (the installer's 'new' mark) whose owner hasn't started setup yet: the admin home then opens the wizard once per session. Blogs updated from older versions never have the mark, so they are never sent there.">
	<cfreturn isStepDone("new") and stepsDoneCount() eq 0 and not isFinished()>
</cffunction>

<cffunction name="isFinished" access="public" returntype="boolean" output="false" hint="True once the owner pressed Done. The admin home shows the Finish setting up banner until then.">
	<cfreturn len(application.BlogOptionDbObj.getSetupFinished() ?: "") gt 0>
</cffunction>

<cffunction name="markDone" access="private" returntype="void" output="false">
	<cfargument name="step" type="string" required="true">
	<cfset var optionObj = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
	<cfset var done = optionObj.getSetupStepsDone() ?: "">
	<cfif not listFindNoCase(done, arguments.step)>
		<cfset optionObj.setSetupStepsDone(listAppend(done, arguments.step))>
		<cfset entitySave(optionObj)>
		<cfset ormFlush()>
	</cfif>
	<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
</cffunction>

<cffunction name="getOwner" access="private" returntype="any" output="false" hint="The blog owner's Users entity, or null: the same person the Bio window shows (blog.cfc getBlogOwner - the owner named in blog.ini.cfm, or the first user when it names none).">
	<cfset var owners = application.blog.getBlogOwner()>
	<cfif arrayLen(owners) and val(owners[1]["UserId"] ?: 0)>
		<cfreturn entityLoadByPK("Users", owners[1]["UserId"])>
	</cfif>
	<cfreturn javaCast("null", "")>
</cffunction>

<cffunction name="fail" access="private" returntype="void" output="false">
	<cfargument name="message" type="string" required="true">
	<cfthrow type="GalaxieBlog.Setup" message="#arguments.message#">
</cffunction>

<!---//*****************************************************************************************************
		Screen 1: your site
//******************************************************************************************************--->

<cffunction name="saveSite" access="public" returntype="void" output="false" hint="The site's name, one-line description, blog email and time zone (a Java/IANA id such as America/Los_Angeles).">
	<cfargument name="title" type="string" required="true">
	<cfargument name="description" type="string" required="false" default="">
	<cfargument name="email" type="string" required="false" default="">
	<cfargument name="timeZone" type="string" required="false" default="">
	<cfset var blogObj = "">
	<cfset var siteTitle = left(trim(arguments.title), 125)>
	<cfset var siteEmail = trim(arguments.email)>
	<cfset var siteZone = trim(arguments.timeZone)>
	<cfif not len(siteTitle)><cfset fail("Please give your site a name.")></cfif>
	<cfif len(siteEmail) and not isValid("email", siteEmail)><cfset fail("That email address doesn't look right.")></cfif>
	<!--- Only a time zone Java knows; anything else keeps the current one. --->
	<cfif len(siteZone) and createObject("java", "java.util.TimeZone").getTimeZone(siteZone).getID() neq siteZone>
		<cfset siteZone = "">
	</cfif>
	<cftransaction>
		<cfset blogObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>
		<cfset blogObj.setBlogTitle(siteTitle)>
		<cfset blogObj.setBlogDescription(left(trim(arguments.description), 500))>
		<cfif len(siteEmail)><cfset blogObj.setBlogEmail(siteEmail)></cfif>
		<cfif len(siteZone)><cfset blogObj.setBlogTimeZone(siteZone)></cfif>
		<cfset blogObj.setDate(application.blog.blogNow())>
		<cfset entitySave(blogObj)>
	</cftransaction>
	<cfset application.BlogDbObj = entityLoadByPK("Blog", blogObj.getBlogId())>
	<cfset markDone("site")>
	<!--- The name is in every page's header and title. --->
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="sendTestEmail" access="public" returntype="void" output="false" hint="A short test message to the blog email, so the owner knows mail works before visitors depend on it.">
	<cfargument name="email" type="string" required="true">
	<cfif not isValid("email", arguments.email)><cfset fail("That email address doesn't look right.")></cfif>
	<!--- Through the blog's own mail function, which uses the mail server in Blog Settings (or the server's default when that is
	empty), as every other email the blog sends does. --->
	<cfset createObject("component", application.utilsComponentPath).mail(to = arguments.email, from = arguments.email,
		subject = "Your Galaxie Blog can send email", type = "text",
		body = "Good news: " & application.BlogDbObj.getBlogTitle() & " can send email. Sign-in links, comment notices and subscriber emails will reach you and your visitors.")>
</cffunction>

<!---//*****************************************************************************************************
		Screen 2: pick a look
//******************************************************************************************************--->

<cffunction name="saveLook" access="public" returntype="void" output="false" hint="Selects the theme, so the site stops changing its look day by day (with no theme selected, the blog picks one by the day).">
	<cfargument name="themeAlias" type="string" required="true">
	<cfset var themeRows = ormExecuteQuery("SELECT ThemeId FROM Theme WHERE ThemeAlias = :alias", { alias = arguments.themeAlias })>
	<cfif not arrayLen(themeRows)><cfset fail("That theme isn't available.")></cfif>
	<!--- blog.saveTheme clears every other theme's selection first, and clears the theme cache. --->
	<cfset application.blog.saveTheme(themeId = themeRows[1], selectedTheme = "1")>
	<cfset markDone("look")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<!---//*****************************************************************************************************
		Screen 3: your logo
//******************************************************************************************************--->

<cffunction name="saveLogo" access="public" returntype="struct" output="false" hint="Saves the logo the wizard made or the owner uploaded, and a PNG for social media, and sets them on EVERY theme (logo, mobile logo, social-share picture). Both come as data URLs. A logo with the site name in it hides the theme's own blog name text, so the name doesn't show twice.">
	<cfargument name="logo" type="string" required="true" hint="data:image/svg+xml;base64,... (made by the wizard) or an uploaded PNG, GIF, JPG, WebP or SVG.">
	<cfargument name="social" type="string" required="false" default="" hint="data:image/png;base64,... 1200 x 630, for social media.">
	<cfargument name="hasName" type="boolean" required="false" default="true" hint="Whether the logo carries the site name.">
	<cfset var folder = expandPath(application.baseUrl & "/images/logo")>
	<cfset var stamp = dateTimeFormat(now(), "yyyymmddHHnnss")>
	<cfset var logoData = decodeDataUrl(arguments.logo)>
	<cfset var socialData = len(arguments.social) ? decodeDataUrl(arguments.social) : {}>
	<cfset var logoFile = "site-logo-" & stamp & "." & logoData.ext>
	<cfset var socialFile = "">
	<cfset var settings = "">
	<cfset var setting = "">
	<cfif not listFind("svg,png,gif,jpg,webp", logoData.ext)><cfset fail("A logo must be a PNG, GIF, JPG, WebP or SVG picture.")></cfif>
	<cfif arrayLen(logoData.bytes) gt 2 * 1024 * 1024><cfset fail("That logo is larger than 2 MB. Please use a smaller picture.")></cfif>
	<cfif logoData.ext eq "svg">
		<cfset checkSvg(toString(logoData.bytes, "utf-8"))>
	</cfif>
	<cfif not directoryExists(folder)><cfdirectory action="create" directory="#folder#"></cfif>
	<cffile action="write" file="#folder#/#logoFile#" output="#logoData.bytes#">
	<cfif structKeyExists(socialData, "ext") and socialData.ext eq "png" and arrayLen(socialData.bytes) lt 4 * 1024 * 1024>
		<cfset socialFile = "site-logo-" & stamp & "-social.png">
		<cffile action="write" file="#folder#/#socialFile#" output="#socialData.bytes#">
	</cfif>
	<!--- Every theme, so the logo stays when the owner changes theme. Theme paths are stored without the base URL. --->
	<cftransaction>
		<cfset settings = entityLoad("ThemeSetting")>
		<cfloop array="#settings#" index="setting">
			<cfset setting.setLogoImage("/images/logo/" & logoFile)>
			<cfset setting.setLogoImageMobile("/images/logo/" & logoFile)>
			<cfif len(socialFile)><cfset setting.setDefaultLogoImageForSocialMediaShare("/images/logo/" & socialFile)></cfif>
			<cfif arguments.hasName><cfset setting.setDisplayBlogName(false)></cfif>
			<cfset entitySave(setting)>
		</cfloop>
	</cftransaction>
	<cfset markDone("logo")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
	<cfreturn { logo = application.baseUrl & "/images/logo/" & logoFile, social = len(socialFile) ? application.baseUrl & "/images/logo/" & socialFile : "" }>
</cffunction>

<cffunction name="decodeDataUrl" access="private" returntype="struct" output="false" hint="A base64 data URL as { ext, bytes }; ext is empty for a type that isn't a picture.">
	<cfargument name="dataUrl" type="string" required="true">
	<cfargument name="what" type="string" required="false" default="The logo">
	<cfset var m = reFind("^data:(image/(svg\+xml|png|gif|jpeg|webp));base64,(.+)$", trim(arguments.dataUrl), 1, true)>
	<cfset var types = { "svg+xml" = "svg", "png" = "png", "gif" = "gif", "jpeg" = "jpg", "webp" = "webp" }>
	<cfif not m.pos[1]><cfset fail(arguments.what & " didn't arrive as a picture.")></cfif>
	<cfreturn { ext = types[mid(trim(arguments.dataUrl), m.pos[3], m.len[3])], bytes = binaryDecode(mid(trim(arguments.dataUrl), m.pos[4], m.len[4]), "base64") }>
</cffunction>

<cffunction name="checkSvg" access="private" returntype="void" output="false" hint="An SVG logo is served from the blog's own address, so it must not carry anything that runs: no scripts, event handlers, javascript: links or embedded HTML.">
	<cfargument name="svg" type="string" required="true">
	<cfif not reFindNoCase("^\s*(<\?xml[^>]*>\s*)?<svg[\s>]", arguments.svg)
			or reFindNoCase("<script|<foreignObject|<iframe|<embed|<object|\son[a-z]+\s*=|javascript:|<!ENTITY", arguments.svg)>
		<cfset fail("That SVG has content a logo can't have (scripts or embedded pages). Please use a plain SVG, or a PNG.")>
	</cfif>
</cffunction>

<!---//*****************************************************************************************************
		Screen 4: about you
//******************************************************************************************************--->

<cffunction name="saveAbout" access="public" returntype="void" output="false" hint="The owner's name, a few lines about themselves and social links (their user profile, shown in the Bio window), and the About window's text.">
	<cfargument name="firstName" type="string" required="true">
	<cfargument name="lastName" type="string" required="false" default="">
	<cfargument name="biography" type="string" required="false" default="" hint="Plain text; blank lines start a new paragraph.">
	<cfargument name="aboutSite" type="string" required="false" default="" hint="Plain text for the About window.">
	<cfargument name="facebookUrl" type="string" required="false" default="">
	<cfargument name="linkedInUrl" type="string" required="false" default="">
	<cfargument name="instagramUrl" type="string" required="false" default="">
	<cfargument name="twitterUrl" type="string" required="false" default="">
	<cfargument name="photo" type="string" required="false" default="" hint="A new profile photo as a data URL (PNG, JPG, GIF or WebP); empty keeps the current one.">
	<cfset var owner = getOwner()>
	<cfset var photoData = "">
	<cfset var photoFile = "">
	<cfset var photoFolder = expandPath(application.baseUrl & "/images/photo")>
	<cfset var photoImage = "">
	<cfset var fullName = trim(trim(arguments.firstName) & " " & trim(arguments.lastName))>
	<cfset var aboutHtml = "">
	<cfset var link = "">
	<cfif isNull(owner)><cfset fail("The blog owner's account couldn't be found.")></cfif>
	<cfif not len(trim(arguments.firstName))><cfset fail("Please give your first name.")></cfif>
	<cfloop list="facebookUrl,linkedInUrl,instagramUrl,twitterUrl" index="link">
		<cfif len(trim(arguments[link])) and not reFindNoCase("^https?://[^\s<>""]+$", trim(arguments[link]))>
			<cfset fail("Links must start with https:// (check the " & replaceNoCase(link, "Url", "") & " link).")>
		</cfif>
	</cfloop>
	<!--- The photo: saved in images/photo/, as profile pictures uploaded in the profile are; a large one is made 600 pixels wide
	(the Bio window shows it at 135). A GIF is kept as it is, so an animated one stays animated. --->
	<cfif len(arguments.photo)>
		<cfset photoData = decodeDataUrl(arguments.photo, "The photo")>
		<cfif not listFind("png,jpg,gif,webp", photoData.ext)><cfset fail("A photo must be a PNG, JPG, GIF or WebP picture.")></cfif>
		<cfif arrayLen(photoData.bytes) gt 8 * 1024 * 1024><cfset fail("That photo is larger than 8 MB. Please choose a smaller one.")></cfif>
		<cfif not directoryExists(photoFolder)><cfdirectory action="create" directory="#photoFolder#"></cfif>
		<cfset photoFile = "profile-" & owner.getUserId() & "-" & dateTimeFormat(now(), "yyyymmddHHnnss") & "." & photoData.ext>
		<cffile action="write" file="#photoFolder#/#photoFile#" output="#photoData.bytes#">
		<cfif photoData.ext neq "gif">
			<cftry>
				<cfset photoImage = imageRead(photoFolder & "/" & photoFile)>
				<cfif imageGetWidth(photoImage) gt 600>
					<cfset imageResize(photoImage, 600, "")>
					<cfset imageWrite(photoImage, photoFolder & "/" & photoFile, 0.85, true)>
				</cfif>
				<cfcatch type="any"><!--- A picture the server can't resize is kept at its own size. ---></cfcatch>
			</cftry>
		</cfif>
	</cfif>
	<cftransaction>
		<cfset owner.setFirstName(left(trim(arguments.firstName), 125))>
		<cfset owner.setLastName(left(trim(arguments.lastName), 125))>
		<cfset owner.setFullName(left(fullName, 255))>
		<cfif not len(owner.getDisplayName() ?: "")><cfset owner.setDisplayName(left(fullName, 125))></cfif>
		<cfset owner.setBiography(paragraphs(arguments.biography))>
		<cfset owner.setFacebookUrl(trim(arguments.facebookUrl))>
		<cfset owner.setLinkedInUrl(trim(arguments.linkedInUrl))>
		<cfset owner.setInstagramUrl(trim(arguments.instagramUrl))>
		<cfset owner.setTwitterUrl(trim(arguments.twitterUrl))>
		<cfif len(photoFile)><cfset owner.setProfilePicture(application.baseUrl & "/images/photo/" & photoFile)></cfif>
		<cfset entitySave(owner)>
	</cftransaction>
	<!--- The About window: the owner's own words, signed with their name, for every theme and both layouts. --->
	<cfif len(trim(arguments.aboutSite))>
		<cfset aboutHtml = '<div class="k-content">' & paragraphs(arguments.aboutSite) & '<p>' & encodeForHtml(fullName) & '</p></div>'>
		<cfset application.blog.saveContentOutput(contentTemplate = "aboutWindow", themeId = "", contentOutputDesktop = aboutHtml, contentOutputMobile = aboutHtml)>
	</cfif>
	<cfset markDone("about")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="paragraphs" access="private" returntype="string" output="false" hint="Plain text as HTML paragraphs: a blank line starts a new one, a single line break stays a line break.">
	<cfargument name="text" type="string" required="true">
	<cfset var html = "">
	<cfset var para = "">
	<cfset var normal = replace(replace(trim(arguments.text), chr(13) & chr(10), chr(10), "all"), chr(13), chr(10), "all")>
	<!--- A blank line (perhaps with spaces on it) becomes a separator character, then the text is split on it. --->
	<cfloop array="#listToArray(reReplace(normal, chr(10) & "[ \t]*" & chr(10) & "\s*", chr(30), "all"), chr(30))#" index="para">
		<cfif len(trim(para))>
			<cfset html = html & "<p>" & replace(encodeForHtml(trim(para)), "&##xa;", "<br>", "all") & "</p>">
		</cfif>
	</cfloop>
	<cfreturn html>
</cffunction>

<!---//*****************************************************************************************************
		Screen 5: your home page
//******************************************************************************************************--->

<cffunction name="saveHome" access="public" returntype="void" output="false" hint="The home page layout (posts: latest posts; about: the About page as the whole home page; featured: the About page above the latest posts) and the post hero style. The layout is applied when the owner presses Done, after the starter pages exist.">
	<cfargument name="layout" type="string" required="true">
	<cfargument name="heroStyle" type="string" required="false" default="classic">
	<cfset var optionObj = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
	<cfif not listFind("posts,about,featured", arguments.layout)><cfset fail("Please choose a home page layout.")></cfif>
	<cfset optionObj.setSetupHomeLayout(arguments.layout)>
	<cfset optionObj.setPostHeroStyle(listFind("classic,held,band,magazine", arguments.heroStyle) ? arguments.heroStyle : "classic")>
	<cfset entitySave(optionObj)>
	<cfset ormFlush()>
	<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
	<cfset markDone("home")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<!---//*****************************************************************************************************
		Screen 6: starter content
//******************************************************************************************************--->

<cffunction name="saveStarter" access="public" returntype="struct" output="false" hint="Creates a welcome post and an About page, each only once (a second run finds the first by its title). Both are ordinary posts the owner edits or deletes.">
	<cfargument name="welcomePost" type="boolean" required="false" default="false">
	<cfargument name="aboutPage" type="boolean" required="false" default="false">
	<cfset var owner = getOwner()>
	<cfset var made = { welcomePostId = 0, aboutPageId = 0 }>
	<cfset var blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfif isNull(owner)><cfset fail("The blog owner's account couldn't be found.")></cfif>
	<cfif arguments.welcomePost>
		<cfset made.welcomePostId = makePost("blogPost", owner.getUserId(), "Welcome to " & blogTitle,
			"The first post on " & blogTitle & ".",
			"<p>Welcome to " & encodeForHtml(blogTitle) & "! This is the first post. Edit it to say hello in your own words, or delete it once you have written your own.</p><p>To write a new post, sign in and choose Create Post on the administration page.</p>",
			"linear-gradient(135deg, ##1d4350 0%, ##a43931 100%)")>
	</cfif>
	<cfif arguments.aboutPage>
		<cfset made.aboutPageId = makePost("page", owner.getUserId(), "About",
			"About " & blogTitle & ".",
			len(owner.getBiography() ?: "") ? owner.getBiography() : "<p>Tell your visitors who you are and what this site is about. Edit this page to make it yours.</p>",
			"linear-gradient(135deg, ##355c7d 0%, ##6c5b7b 50%, ##c06c84 100%)")>
	</cfif>
	<cfset markDone("starter")>
	<cfreturn made>
</cffunction>

<cffunction name="makePost" access="private" returntype="numeric" output="false" hint="A released post or page with this title, made now - or the existing one with this title.">
	<cfargument name="postType" type="string" required="true">
	<cfargument name="authorId" type="numeric" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="description" type="string" required="true">
	<cfargument name="body" type="string" required="true">
	<cfargument name="gradient" type="string" required="false" default="" hint="A CSS gradient for the post's picture, so the home page and cards show color rather than the no-picture image. Change it with the post's picture like any other.">
	<cfset var existing = ormExecuteQuery("SELECT PostId, Released FROM Post WHERE Title = :title AND Remove = :removed ORDER BY PostId", { title = arguments.title, removed = false })>
	<cfset var postId = 0>
	<!--- Made by an earlier run: kept as it is once released; one an interrupted run left unreleased is finished now. --->
	<cfif arrayLen(existing) and isBoolean(existing[1][2]) and existing[1][2]><cfreturn existing[1][1]></cfif>
	<cfif arrayLen(existing)>
		<cfset postId = existing[1][1]>
	<cfelse>
		<cfset postId = application.blog.insertNewPost(postType = arguments.postType, author = arguments.authorId, title = arguments.title, description = arguments.description)>
	</cfif>
	<!--- savePost reads the author without declaring it as an argument, so it is passed by name. --->
	<cfset application.blog.savePost(postId = postId, postType = arguments.postType, author = arguments.authorId, title = arguments.title, description = arguments.description,
		post = arguments.body, released = true, emailSubscriber = false)>
	<cfif len(arguments.gradient)>
		<cfset application.blog.savePostHeroGradient(postId = postId, heroGradient = arguments.gradient)>
		<cfset application.blog.flushGalaxieCache(type = "post", postId = postId)>
	</cfif>
	<cfreturn postId>
</cffunction>

<!---//*****************************************************************************************************
		Done
//******************************************************************************************************--->

<cffunction name="finish" access="public" returntype="void" output="false" hint="Applies the home page layout (now that the starter pages exist) and records that setup is finished.">
	<cfset var optionObj = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
	<cfset var layout = optionObj.getSetupHomeLayout() ?: "">
	<cfset var about = ormExecuteQuery("SELECT PostId FROM Post WHERE Title = 'About' AND IsPage = :isPage AND Remove = :removed ORDER BY PostId", { isPage = true, removed = false })>
	<cfif listFind("about,featured", layout) and arrayLen(about)>
		<cfset application.blog.saveHomepageSettings(showPages = true, pageIdList = about[1], showCollections = false,
			collectionIdList = "", showBlogPosts = layout eq "featured")>
	<cfelseif layout eq "posts">
		<cfset application.blog.saveHomepageSettings(showPages = false, pageIdList = "", showCollections = false,
			collectionIdList = "", showBlogPosts = true)>
	</cfif>
	<cfset optionObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
	<cfset optionObj.setSetupFinished(dateTimeFormat(application.blog.blogNow(), "yyyy-mm-dd HH:nn"))>
	<cfset entitySave(optionObj)>
	<cfset ormFlush()>
	<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

</cfcomponent>

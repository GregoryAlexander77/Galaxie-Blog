<cfcomponent displayName="Setup" output="false" hint="The Site Wizard's saves (Galaxie 5, 2026-10-19): admin/setup.cfm, through ProxyController.cfc saveSetup*. One function per screen. Each marks its screen done in BlogOption.SetupStepsDone, so the wizard can show what is finished and pick up where the owner left off.">

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

<cffunction name="applyShippedLook" access="private" returntype="void" output="false"
		hint="A new blog's built-in themes get their solid headers, name colors and logo marks (installer/shippedHeaders.cfm), once, the first time the wizard opens. Never on an upgraded blog.">
	<cfif isUpgradedBlog() or application.events.getSetting(0, "shippedLookApplied", "") eq "1"><cfreturn></cfif>
	<cfinclude template="../../installer/shippedHeaders.cfm">
	<cfset application.events.setSetting(0, "shippedLookApplied", "1")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="getState" access="public" returntype="struct" output="false" hint="What the wizard shows on opening: the blog's current settings, the owner's profile and the screens already done.">
	<cfset var blogObj = "">
	<cfset applyShippedLook()>
	<cfset blogObj = application.BlogDbObj>
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
	<!--- The installer's old stand-ins (a blog installed before 5.0) read as empty, and the email starts as the owner's (2026-10-25). --->
	<cfif state.description eq "Your blog description"><cfset state.description = ""></cfif>
	<cfif state.email eq "myblog@yournewblog.com"><cfset state.email = ""></cfif>
	<cfif not len(state.email) and not isNull(owner)><cfset state.email = owner.getEmail() ?: ""></cfif>
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
	<!--- For the previews (2026-10-20): the starter posts if they exist, and the footer choice. --->
	<cfset structAppend(state, starterLinks(), true)>
	<cfset state.footer = application.events.getSetting(0, "setupFooter", "simple")>
	<cfset state.footerIsCustom = footerIsCustom()>
	<cfset state.footerLogo = application.events.getSetting(0, "setupFooterLogo", "same")>
	<!--- 2026-10-24 (owner): a blog updated from an older version already has its posts, pages and home page, so the wizard
	starts with no starter content ticked and with "Keep my home page as it is" picked. --->
	<cfset state.upgradedBlog = isUpgradedBlog()>
	<cfreturn state>
</cffunction>

<cffunction name="starterLinks" access="public" returntype="struct" output="false" hint="The welcome post's and About page's ids and addresses, when the Site Wizard has made them (0 and empty otherwise).">
	<cfset var result = { welcomePostId = 0, welcomeUrl = "", aboutPageId = 0, aboutUrl = "" }>
	<cfset var found = ormExecuteQuery("SELECT PostId FROM Post WHERE Title = :title AND Remove = :removed ORDER BY PostId", { title = "Welcome to " & (application.BlogDbObj.getBlogTitle() ?: ""), removed = false })>
	<cfif arrayLen(found)>
		<cfset result.welcomePostId = found[1]>
		<cfset result.welcomeUrl = application.blog.makeLink(postId = found[1])>
	</cfif>
	<cfset found = ormExecuteQuery("SELECT PostId FROM Post WHERE Title = 'About' AND IsPage = :isPage AND Remove = :removed ORDER BY PostId", { isPage = true, removed = false })>
	<cfif arrayLen(found)>
		<cfset result.aboutPageId = found[1]>
		<cfset result.aboutUrl = application.blog.makeLink(postId = found[1])>
	</cfif>
	<cfreturn result>
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

<cffunction name="isUpgradedBlog" access="public" returntype="boolean" output="false" hint="True on a blog updated from a version before 5.0: it never has the installer's 'new' mark.">
	<cfreturn not isStepDone("new")>
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
	<cfargument name="footerMode" type="string" required="false" default="same" hint="The footer logo (2026-10-21, owner): same (the header logo), upload (footerLogo), or none.">
	<cfargument name="footerLogo" type="string" required="false" default="" hint="An uploaded footer logo as a data URL, for footerMode upload.">
	<cfargument name="themeName" type="boolean" required="false" default="false"
		hint="2026-10-26 (owner): the name is left to the theme - its own site name, in its font and color, in whatever theme is picked later. The logo is then only a mark (a sample) or empty (no picture), and every theme shows the site name.">
	<cfset var folder = expandPath(application.baseUrl & "/images/logo")>
	<cfset var stamp = dateTimeFormat(now(), "yyyymmddHHnnss")>
	<cfset var hasPicture = not (arguments.themeName and not len(arguments.logo))>
	<cfset var logoData = hasPicture ? decodeDataUrl(arguments.logo) : { ext = "", bytes = [] }>
	<cfset var socialData = len(arguments.social) ? decodeDataUrl(arguments.social) : {}>
	<!--- A mark beside the theme's name is named site-mark-*, so the footer shows it at twice its size (footer.cfm). --->
	<cfset var logoFile = hasPicture ? (arguments.themeName ? "site-mark-" : "site-logo-") & stamp & "." & logoData.ext : "">
	<cfset var logoPath = hasPicture ? "/images/logo/" & logoFile : "">
	<cfset var socialFile = "">
	<cfset var settings = "">
	<cfset var setting = "">
	<cfif hasPicture>
		<cfif not listFind("svg,png,gif,jpg,webp", logoData.ext)><cfset fail("A logo must be a PNG, GIF, JPG, WebP or SVG picture.")></cfif>
		<cfif arrayLen(logoData.bytes) gt 2 * 1024 * 1024><cfset fail("That logo is larger than 2 MB. Please use a smaller picture.")></cfif>
		<cfif logoData.ext eq "svg">
			<cfset checkSvg(toString(logoData.bytes, "utf-8"))>
		</cfif>
	</cfif>
	<!--- The footer logo is checked before anything is written. --->
	<cfset local.footerMode = listFind("same,upload,none", arguments.footerMode) ? arguments.footerMode : "same">
	<cfset local.footerPath = "">
	<cfif local.footerMode eq "upload">
		<cfif not len(arguments.footerLogo)><cfset fail("Please choose a picture for the footer logo, or pick one of the other two choices.")></cfif>
		<cfset local.footerData = decodeDataUrl(arguments.footerLogo)>
		<cfif not listFind("svg,png,gif,jpg,webp", local.footerData.ext)><cfset fail("A footer logo must be a PNG, GIF, JPG, WebP or SVG picture.")></cfif>
		<cfif arrayLen(local.footerData.bytes) gt 2 * 1024 * 1024><cfset fail("That footer logo is larger than 2 MB. Please use a smaller picture.")></cfif>
		<cfif local.footerData.ext eq "svg"><cfset checkSvg(toString(local.footerData.bytes, "utf-8"))></cfif>
	</cfif>
	<cfif not directoryExists(folder)><cfdirectory action="create" directory="#folder#"></cfif>
	<cfif local.footerMode eq "upload">
		<cfset local.footerPath = "/images/logo/site-footer-logo-" & stamp & "." & local.footerData.ext>
		<cffile action="write" file="#folder#/site-footer-logo-#stamp#.#local.footerData.ext#" output="#local.footerData.bytes#">
	<cfelseif local.footerMode eq "same">
		<cfset local.footerPath = logoPath>
	</cfif>
	<cfif hasPicture><cffile action="write" file="#folder#/#logoFile#" output="#logoData.bytes#"></cfif>
	<cfif structKeyExists(socialData, "ext") and socialData.ext eq "png" and arrayLen(socialData.bytes) lt 4 * 1024 * 1024>
		<cfset socialFile = "site-logo-" & stamp & "-social.png">
		<cffile action="write" file="#folder#/#socialFile#" output="#socialData.bytes#">
	</cfif>
	<!--- Every theme, so the logo stays when the owner changes theme. Theme paths are stored without the base URL. --->
	<cftransaction>
		<cfset settings = entityLoad("ThemeSetting")>
		<cfloop array="#settings#" index="setting">
			<cfset setting.setLogoImage(logoPath)>
			<cfset setting.setLogoImageMobile(logoPath)>
			<cfif len(socialFile)><cfset setting.setDefaultLogoImageForSocialMediaShare("/images/logo/" & socialFile)></cfif>
			<!--- The footer logo (2026-10-21): bigger, at the bottom of every page; empty for none. --->
			<cfset setting.setFooterImage(local.footerPath)>
			<cfif arguments.themeName>
				<cfset setting.setDisplayBlogName(true)>
			<cfelseif arguments.hasName>
				<cfset setting.setDisplayBlogName(false)>
			</cfif>
			<cfset entitySave(setting)>
		</cfloop>
	</cftransaction>
	<cfset application.events.setSetting(0, "setupFooterLogo", local.footerMode)>
	<cfset markDone("logo")>
	<cfset application.blog.flushGalaxieCache(type = "all")>
	<cfreturn { logo = hasPicture ? application.baseUrl & logoPath : "", social = len(socialFile) ? application.baseUrl & "/images/logo/" & socialFile : "" }>
</cffunction>

<cffunction name="decodeDataUrl" access="private" returntype="struct" output="false" hint="A base64 data URL as { ext, bytes }; ext is empty for a type that isn't a picture.">
	<cfargument name="dataUrl" type="string" required="true">
	<cfargument name="what" type="string" required="false" default="The logo">
	<!--- Read without one pattern over the whole picture, and typed by the picture's own first bytes rather than the browser's label
	(gregorysblog.org 5.0 install, 2026-10-25: a JPG photo "didn't arrive as a picture" - some browsers label a JPG image/pjpeg or
	image/jpg, and a + in the data can arrive as a space). --->
	<cfset var value = trim(arguments.dataUrl)>
	<cfset var comma = find(",", value)>
	<cfset var header = comma ? lCase(left(value, comma - 1)) : "">
	<cfset var bytes = "">
	<cfset var head = "">
	<cfset var ext = "">
	<cfif left(header, 5) neq "data:" or not findNoCase(";base64", header)>
		<cfset fail(arguments.what & " didn't arrive as a picture (it began: " & encodeForHtml(left(value, 30)) & ").")>
	</cfif>
	<cftry>
		<cfset bytes = binaryDecode(reReplace(replace(mid(value, comma + 1, len(value)), " ", "+", "all"), "[\r\n\t]", "", "all"), "base64")>
		<cfcatch type="any"><cfset fail(arguments.what & " arrived damaged. Please choose it again.")></cfcatch>
	</cftry>
	<!--- The type from the first bytes: PNG, JPG, GIF, WebP; SVG is text, so it is taken from the label. --->
	<cfif arrayLen(bytes) gte 12>
		<cfset head = binaryEncode(createObject("java", "java.util.Arrays").copyOfRange(bytes, 0, 12), "hex")>
	</cfif>
	<cfif left(head, 16) eq "89504E470D0A1A0A">
		<cfset ext = "png">
	<cfelseif left(head, 6) eq "FFD8FF">
		<cfset ext = "jpg">
	<cfelseif left(head, 8) eq "47494638">
		<cfset ext = "gif">
	<cfelseif left(head, 8) eq "52494646" and mid(head, 17, 8) eq "57454250">
		<cfset ext = "webp">
	<cfelseif findNoCase("image/svg+xml", header)>
		<cfset ext = "svg">
	</cfif>
	<cfreturn { ext = ext, bytes = bytes }>
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

<cffunction name="saveFooter" access="public" returntype="void" output="false"
		hint="The footer the Site Wizard builds (2026-10-20, owner): from what the wizard knows - About and Contact links (no social icons since 2026-10-27: they are in the Bio window), with the first lines of their bio for 'blurb' - or switched off for 'none'. No email address (spam). footer.cfm adds the copyright and version lines under it by itself. Changed later in the Themes window's Content tab.">
	<cfargument name="style" type="string" required="true">
	<cfset var owner = getOwner()>
	<cfset var links = starterLinks()>
	<cfset var parts = []>
	<cfset var icons = []>
	<cfset var html = "">
	<cfset var bio = "">
	<cfset var net = "">
	<!--- A footer the owner made themselves (in Themes) is never replaced: only the default one, or one this wizard wrote. --->
	<cfif footerIsCustom()><cfreturn></cfif>
	<cfset application.events.setSetting(0, "setupFooter", arguments.style)>
	<!--- None: just the basics - footer.cfm's own logo and version lines, without links. (A footer can't be switched off: footer.cfm
	always adds the version and copyright.) Only reached for the default footer or one this wizard wrote, never the owner's own. --->
	<!--- 5.0 (owner, 2026-10-27): no links in the footer - no About page or Contact yet (to revisit next version) - so Simple is the
	standard footer, the same as "none": the logo and the version line, like gregoryalexander.com and galaxieblog.org. --->
	<cfif arguments.style eq "none" or arguments.style eq "simple">
		<cfset application.blog.saveContentOutput(contentTemplate = "compositeFooter", themeId = "", revertDesktop = "true")>
		<cfset application.blog.saveContentOutput(contentTemplate = "compositeFooter", themeId = "", revertMobile = "true")>
		<cfset application.events.setSetting(0, "setupFooterHash", "")>
		<cfset application.blog.flushGalaxieCache(type = "all")>
		<cfreturn>
	</cfif>
	<!--- No About or Contact links in 5.0 (see above). --->
	<!--- No social icons in the footer (owner, 2026-10-27): they are in the Bio window. --->
	<cfif not isNull(owner)>
		<cfif arguments.style eq "blurb">
			<cfset bio = trim(reReplace(owner.getBiography() ?: "", "<[^>]*>", " ", "all"))>
			<cfset bio = reReplace(bio, "\s+", " ", "all")>
			<cfif len(bio) gt 220><cfset bio = left(bio, 217) & "..."></cfif>
		</cfif>
	</cfif>
	<!--- A blurb with nothing written about yourself would be an empty footer: the standard one instead. --->
	<cfif not len(bio) and not arrayLen(parts)>
		<cfset saveFooter("simple")>
		<cfreturn>
	</cfif>
	<cfset html = '<div class="siteFooter" style="text-align: center;">'>
	<cfif len(bio)><cfset html = html & '<p>' & encodeForHtml(bio) & '</p>'></cfif>
	<cfif arrayLen(parts)><cfset html = html & '<p>' & arrayToList(parts, ' &middot; ') & '</p>'></cfif>
	<cfset html = html & '</div>'>
	<cfset application.blog.saveContentOutput(contentTemplate = "compositeFooter", themeId = "", contentOutputDesktop = html, contentOutputMobile = html, active = "true")>
	<!--- Remember exactly what was written, so a later run can tell this footer from one the owner changed. --->
	<cfset application.events.setSetting(0, "setupFooterHash", hash(html))>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="footerIsCustom" access="public" returntype="boolean" output="false"
		hint="Whether the footer was written by the owner (in Themes) rather than being the default or the one the Site Wizard made - then the Site Wizard leaves it alone.">
	<cfset var rows = queryExecute("SELECT o.ContentOutput FROM ContentOutput o JOIN ContentTemplate t ON t.ContentTemplateId = o.ContentTemplateRef WHERE t.ContentTemplateName = 'compositeFooter' AND o.ContentOutput IS NOT NULL",
		{}, { datasource = application.dsn })>
	<cfset var made = application.events.getSetting(0, "setupFooterHash", "")>
	<cfset var row = 0>
	<cfloop query="rows">
		<cfif len(trim(rows.ContentOutput)) and hash(toString(rows.ContentOutput)) neq made><cfreturn true></cfif>
	</cfloop>
	<cfreturn false>
</cffunction>

<!---//*****************************************************************************************************
		Screen 5: your home page
//******************************************************************************************************--->

<cffunction name="saveHome" access="public" returntype="void" output="false" hint="The home page layout (posts: latest posts; about: the About page as the whole home page; featured: the About page above the latest posts; keep: leave the home page as it is) and the post hero style. The layout is applied when the owner presses Done, after the starter pages exist.">
	<cfargument name="layout" type="string" required="true">
	<cfargument name="heroStyle" type="string" required="false" default="classic">
	<cfargument name="footer" type="string" required="false" default="" hint="simple, blurb or none (2026-10-20); empty leaves the footer as it is.">
	<cfset var optionObj = entityLoadByPK("BlogOption", application.BlogOptionDbObj.getBlogOptionId())>
	<cfif not listFind("posts,about,featured,keep", arguments.layout)><cfset fail("Please choose a home page layout.")></cfif>
	<cfif listFind("simple,blurb,none", arguments.footer)>
		<cfset saveFooter(arguments.footer)>
	</cfif>
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

<cffunction name="saveStarter" access="public" returntype="struct" output="false" hint="Creates a welcome post, an About page and a contact form, each only once (a second run finds the first by its title). The posts are ordinary posts the owner edits or deletes; the contact form (5.0, owner 10-20) is a ready-made Contact form named 'Contact (About page)', placed at the end of a new About page, and answers go to the blog's email.">
	<cfargument name="welcomePost" type="boolean" required="false" default="false">
	<cfargument name="aboutPage" type="boolean" required="false" default="false">
	<cfargument name="contactForm" type="boolean" required="false" default="false">
	<cfset var owner = getOwner()>
	<cfset var made = { welcomePostId = 0, aboutPageId = 0, contactFormId = 0 }>
	<cfset var blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfset var aboutBody = "">
	<cfset var contact = {}>
	<cfset var existingForm = {}>
	<cfif isNull(owner)><cfset fail("The blog owner's account couldn't be found.")></cfif>
	<cfif arguments.welcomePost>
		<!--- The getting-started post (5.0, owner 2026-10-27): what visitors see is this short welcome; the owner, signed in, also sees
		what is left to set up and the features under it (renderGettingStarted). It is the home page until another post is released. --->
		<cfset made.welcomePostId = makePost("blogPost", owner.getUserId(), "Welcome to " & blogTitle,
			"A new site: the first post is on its way.",
			"<p>Welcome to " & encodeForHtml(blogTitle) & "! This site is brand new, and the first post is on its way. Please come back soon.</p>",
			"linear-gradient(135deg, ##1d4350 0%, ##a43931 100%)")>
		<cfset application.events.setSetting(0, "gettingStartedPostId", made.welcomePostId)>
		<cfset structDelete(application, "galaxieGettingStarted")>
		<!--- The 4.x welcome text, kept for reference:
		<cfset made.welcomePostId = makePost("blogPost", owner.getUserId(), "Welcome to " & blogTitle,
			"The first post on " & blogTitle & ".",
			"<p>Welcome to " & encodeForHtml(blogTitle) & "! This is the first post. <a href=""{editLink}"">Edit it</a> to say hello in your own words, or delete it once you have written your own. (Later you will find it in the administration under Posts and Pages, then Posts: click its title in the list.)</p><p>To write a new post, sign in and choose Create Post on the administration page.</p>",
			"linear-gradient(135deg, ##1d4350 0%, ##a43931 100%)")>
		--->
	</cfif>
	<cfif arguments.contactForm and structKeyExists(application, "webForms")>
		<cfloop array="#application.webForms.getForms()#" index="existingForm">
			<cfif existingForm.title eq "Contact (About page)"><cfset contact = { webFormId = existingForm.webFormId, alias = existingForm.alias }></cfif>
		</cfloop>
		<cfif structIsEmpty(contact)>
			<cfset contact = application.webForms.useReadyMade("contact", "About page")>
			<cfif not contact.success><cfset fail("The contact form couldn't be made: " & arrayToList(contact.errors, " "))></cfif>
		</cfif>
		<cfset made.contactFormId = contact.webFormId>
	</cfif>
	<cfif arguments.aboutPage>
		<cfset aboutBody = len(owner.getBiography() ?: "") ? owner.getBiography() : "<p>Tell your visitors who you are and what this site is about. <a href=""{editLink}"">Edit this page</a> to make it yours. (Later you will find it in the administration under Posts and Pages, then Pages: click About in the list.)</p>">
		<!--- The contact form at the end, as Insert Form places one. --->
		<cfif not structIsEmpty(contact)>
			<cfset aboutBody = aboutBody & '<h2>Get in touch</h2><div class="galaxieWebForm" data-webform="' & encodeForHtmlAttribute(contact.alias) & '">[Form: Contact]</div>'>
		</cfif>
		<cfset made.aboutPageId = makePost("page", owner.getUserId(), "About", "About " & blogTitle & ".", aboutBody,
			"linear-gradient(135deg, ##355c7d 0%, ##6c5b7b 50%, ##c06c84 100%)")>
	</cfif>
	<cfset markDone("starter")>
	<cfreturn made>
</cffunction>

<!---//*****************************************************************************************************
		Getting started (5.0, owner 2026-10-27): the wizard's first post. Shown on its own as the home page until another post is
		released, then hidden (Remove) automatically. Visitors see its short welcome; the signed-in owner also sees, under it, what is
		left to set up (worked out each time, so it ticks itself off) and a short tour of the features (renderGettingStarted).
//******************************************************************************************************--->

<cffunction name="gettingStartedPostId" access="public" returntype="numeric" output="false" hint="The getting-started post's id while it is the home page, or 0. Once another blog post is released it hides the getting-started post (Remove) and returns 0 from then on. Looked up at most once a minute.">
	<cfset var id = 0>
	<cfset var others = 0>
	<cfset var live = 0>
	<cfif structKeyExists(application, "galaxieGettingStarted") and dateDiff("s", application.galaxieGettingStarted.checked, now()) lt 60>
		<cfreturn application.galaxieGettingStarted.id>
	</cfif>
	<cftry>
		<cfset id = val(application.events.getSetting(0, "gettingStartedPostId", ""))>
		<cfif id>
			<cfset live = ormExecuteQuery("SELECT Post.Released FROM Post as Post WHERE Post.PostId = :id AND Post.Remove = :no", { id = id, no = false })>
			<cfif not arrayLen(live)>
				<!--- Deleted or removed by the owner: it's done for good. --->
				<cfset application.events.setSetting(0, "gettingStartedPostId", "")>
				<cfset id = 0>
			<cfelseif not (isBoolean(live[1]) and live[1])>
				<!--- Unreleased for now: not shown, but it comes back if it's released again. --->
				<cfset id = 0>
			<cfelse>
				<cfset others = ormExecuteQuery("SELECT count(Post.PostId) FROM Post as Post WHERE Post.PostId <> :id AND Post.Released = :yes AND Post.Remove = :no AND (Post.IsPage = :no OR Post.IsPage IS NULL) AND Post.BlogRef.BlogId = :blogId",
					{ id = id, yes = true, no = false, blogId = application.BlogDbObj.getBlogId() })[1]>
				<cfif not val(others)>
					<!--- A site built from pages (2026-10-28): once Configure Homepage shows pages or collections, those are the home page.
					Not shown then, but kept: it comes back if the home page goes back to the post list before a post is out. --->
					<cftry>
						<cfset var homeSettings = application.blog.getHomepageSettings()>
						<cfif (homeSettings.showPages and listLen(homeSettings.pageIdList)) or homeSettings.showCollections>
							<cfset id = 0>
						</cfif>
						<cfcatch type="any"></cfcatch>
					</cftry>
				<cfelse>
					<!--- The first real post is out: the getting-started post steps aside (kept, as a removed post). --->
					<cfset queryExecute("UPDATE Post SET Remove = :yes WHERE PostId = :id", { yes = { value = true, cfsqltype = "cf_sql_bit" }, id = { value = id, cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
					<cfset application.events.setSetting(0, "gettingStartedPostId", "")>
					<cfset id = 0>
					<cftry><cfset application.blog.flushGalaxieCache(type = "all")><cfcatch type="any"></cfcatch></cftry>
				</cfif>
			</cfif>
		</cfif>
		<cfcatch type="any">
			<cfset id = 0>
		</cfcatch>
	</cftry>
	<cfset application.galaxieGettingStarted = { id = id, checked = now() }>
	<cfreturn id>
</cffunction>

<cffunction name="renderGettingStarted" access="public" returntype="string" output="false" hint="The signed-in owner's part of the getting-started post: what is left to set up (live) and the features, each with a link that opens its window in the administrator (admin/?open=).">
	<cfset var admin = application.baseUrl & "/admin/">
	<cfset var steps = []>
	<cfset var features = []>
	<cfset var html = "">
	<cfset var item = {}>
	<cfset var stepsDone = "">
	<cfset var owner = "">
	<cfset var paymentsReady = false>
	<cfset var i = 0>
	<cftry><cfset stepsDone = application.BlogOptionDbObj.getSetupStepsDone() ?: ""><cfcatch type="any"></cfcatch></cftry>
	<cftry><cfset owner = getOwner()><cfcatch type="any"></cfcatch></cftry>
	<cftry><cfset paymentsReady = structKeyExists(application, "payments") and application.payments.getStatus().ready><cfcatch type="any"></cfcatch></cftry>
	<cfset arrayAppend(steps, { done = application.blog.mailIsSetUp(), title = "Email",
		text = "Add your mail server in Blog Settings, then press Send a test email. Comment notices, subscriber emails and the Contact link in the menu need it.",
		link = admin & "?open=settings", label = "Blog Settings" })>
	<cfset arrayAppend(steps, { done = listFindNoCase(stepsDone, "look") and listFindNoCase(stepsDone, "logo"), title = "Your look and logo",
		text = "Pick a theme and a logo in the Site Wizard. You can change the look any time in Themes.",
		link = admin & "setup.cfm", label = "Site Wizard" })>
	<cfset arrayAppend(steps, { done = not isNull(owner) and isObject(owner) and (len(owner.getProfilePicture() ?: "") or len(trim(owner.getBiography() ?: ""))), title = "About you",
		text = "Add your picture and a few lines about yourself. They show under your posts.",
		link = admin & "?open=profile", label = "Your profile" })>
	<cfset arrayAppend(steps, { done = paymentsReady, title = "Payments (only to sell)",
		text = "The shop, paid bookings and paid events take payment through Stripe. Add your Stripe keys in Blog Options when you are ready.",
		link = admin & "?open=payments", label = "Payments" })>
	<!--- A post or a page (owner, 2026-10-28: Galaxie builds sites, not only blogs). --->
	<cfset arrayAppend(steps, { done = false, title = "Your first post or page",
		text = "Write a blog post, or build a page: an About page, a service with bookings, a shop page. Release a post and it takes this page's place on the home page; for a site built from pages, set your home page to show them in Configure Homepage, and this page steps aside.",
		link = admin & "?open=post", label = "Create Post", link2 = admin & "?open=page", label2 = "Create Page", link3 = admin & "?open=homepage", label3 = "Configure Homepage" })>

	<cfset features = [
		{ title = "Pictures, galleries and video", text = "In the post editor's Insert menu: pictures, galleries, carousels, YouTube and your own videos, and maps with routes.", link = admin & "?open=post", label = "Create Post" },
		{ title = "Heroes and scenes", text = "A large picture, a gradient or an animated parallax scene at the top of a post or page, with your own heading.", link = admin & "?open=scenes", label = "Scenes" },
		{ title = "Bookings", text = "Let people book a time with you: free consultations or paid sessions, with your own availability.", link = admin & "?open=bookings", label = "Bookings" },
		{ title = "Shop", text = "Sell products and downloads, with a cart and Stripe checkout.", link = admin & "?open=shop", label = "Shop" },
		{ title = "Events", text = "Event posts with a date card, sign-ups and paid tickets.", link = admin & "?open=events", label = "Events" },
		{ title = "Forms", text = "Contact and sign-up forms you can place in any post or page.", link = admin & "?open=forms", label = "Forms" },
		{ title = "Members and subscribers", text = "Visitors can subscribe to new posts, or sign in as members with an emailed link.", link = admin & "?open=members", label = "Members" },
		{ title = "Visitors and traffic", text = "Who reads what, where they came from, and the bots kept out of the counts.", link = admin & "?open=traffic", label = "Traffic Sources" },
		{ title = "Themes", text = "Over 25 themes, each with its own colors, fonts and header; customize any of them beside a live preview.", link = admin & "?open=themes", label = "Themes" }
	]>

	<cfsavecontent variable="html"><cfoutput>
<style>
	.galaxieGettingStarted { margin: 24px 0; }
	.galaxieGettingStarted h2 { margin: 26px 0 6px; }
	.galaxieGettingStarted .gsNote { opacity: .8; font-size: 90%; }
	.galaxieGettingStarted .gsList { list-style: none; padding: 0; margin: 10px 0; }
	.galaxieGettingStarted .gsList li { display: flex; gap: 12px; align-items: flex-start; padding: 12px 14px; border-radius: 8px; margin-bottom: 8px; }
	.galaxieGettingStarted .gsMark { flex: 0 0 26px; height: 26px; border-radius: 50%; border: 2px solid currentColor; display: flex; align-items: center; justify-content: center; font-weight: bold; opacity: .55; }
	.galaxieGettingStarted .gsDone .gsMark { opacity: 1; background: ##1a7f37; border-color: ##1a7f37; color: white; }
	.galaxieGettingStarted .gsBody { flex: 1; }
	.galaxieGettingStarted .gsBody strong { display: block; }
	.galaxieGettingStarted .gsDone .gsBody strong { text-decoration: line-through; opacity: .7; }
	.galaxieGettingStarted .gsBody a { white-space: nowrap; }
</style>
<div class="galaxieGettingStarted">
	<blockquote class="k-notification-info"><p><strong>Only you see this part</strong> (you are signed in). Visitors see the welcome above.
	This post stays on your home page until you release your first post, then it steps aside by itself.</p></blockquote>
	<h2>What's left to set up</h2>
	<ul class="gsList"><cfloop array="#steps#" index="item">
		<li class="#item.done ? 'gsDone k-content' : 'k-alt'#"><span class="gsMark">#item.done ? "&##10003;" : ""#</span>
			<span class="gsBody"><strong>#encodeForHtml(item.title)#</strong>#encodeForHtml(item.text)# <a href="#encodeForHtmlAttribute(item.link)#">#encodeForHtml(item.label)# &rsaquo;</a><cfif structKeyExists(item, "link2")> &nbsp; <a href="#encodeForHtmlAttribute(item.link2)#">#encodeForHtml(item.label2)# &rsaquo;</a></cfif><cfif structKeyExists(item, "link3")> &nbsp; <a href="#encodeForHtmlAttribute(item.link3)#">#encodeForHtml(item.label3)# &rsaquo;</a></cfif></span></li>
	</cfloop></ul>
	<h2>What Galaxie can do</h2>
	<p class="gsNote">Each link opens its window in the administrator.</p>
	<ul class="gsList"><cfloop from="1" to="#arrayLen(features)#" index="i">
		<li class="#i mod 2 ? 'k-content' : 'k-alt'#"><span class="gsBody"><strong>#encodeForHtml(features[i].title)#</strong>#encodeForHtml(features[i].text)# <a href="#encodeForHtmlAttribute(features[i].link)#">#encodeForHtml(features[i].label)# &rsaquo;</a></span></li>
	</cfloop></ul>
</div>
</cfoutput></cfsavecontent>
	<cfreturn html>
</cffunction>

<cffunction name="makePost" access="private"returntype="numeric" output="false" hint="A released post or page with this title, made now - or the existing one with this title.">
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
	<!--- {editLink} in the text (2026-10-20): a link that opens this post in the editor (the admin home opens ?editPost=). --->
	<!--- savePost reads the author without declaring it as an argument, so it is passed by name. --->
	<cfset application.blog.savePost(postId = postId, postType = arguments.postType, author = arguments.authorId, title = arguments.title, description = arguments.description,
		post = replace(arguments.body, "{editLink}", application.baseUrl & "/admin/?editPost=" & postId, "all"), released = true, emailSubscriber = false)>
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
	<!--- "keep" (2026-10-24) changes nothing: an updated blog's own home page settings stay. --->
	<cfset optionObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
	<cfset optionObj.setSetupFinished(dateTimeFormat(application.blog.blogNow(), "yyyy-mm-dd HH:nn"))>
	<cfset entitySave(optionObj)>
	<cfset ormFlush()>
	<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", optionObj.getBlogOptionId())>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="sendHello" access="public" returntype="boolean" output="false"
		hint="Say hello (5.0.x, 2026-10-31, owner): on the owner's say-so (two boxes on the Site Wizard's last screen), tells Galaxie Blog's author that this blog is running - its name, address, Galaxie version, engine and database - and, with addToCfblogs, asks to be added to cfblogs.org with its feed and the owner's email. Posted to https://galaxieblog.org (no www: the www address redirects, and a redirected post arrives as a GET) - common/services/newBlogHello.cfm there, which emails the author. Waits at most 5 seconds; a failure never stops the wizard. Returns true when the note was taken.">
	<cfargument name="addToCfblogs" type="boolean" required="false" default="false">
	<cfargument name="toUrl" type="string" required="false" default="https://galaxieblog.org/common/services/newBlogHello.cfm" hint="Where the note goes; another address only for testing.">
	<cfset var engine = application.serverProduct & " " & (server.coldfusion.productVersion ?: "")>
	<cfset var result = {}>
	<cfif application.serverProduct eq "Lucee" and structKeyExists(server, "lucee")><cfset engine = "Lucee " & server.lucee.version></cfif>
	<cftry>
		<cfhttp url="#arguments.toUrl#" method="post" timeout="5" result="result" redirect="true">
			<cfhttpparam type="formfield" name="siteName" value="#application.BlogDbObj.getBlogTitle()#">
			<cfhttpparam type="formfield" name="siteUrl" value="#application.blogHostUrl#">
			<cfhttpparam type="formfield" name="version" value="#application.blog.getVersion()#">
			<cfhttpparam type="formfield" name="engine" value="#engine#">
			<cfhttpparam type="formfield" name="database" value="#application.databaseType ?: ''#">
			<cfhttpparam type="formfield" name="addToCfblogs" value="#arguments.addToCfblogs#">
			<cfif arguments.addToCfblogs>
				<cfhttpparam type="formfield" name="feedUrl" value="#application.blogHostUrl#/rss.cfm">
				<cfhttpparam type="formfield" name="email" value="#application.BlogDbObj.getBlogEmail()#">
			</cfif>
		</cfhttp>
		<cfreturn left(result.statusCode ?: "", 3) eq "200">
		<cfcatch type="any"><cfreturn false></cfcatch>
	</cftry>
</cffunction>

</cfcomponent>

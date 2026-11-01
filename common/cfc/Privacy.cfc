<cfcomponent displayName="Privacy" output="false" hint="Privacy (5.0.x, 2026-10-31, owner): the blog's privacy page and the Google Analytics consent banner. The page is an ordinary page titled Privacy, made once - the first time the admin home is opened after this update - from what this blog actually collects and uses at that moment; the owner changes it like any page. Every blog's footer links to it. The banner shows only when Google Analytics is set up (Blog Options) and the owner hasn't switched it off; Google Analytics then loads only after a visitor agrees. Used through blog.cfc getPrivacy().">

<cffunction name="getPageId" access="public" returntype="numeric" output="false" hint="The privacy page's PostId, or 0 when there is none (never made, or removed).">
	<cfset var id = val(application.events.getSetting(0, "privacyPostId", "0"))>
	<cfset var found = []>
	<cfif id gt 0>
		<cfset found = ormExecuteQuery("SELECT PostId FROM Post WHERE PostId = :id AND (Remove = :removed OR Remove IS NULL)", { id = id, removed = false })>
	</cfif>
	<cfreturn arrayLen(found) ? id : 0>
</cffunction>

<cffunction name="getPageUrl" access="public" returntype="string" output="false" hint="The privacy page's address, or an empty string.">
	<cfset var id = getPageId()>
	<cfreturn id gt 0 ? application.blog.makeLink(id) : "">
</cffunction>

<cffunction name="ensurePage" access="public" returntype="numeric" output="false" hint="Makes the privacy page once, for an owner signed in to the admin. A page already titled Privacy is used as it is. Never makes a second one, and never changes the page after it is made.">
	<cfargument name="authorId" type="numeric" required="true">
	<cfset var id = getPageId()>
	<cfset var existing = []>
	<cfif id gt 0 or arguments.authorId lte 0><cfreturn id></cfif>
	<cflock name="galaxiePrivacyPage_#application.applicationName#" type="exclusive" timeout="30">
		<cfset id = getPageId()>
		<cfif id eq 0>
			<!--- A page the owner already wrote, titled Privacy (or Privacy Policy), is the one used. --->
			<cfset existing = ormExecuteQuery("SELECT PostId FROM Post WHERE Title IN ('Privacy', 'Privacy Policy', 'Privacy policy') AND (Remove = :removed OR Remove IS NULL) ORDER BY PostId", { removed = false })>
			<cfif arrayLen(existing)>
				<cfset id = existing[1]>
			<cfelse>
				<cfset id = application.blog.insertNewPost(postType = "page", author = arguments.authorId, title = "Privacy",
					description = "How " & application.BlogDbObj.getBlogTitle() & " handles your information.")>
				<cfset application.blog.savePost(postId = id, postType = "page", author = arguments.authorId, title = "Privacy",
					description = "How " & application.BlogDbObj.getBlogTitle() & " handles your information.", post = templateHtml(), released = true, emailSubscriber = false)>
				<!--- savePost releases only for someone allowed to release posts; the privacy page is always out. --->
				<cfset local.privacyPost = entityLoadByPK("Post", id)>
				<cfif not isNull(local.privacyPost) and local.privacyPost.getReleased() neq 1>
					<cfset local.privacyPost.setReleased(true)>
					<cfset entitySave(local.privacyPost)>
					<cfset ormFlush()>
				</cfif>
			</cfif>
			<cfset application.events.setSetting(0, "privacyPostId", id)>
			<!--- The footer, which links to it, is a saved page part. --->
			<cfset application.blog.flushGalaxieCache(type = "all")>
		</cfif>
	</cflock>
	<cfreturn id>
</cffunction>

<cffunction name="consentNeeded" access="public" returntype="boolean" output="false" hint="True when the consent banner shows: Google Analytics is set up and the owner hasn't switched the banner off (Blog Options).">
	<cfreturn len(trim(application.googleAnalyticsString ?: "")) gt 0 and application.events.getSetting(0, "analyticsConsentBanner", "1") neq "0">
</cffunction>

<!---//*****************************************************************************************************
		The starting text: what this blog collects, worded plainly. The owner changes it like any page.
//******************************************************************************************************--->

<cffunction name="templateHtml" access="private" returntype="string" output="false">
	<cfset var title = encodeForHtml(application.BlogDbObj.getBlogTitle())>
	<cfset var visitorMonths = val(application.monthsToRetainVisitorLog ?: 0)>
	<cfset var logMonths = val(application.monthsToRetainAdminLog ?: 0)>
	<cfset var uses = { forms: hasRows("WebForm"), bookings: hasRows("BookingType"), shop: hasRows("Product"), members: hasRows("BlogMember"), events: hasRows("BlogEvent") }>
	<cfset var analytics = len(trim(application.googleAnalyticsString ?: "")) gt 0>
	<!--- What visitors can do here, for the "Forms, bookings..." part: what they do, and its heading. --->
	<cfset var doing = []>
	<cfset var headings = []>
	<cfset var html = "">
	<cfif uses.forms><cfset arrayAppend(doing, "send a form")><cfset arrayAppend(headings, "Forms")></cfif>
	<cfif uses.bookings><cfset arrayAppend(doing, "book a time")><cfset arrayAppend(headings, "bookings")></cfif>
	<cfif uses.events><cfset arrayAppend(doing, "sign up for an event")><cfset arrayAppend(headings, "events")></cfif>
	<cfif uses.shop><cfset arrayAppend(doing, "place an order")><cfset arrayAppend(headings, "orders")></cfif>
	<cfif uses.members><cfset arrayAppend(headings, "accounts")></cfif>
	<cfif arrayLen(headings)><cfset headings[1] = uCase(left(headings[1], 1)) & mid(headings[1], 2, 100)></cfif>
	<cfsavecontent variable="html"><cfoutput>
<blockquote class="k-notification-info"><p><b>This page was written for you by Galaxie Blog</b> from what your blog collects today. Please read it and change anything that doesn't fit your site. Then delete this note.</p></blockquote>
<p>This page explains what #title# collects when you visit, why, how long it's kept, and who else sees it. In short: we keep what we need to run the site, we don't sell it, and we delete it on a schedule.</p>
<h2>When you visit</h2>
<p>Like most websites, this one keeps a log of visits: your IP address, your browser (its "user agent"), the page you opened, the site you came from, and the time. We use it to count visits, to see which pages are read, and to spot and block bots and abuse. <cfif visitorMonths gt 0>Visits are deleted automatically after #visitorMonths# month<cfif visitorMonths neq 1>s</cfif>.</cfif> When something goes wrong on a page, the error is logged with the same details so it can be fixed<cfif logMonths gt 0>; error records are deleted after #logMonths# month<cfif logMonths neq 1>s</cfif></cfif>.</p>
<h2>Cookies</h2>
<ul>
	<li><b>A session cookie</b> keeps your visit together from page to page. It doesn't follow you to other sites.</li>
	<li><b>Comment details:</b> if you tick "Remember me" when you comment, your name, email address and website are kept in your browser for a year so you don't have to type them again. Untick it to forget them.</li>
	<li><b>Your theme</b>, if you pick one, is remembered in your browser.</li>
	<cfif analytics><li><b>Google Analytics</b> cookies, only if you agree (see below).</li></cfif>
</ul>
<h2>Comments</h2>
<p>When you leave a comment we keep your name, email address, website (if you give one) and the comment. Your name, website and comment are shown on the site; your email address is never shown. It's used to tell you about replies if you ask, and to show your picture: a coded version of your email address (not the address itself) is sent to <a href="https://gravatar.com" rel="noopener">Gravatar</a>, which returns the picture you set up there, if any.</p>
<h2>Email subscriptions</h2>
<p>If you subscribe, we keep your email address and use it only to send you new posts (and, if you ask, replies to a post you follow). Every email has a link to unsubscribe.</p>
<cfif arrayLen(doing) or uses.members>
<h2>#joinWords(headings, "and")#</h2>
<p><cfif arrayLen(doing)>When you #joinWords(doing, "or")#, we keep what you enter so we can answer you and do what you asked<cfif uses.shop>, and for our records</cfif>.</cfif><cfif uses.members> If you create an account, we keep your name, email address and what you add to your profile; you sign in with a link we email you, so there's no password to store.</cfif></p>
<cfif uses.bookings or uses.events or uses.shop><p>Payments are handled by <a href="https://stripe.com/privacy" rel="noopener">Stripe</a>. Your card details go straight to Stripe; we never see or store them.</p></cfif>
</cfif>
<cfif analytics>
<h2>Google Analytics</h2>
<p>With your permission, we use Google Analytics to understand how the site is used. It doesn't run until you agree, and you can change your mind at any time with the <b>Privacy choices</b> link at the bottom of every page. Google's own <a href="https://policies.google.com/privacy" rel="noopener">privacy policy</a> explains what it does with the data.</p>
</cfif>
<h2>Content from other sites</h2>
<p>Some pages show things that load from other services, such as videos (YouTube, Vimeo), maps (Microsoft Azure Maps), fonts and code libraries from public content networks. When they load, your browser contacts those services directly, as with any website, and they see your IP address.</p>
<h2>What we don't do</h2>
<p>We don't sell or rent your information, and we don't share it except as described here or when the law requires it.</p>
<h2>Your choices</h2>
<p>You can ask to see the information we hold about you, have it corrected, or have it deleted. To ask, <a href="#application.blogHostUrl#/?contact">contact us</a>.</p>
<p><i>Last updated #dateFormat(application.blog.blogNow(), "mmmm d, yyyy")#.</i></p>
	</cfoutput></cfsavecontent>
	<cfreturn trim(html)>
</cffunction>

<!--- "a", "a and b", "a, b and c" --->
<cffunction name="joinWords" access="private" returntype="string" output="false">
	<cfargument name="words" type="array" required="true">
	<cfargument name="lastJoin" type="string" required="true">
	<cfset var count = arrayLen(arguments.words)>
	<cfif count eq 0><cfreturn ""></cfif>
	<cfif count eq 1><cfreturn arguments.words[1]></cfif>
	<cfreturn arrayToList(arraySlice(arguments.words, 1, count - 1), ", ") & " " & arguments.lastJoin & " " & arguments.words[count]>
</cffunction>

<cffunction name="hasRows" access="private" returntype="boolean" output="false" hint="True when this blog has anything in a table (a feature it uses). False when the table is missing.">
	<cfargument name="tableName" type="string" required="true">
	<cftry>
		<cfreturn queryExecute("SELECT COUNT(*) AS N FROM #arguments.tableName#", {}, { datasource: application.dsn }).N gt 0>
		<cfcatch type="any"><cfreturn false></cfcatch>
	</cftry>
</cffunction>

</cfcomponent>

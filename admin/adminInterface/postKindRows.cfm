<!--- The shared rows of the Create and Edit Post windows (2026-11-08, owner: "keep both interfaces identical"), included twice by newPost.cfm
(pkMode "create") and postDetail.cfm (pkMode "edit"). pkPart "kind" draws Blog post and Page at the top of the window. pkPart "layout" draws
Layout right under Title (owner), which in Edit Post is right above the Hero or Scene row it changes. A scrolling scene is a layout of an article
or a page, not a kind of post of its own, so making one takes two choices: Article or Page, then Scrolling scene. Layout shows only for Article
and Page; a real request can add it to the others. Each row alternates, with its description above its choices. Needs thisContentClass and
HtmlUtilsObj, and leaves thisContentClass ready for the row after it. Set first: pkMode, pkPart, pkSmall, and for "edit" postIsEvent, postIsBooking,
postIsShop, postEventWhen, postBookingLabel, postShopLabel, postSceneIsFull, getPost. --->
<cfsilent>
<cfset pkCreate = pkMode eq "create">
<cfif pkCreate>
	<cfset pkOpt = URL.optArgs ?: "">
	<cfset pkType = pkOpt eq "newPage" ? "page" : (pkOpt eq "newPageCollection" ? "pageCollection" : (pkOpt eq "newEvent" ? "event" : (pkOpt eq "newBooking" ? "booking" : (pkOpt eq "newShop" ? "shop" : "blogPost"))))>
	<cfset pkLayout = pkOpt eq "newScene" ? "scene" : "standard">
<cfelse>
	<cfset pkType = postIsEvent ? "event" : (postIsBooking ? "booking" : (postIsShop ? "shop" : (getPost[1]['IsPage'] ? "page" : "blogPost")))>
	<cfset pkLayout = postSceneIsFull ? "scene" : "standard">
</cfif>
<cfsavecontent variable="pkBlogPost"><cfoutput>
	<div class="k-form-hint" style="display: block; margin-bottom: 6px;">Dated and listed newest first on your blog, in the RSS feed and in subscriber emails, and can have comments. An <b>event</b> is an article with a date, time and place that visitors can add to their calendar or sign up for.</div>
	<label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" <cfif pkCreate>id="blogPost"</cfif> value="blogPost" <cfif pkType eq "blogPost">checked</cfif> /> Article</label><label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" <cfif pkCreate>id="event"</cfif> value="event" <cfif pkType eq "event">checked</cfif> /> Event</label>
	<cfif not pkCreate><span class="postEventRow"><button type="button" class="k-button" id="postEventDetails">Event details</button> <span class="k-form-hint" id="postEventSummary">#encodeForHtml(postEventWhen)#</span></span></cfif>
</cfoutput></cfsavecontent>
<cfsavecontent variable="pkPage"><cfoutput>
	<div class="k-form-hint" style="display: block; margin-bottom: 6px;">Stays up as it is: no date, no comments, not in the RSS feed, and linked from your menu. A <b>booking</b> page adds a booking form, so visitors can book a time with you, a <b>shop</b> page lists products to buy, and a <b>page collection</b> is an index that links to several of your pages, like a Portfolio or Services section.<cfif not pkCreate> An existing post or page can't become a collection: make one with Create.</cfif></div>
	<label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" <cfif pkCreate>id="page"</cfif> value="page" <cfif pkType eq "page">checked</cfif> /> Page</label><label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" <cfif pkCreate>id="booking"</cfif> value="booking" <cfif pkType eq "booking">checked</cfif> /> Booking</label><label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" <cfif pkCreate>id="shop"</cfif> value="shop" <cfif pkType eq "shop">checked</cfif> /> Shop</label><cfif pkCreate><label class="postTypeChoice"><input class="k-radio" type="radio" name="postType" id="pageCollection" value="pageCollection" <cfif pkType eq "pageCollection">checked</cfif> /> Page Collection</label><cfelse><label class="postTypeChoice k-disabled"><input class="k-radio" type="radio" name="postTypeCollection" disabled /> Page Collection</label></cfif>
	<cfif not pkCreate><span class="postBookingRow"><button type="button" class="k-button" id="postBookingDetails">Booking details</button> <span class="k-form-hint" id="postBookingSummary">#encodeForHtml(postBookingLabel)#</span></span> <span class="postShopRow"><button type="button" class="k-button" id="postShopDetails">Shop details</button> <span class="k-form-hint" id="postShopSummary">#encodeForHtml(postShopLabel)#</span></span></cfif>
</cfoutput></cfsavecontent>
<cfsavecontent variable="pkLayoutHtml"><cfoutput>
	<div class="k-form-hint" style="display: block; margin-bottom: 6px;">How this is arranged. Most posts use Standard.</div>
	<label class="postTypeChoice" style="display: block; margin-bottom: 4px;"><input class="k-radio" type="radio" name="postLayout" value="standard" <cfif pkLayout neq "scene">checked</cfif> /> <b>Standard:</b> a hero at the top, then your text</label>
	<label class="postTypeChoice" style="display: block;"><input class="k-radio" type="radio" name="postLayout" value="scene" <cfif pkLayout eq "scene">checked</cfif> /> <b>Scrolling scene:</b> a full-page story that rises in as readers scroll</label>
</cfoutput></cfsavecontent>
<cfif pkPart eq "layout">
	<!--- Plain, like the Title above it in each window: only the main choices at the top are bold (owner, 2026-11-08). --->
	<cfset pkRows = [ { label: pkCreate ? "<label>Layout:</label>" : "<label>Layout</label>", html: pkLayoutHtml, rowClass: "postLayoutRow" } ]>
<cfelse>
	<cfset pkRows = [ { label: "Blog post:", html: pkBlogPost, rowClass: "" }, { label: "Page:", html: pkPage, rowClass: "" } ]>
</cfif>
</cfsilent>
<cfloop from="1" to="#arrayLen(pkRows)#" index="pkIndex">
	<cfif pkIndex gt 1>
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	</cfif>
	<cfoutput>
	<cfif pkIndex gt 1><tr height="1px" class="#pkRows[pkIndex].rowClass#"><td align="left" valign="top" colspan="2" class="border #thisContentClass#"></td></tr></cfif>
	<cfif pkSmall>
	<tr class="#pkRows[pkIndex].rowClass#"><td class="#thisContentClass#" colspan="2"><h4 class="adminBlockHeading">#pkRows[pkIndex].label#</h4> #pkRows[pkIndex].html#</td></tr>
	<cfelse>
	<tr valign="top" height="35" class="#pkRows[pkIndex].rowClass#"><td align="right" valign="top" class="#thisContentClass#" style="width: 20%"><h4 class="adminBlockHeading">#pkRows[pkIndex].label#</h4></td><td class="#thisContentClass#">#pkRows[pkIndex].html#</td></tr>
	</cfif>
	</cfoutput>
</cfloop>
<cfif pkPart eq "layout">
	<!--- The row's own borders hide with it, so the row above runs straight into the row below. --->
	<cfoutput><tr height="2px" class="postLayoutRow"><td align="left" valign="top" colspan="2" class="#thisContentClass#"></td></tr></cfoutput>
	<cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	<cfoutput><tr height="2px" class="postLayoutRow"><td align="left" valign="top" colspan="2" class="border #thisContentClass#"></td></tr></cfoutput>
<script>
	<!--- Layout is for articles and pages. With its row hidden, the rows below it swap shades, so the colors still alternate. --->
	window.galaxiePostLayoutRowSync = function () {
		var chosen = $("input[name=postType]:checked").val();
		var show = chosen === "blogPost" || chosen === "page";
		var rows = $(".postLayoutRow");
		var wasHidden = rows.first().data("layoutHidden") === true;
		rows.toggle(show);
		if (wasHidden === show) { rows.last().nextAll("tr").children("td").filter(".k-content, .k-alt").toggleClass("k-content k-alt"); }
		rows.first().data("layoutHidden", !show);
	};
	$("input[name=postType]").on("change", window.galaxiePostLayoutRowSync);
	window.galaxiePostLayoutRowSync();
</script>
</cfif>

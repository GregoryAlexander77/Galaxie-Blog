<cfset temporarillyBypassSecurity = false>
<!--- Don't allow anyone who is not authorized to consume this page, since it can overwrite post content. --->
<cfif temporarillyBypassSecurity or (application.Udf.isLoggedIn() and listFindNoCase(session.capabilityList, 'EditPost'))>

<!---
	retrofitTocAnchors.cfm

	One-time (repeatable) migration utility that rewrites the anchor ids the built-in TinyMCE 'toc'
	plugin generates (eg. id="mcetoc_1j30ce75hj") into descriptive, url-friendly slugs built from each
	heading's own text (eg. id="background", or id="background-1" for a repeated heading). This mirrors
	the rewriteTocAnchors() logic that now runs automatically in the post editor (see
	blog/includes/templates/js/tinyMce.cfm and blog/admin/adminInterface/postDetail.cfm) for posts
	saved going forward - this template lets you retrofit posts that were saved before that change.

	How to use:
	  1. Open this page in your browser while logged in as an admin with the EditPost capability.
	     By default it runs as a DRY RUN - it reports exactly what it *would* change without touching
	     the database.
	  2. Review the report. Each post lists its old ids alongside the new slug they'd become.
	  3. When you're happy with the results, click the "Save these changes" link at the bottom of the
	     report (or add ?commit=true to the URL) to actually update the posts.
	  4. This is safe to run more than once - it only touches headings that still have the old
	     mcetoc_ ids, so already-migrated posts are simply skipped the next time.
--->

<cfparam name="url.commit" type="boolean" default="false">

<cfscript>
	// Turn a heading's raw inner HTML (which may contain nested tags like <strong> or a trailing
	// &nbsp;) into a lower-case, dash-separated, url-fragment-safe slug.
	function slugifyHeadingText(required string rawText) {
		// Strip any nested HTML tags (eg. <strong>, <em>, <span>) to get plain text.
		var text = REReplaceNoCase(arguments.rawText, "<[^>]*>", "", "all");
		// Decode &nbsp; to a plain space, then decode the remaining core HTML entities.
		text = Replace(text, "&nbsp;", " ", "all");
		// XmlDecode() only exists in some engines (it is undefined on Adobe ColdFusion), so decode the core entities by hand. &amp; goes last.
		text = Replace(text, "&lt;", "<", "all");
		text = Replace(text, "&gt;", ">", "all");
		text = Replace(text, "&quot;", '"', "all");
		text = Replace(text, "&##39;", "'", "all");
		text = Replace(text, "&apos;", "'", "all");
		text = Replace(text, "&amp;", "&", "all");
		text = trim(text);
		text = lCase(text);
		// Collapse anything that isn't a-z/0-9 into a single dash, then trim leading/trailing dashes.
		var slug = REReplaceNoCase(text, "[^a-z0-9]+", "-", "all");
		slug = REReplaceNoCase(slug, "^-+|-+$", "", "all");
		if (!len(slug)) {
			slug = "section";
		}
		return slug;
	}

	// Finds every <h1-6 id="mcetoc_..."> heading in a chunk of HTML and returns an array of
	// {oldId, innerHtml} structs, in document order.
	function extractMceTocHeadings(required string html) {
		var found = [];
		var pattern = '<h[1-6][^>]*id\s*=\s*"(mcetoc_[a-zA-Z0-9]+)"[^>]*>([\s\S]*?)</h[1-6]>';
		var startPos = 1;
		var searchLen = len(arguments.html);

		while (startPos <= searchLen) {
			var matchInfo = REFindNoCase(pattern, arguments.html, startPos, true);
			if (matchInfo.pos[1] == 0) {
				break;
			}
			arrayAppend(found, {
				oldId: mid(arguments.html, matchInfo.pos[2], matchInfo.len[2]),
				innerHtml: mid(arguments.html, matchInfo.pos[3], matchInfo.len[3])
			});
			startPos = matchInfo.pos[1] + matchInfo.len[1];
		}
		return found;
	}

	// Finds every existing heading id in a chunk of HTML (any prefix, not just mcetoc_), so we can
	// avoid handing out a new slug that collides with a heading id that's already in use.
	function extractAllHeadingIds(required string html) {
		var found = [];
		var pattern = '<h[1-6][^>]*id\s*=\s*"([a-zA-Z0-9_\-]+)"[^>]*>';
		var startPos = 1;
		var searchLen = len(arguments.html);

		while (startPos <= searchLen) {
			var matchInfo = REFindNoCase(pattern, arguments.html, startPos, true);
			if (matchInfo.pos[1] == 0) {
				break;
			}
			arrayAppend(found, mid(arguments.html, matchInfo.pos[2], matchInfo.len[2]));
			startPos = matchInfo.pos[1] + matchInfo.len[1];
		}
		return found;
	}

	// Rewrites the mcetoc_ ids found across a post's Body and MoreBody fields into descriptive,
	// deduplicated slugs, keeping the toc plugin's <a href="#..."> links pointed at the right heading.
	// Returns a struct: {body, moreBody, changes} where changes is an array of
	// {oldId, newId, headingText} for every heading that was actually renamed.
	function rewriteTocAnchorsForPost(required string body, required string moreBody) {
		var usedSlugs = {};
		var changes = [];
		var newBody = arguments.body;
		var newMoreBody = arguments.moreBody;

		// Seed usedSlugs with every heading id already in the post (migrated or not) so a newly
		// generated slug never collides with an id that's already there.
		for (var existingId in extractAllHeadingIds(arguments.body)) {
			usedSlugs[existingId] = true;
		}
		for (var existingId in extractAllHeadingIds(arguments.moreBody)) {
			usedSlugs[existingId] = true;
		}

		// Gather the headings that still need to be migrated, in document order (Body, then MoreBody -
		// MoreBody only appears after a "Read More" click, so it always follows Body).
		var headingsFound = extractMceTocHeadings(arguments.body);
		for (var h in extractMceTocHeadings(arguments.moreBody)) {
			arrayAppend(headingsFound, h);
		}

		for (var heading in headingsFound) {
			var baseSlug = slugifyHeadingText(heading.innerHtml);
			var newSlug = baseSlug;

			// Only append a numeric suffix when the plain slug is not already unique on this post.
			var counter = 1;
			while (structKeyExists(usedSlugs, newSlug)) {
				newSlug = baseSlug & "-" & counter;
				counter++;
			}
			usedSlugs[newSlug] = true;

			newBody = Replace(newBody, 'id="' & heading.oldId & '"', 'id="' & newSlug & '"', "all");
			newBody = Replace(newBody, 'href="##' & heading.oldId & '"', 'href="##' & newSlug & '"', "all");
			newMoreBody = Replace(newMoreBody, 'id="' & heading.oldId & '"', 'id="' & newSlug & '"', "all");
			newMoreBody = Replace(newMoreBody, 'href="##' & heading.oldId & '"', 'href="##' & newSlug & '"', "all");

			arrayAppend(changes, {
				oldId: heading.oldId,
				newId: newSlug,
				headingText: REReplaceNoCase(heading.innerHtml, "<[^>]*>", "", "all")
			});
		}

		return {
			body: newBody,
			moreBody: newMoreBody,
			changes: changes
		};
	}
</cfscript>

<!--- Find every post whose Body or MoreBody still contains an mcetoc_ id. The underscore is escaped
      since it's a single-character wildcard in SQL/HQL LIKE patterns. The escape character is ! and not a backslash, as MySQL treats a backslash in a string as its own escape and the query fails. --->
<!--- An HQL query returns an array, not a query object (Adobe ColdFusion and Lucee). The new Map() makes each row a struct, like the queries in blog.cfc. --->
<cfquery name="getCandidatePosts" dbtype="hql" ormoptions="#{maxresults=5000}#">
	SELECT new Map (
		p.PostId as PostId,
		p.Title as Title
	)
	FROM Post p
	WHERE p.Body LIKE '%mcetoc!_%' ESCAPE '!' OR p.MoreBody LIKE '%mcetoc!_%' ESCAPE '!'
	ORDER BY p.PostId
</cfquery>

<cfset totalPostsChanged = 0>
<cfset totalAnchorsRewritten = 0>
<cfset totalErrors = 0>

<style>
	body { font-family: Arial, sans-serif; font-size: 13px; }
	table { border-collapse: collapse; margin-bottom: 25px; width: 100%; }
	th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; vertical-align: top; }
	th { background: #f0f0f0; }
	.oldId { color: #999; text-decoration: line-through; }
	.newId { color: #0a7d1f; font-weight: bold; }
	.noChanges { color: #999; font-style: italic; }
	.errorRow { color: #b00020; }
	.commitBtn { display: inline-block; padding: 10px 18px; background: #0a7d1f; color: #fff; text-decoration: none; border-radius: 4px; }
	.summary { font-size: 15px; margin: 15px 0; }
</style>

<cfoutput>

<h2>Retrofit TOC Anchors</h2>

<cfif not url.commit>
	<p><strong>This is a dry run.</strong> Nothing has been saved. Review the changes below, then click "Save these changes" at the bottom of the page to actually update these #arrayLen(getCandidatePosts)# post(s).</p>
<cfelse>
	<p><strong>Commit mode.</strong> Changes below have been saved to the database.</p>
</cfif>

<cfif arrayLen(getCandidatePosts) eq 0>
	<p>No posts were found with any leftover mcetoc_ anchors. Nothing to do.</p>
<cfelse>

	<table>
		<tr>
			<th>Post</th>
			<th>Changes</th>
		</tr>

		<cfloop array="#getCandidatePosts#" index="candidate">

			<cftry>
				<cfset PostDbObj = entityLoad("Post", { postId = candidate['PostId'] }, "true")>
				<cfset rewriteResult = rewriteTocAnchorsForPost(PostDbObj.getBody(), PostDbObj.getMoreBody())>

				<tr>
					<td>
						###candidate['PostId']#: <strong>#candidate['Title']#</strong><br/>
						<a href="#application.blog.getPostUrlByPostId(candidate['PostId'])#" target="_blank" rel="noopener noreferrer">view post</a>
					</td>
					<td>
						<cfif arrayLen(rewriteResult.changes) eq 0>
							<span class="noChanges">No mcetoc_ anchors found (already migrated, or the toc was inserted but never used).</span>
						<cfelse>
							<ul>
							<cfloop array="#rewriteResult.changes#" index="change">
								<li>&quot;#change.headingText#&quot; &mdash; <span class="oldId">###change.oldId#</span> &rarr; <span class="newId">###change.newId#</span></li>
							</cfloop>
							</ul>

							<cfif url.commit>
								<cfset PostDbObj.setBody(rewriteResult.body)>
								<cfset PostDbObj.setMoreBody(rewriteResult.moreBody)>
								<cftransaction>
									<cfset EntitySave(PostDbObj)>
								</cftransaction>
								<cfset totalPostsChanged++>
								<cfset totalAnchorsRewritten += arrayLen(rewriteResult.changes)>
								<div style="color:##0a7d1f;">Saved.</div>
							</cfif>
						</cfif>
					</td>
				</tr>

				<cfcatch type="any">
					<cfset totalErrors++>
					<tr class="errorRow">
						<td>###candidate['PostId']#: #candidate['Title']#</td>
						<td>Error: #cfcatch.message# #cfcatch.detail#</td>
					</tr>
				</cfcatch>
			</cftry>

		</cfloop>
	</table>

</cfif>

<cfif url.commit>
	<p class="summary">Done. Updated #totalPostsChanged# post(s), rewrote #totalAnchorsRewritten# anchor(s)<cfif totalErrors gt 0><span style="color:##b00020;"> (#totalErrors# error(s), see above)</span></cfif>.</p>
<cfelseif arrayLen(getCandidatePosts) gt 0>
	<p><a class="commitBtn" href="?commit=true">Save these changes</a></p>
</cfif>

</cfoutput>

<cfelse>
	<p>You must be logged in with the EditPost capability to run this template.</p>
</cfif>

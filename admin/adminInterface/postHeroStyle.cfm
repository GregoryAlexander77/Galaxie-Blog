<!--- A post's hero style (window 120, 11-04, owner: the Hero window had "a lot of stuff at the bottom", so its Hero style cards moved
into a window of their own, opened from the Hero window's toolbar). How the hero shows on the post's own page: the cards are
heroStyleCards.cfm, as in Blog Options; a click saves it (ProxyController.cfc savePostHeroStyle). A moving hero or a full-page scene
has its own look, so the cards don't show for one. optArgs is the postId. --->
<cfsilent>
<cfset heroStylePost = entityLoadByPK("Post", val(URL.optArgs))>
<cfset heroStyleScene = isNull(heroStylePost) ? {} : application.blog.getScenes().getPostSceneStill(val(URL.optArgs))>
<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
</cfsilent>
<cfif isNull(heroStylePost)>
	<p>This post no longer exists.</p>
	<cfexit>
</cfif>
<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="<cfoutput>#blockClass#</cfoutput>" style="padding: 8px 12px;">
	<cfif heroStyleScene.sceneId gt 0 and heroStyleScene.isMovingHero>
		This post's hero is a moving hero, which has its own style: where its heading sits and how it gives way to the post are chosen in the <a href="javascript:createAdminInterfaceWindow(119, <cfoutput>#val(URL.optArgs)#</cfoutput>);">Moving hero</a> wizard.
	<cfelseif heroStyleScene.sceneId gt 0>
		This post shows a full-page scene, which has its own look. To change it, open the scene from the Scenes icon on the admin home page.
	<cfelse>
		How the hero shows on this post's own page. Point at a card to see it move; a click saves it. Carousels, maps and videos always show as they are.
		<span id="postHeroStyleSaved" class="k-form-hint" style="margin-left: 6px;"></span>
		<cfset heroCardsId = "postHeroStyle">
		<cfset heroCardsName = "">
		<cfset heroCardsValue = heroStylePost.getHeroStyle() ?: "">
		<cfset heroCardsBlogChoice = createObject("component", application.rendererComponentPath).getPostHeroStyle("")>
		<cfset heroCardsSmall = true>
		<cfinclude template="heroStyleCards.cfm">
		<!--- How the heading moves (5.03, 11-06, owner): the Moving hero wizard's choices, for the scene styles. The classic hero has no
		scroll effects, so the choice is greyed out for it. Saved on change (ProxyController.cfc savePostHeroTextMotion). --->
		<cfset heroTextMotionValue = heroStylePost.getHeroTextMotion() ?: "">
		<cfset heroTextMotionSplit = application.blog.getScenes().getSetting("librarySource", "cdn") neq "local" or arrayFind(application.blog.getScenes().getLocalLibraryFiles(), "SplitText.min.js")>
		<div style="margin-top: 14px;">
			<label for="postHeroTextMotion" class="adminBlockHeading" style="display: block; margin-bottom: 6px;">How the heading moves</label>
			<select id="postHeroTextMotion" style="width: 360px; max-width: 95%;">
				<option value="">Rises and fades as you scroll</option>
				<option value="slideIn"<cfif heroTextMotionValue eq "slideIn"> selected</cfif>>Slides up into place, then rises and fades as you scroll</option>
				<option value="slideInStay"<cfif heroTextMotionValue eq "slideInStay"> selected</cfif>>Slides up into place</option>
				<option value="slideInOut"<cfif heroTextMotionValue eq "slideInOut"> selected</cfif>>Slides up into place, then up and away as it scrolls off</option>
				<cfif heroTextMotionSplit or listFind("words,letters", heroTextMotionValue)>
				<option value="words"<cfif heroTextMotionValue eq "words"> selected</cfif>>Comes in word by word, then rises and fades</option>
				<option value="letters"<cfif heroTextMotionValue eq "letters"> selected</cfif>>Comes in letter by letter, then rises and fades</option>
				</cfif>
				<option value="still"<cfif heroTextMotionValue eq "still"> selected</cfif>>Stays in place on the picture</option>
			</select>
			<span id="postHeroTextMotionSaved" class="k-form-hint" style="margin-left: 6px;"></span>
			<div id="postHeroTextMotionHint" class="k-form-hint" style="margin-top: 4px;"></div>
		</div>
		<script>
			(function () {
				var blogChoice = "<cfoutput>#encodeForJavaScript(heroCardsBlogChoice)#</cfoutput>";
				var hasHeading = <cfoutput>#len(heroStylePost.getHeroOverlayText() ?: "") ? "true" : "false"#</cfoutput>;
				var list = $("#postHeroTextMotion").kendoDropDownList({ change: function () {
					$("#postHeroTextMotionSaved").text("Saving...");
					jQuery.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeroTextMotion",
						data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#val(URL.optArgs)#</cfoutput>, textMotion: this.value() },
						dataType: "json",
						success: function (response) {
							if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
							if (response && response.success) { $("#postHeroTextMotionSaved").text("Saved."); }
							else {
								$("#postHeroTextMotionSaved").text("");
								$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "How the heading moves could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
							}
						},
						error: function (jqXHR, textStatus, error) {
							$("#postHeroTextMotionSaved").text("");
							if (jqXHR.status === 403) { createLoginWindow(); } else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
						}
					});
				} }).data("kendoDropDownList");
				<!--- Greyed out for the classic style; a note when there is no heading yet. --->
				function sync() {
					var style = $("#postHeroStyle").val() || blogChoice;
					var classic = style === "classic";
					list.enable(!classic);
					$("#postHeroTextMotionHint").text(classic ? "Only for the Held, Band, Magazine and Parallax styles. The classic hero's heading stays in place."
						: (hasHeading ? "" : "This post's hero has no heading yet: add one with Hero text in the Hero window."));
				}
				$("#postHeroStyle").on("change.heroTextMotion", sync);
				sync();
			})();
		</script>
		<script>
			$("#postHeroStyle").off("change.heroStyle").on("change.heroStyle", function () {
				$("#postHeroStyleSaved").text("Saving...");
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeroStyle",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#val(URL.optArgs)#</cfoutput>, heroStyle: $(this).val() },
					dataType: "json",
					success: function (response) {
						if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
						if (response && response.success) {
							$("#postHeroStyleSaved").text("Saved.");
							if (typeof galaxieHeroSummaryRefresh === "function") { galaxieHeroSummaryRefresh(); }
						} else {
							$("#postHeroStyleSaved").text("");
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The hero style could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
						}
					},
					error: function (jqXHR, textStatus, error) {
						$("#postHeroStyleSaved").text("");
						if (jqXHR.status === 403) { createLoginWindow(); } else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
					}
				});
			});
		</script>
	</cfif>
	</td></tr>
</table>

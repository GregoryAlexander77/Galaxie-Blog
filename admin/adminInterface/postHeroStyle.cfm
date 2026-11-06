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

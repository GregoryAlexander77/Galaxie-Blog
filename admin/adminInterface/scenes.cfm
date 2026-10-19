<!--- Scenes window (window 106, 2026-10-19, Galaxie 5), the Scenes icon on the admin home page: every scene, the scrolling
heroes built by common/js/galaxieScene.js. New scene and Edit open the Scene editor (window 107). A post shows a scene with
<galaxieScene>name</galaxieScene> in its header. The work is done by application.blog.getScenes() (common/cfc/Scenes.cfc)
through ProxyController.cfc. See doc/aiDraftArticles/parallaxScenesDesign.cfm. --->
<cfset sceneList = application.blog.getScenes().listScenes()>

<script>
	<!--- Called by the Scene editor after a save, so the list stays current. --->
	function refreshScenesWindow() {
		try {
			$("#scenesWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}

	function deleteScene(sceneId, sceneName) {
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete " + sceneName + "?", message: "Posts that show this scene will show nothing in its place. This can't be undone.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
			if (answer['button'] !== 'Yes') { return; }
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteScene",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", sceneId: sceneId },
				dataType: "json",
				success: function(response) {
					if (response && response.success) {
						refreshScenesWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		});
	}
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">A scene is a scrolling hero for a post or page: layered pictures that move at different speeds, a photo, an animation or a gradient, with your heading and text rising over it. Start from a ready-made scene and change the words and pictures; the preview shows it as you go.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Scenes look best with a modern theme and the sidebar hidden.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(107, 0);">New scene</button></td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not sceneList.recordCount>
			No scenes yet. Click New scene to make one.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Scene</th>
						<th align="left">Name in posts</th>
						<th align="left">Shown on</th>
						<th align="left">Status</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody>
				<cfloop query="sceneList">
					<cfset thisUsedBy = arrayLen(application.blog.getScenes().getPostIdsUsing(sceneList.Alias))>
					<cfset thisUsedText = thisUsedBy eq 0 ? "No posts yet" : thisUsedBy & (thisUsedBy eq 1 ? " post" : " posts")>
					<cfset thisStatus = sceneList.Active eq 1 ? "Active" : "Inactive">
					<cfset thisJsName = encodeForJavaScript(sceneList.Name)>
					<cfif session.isMobile>
					<tr>
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							<a href="javascript:createAdminInterfaceWindow(107, #sceneList.SceneId#);">#encodeForHtml(sceneList.Name)#</a><br>
							#encodeForHtml(sceneList.Alias)#. #thisUsedText#. #thisStatus#<br>
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(107, #sceneList.SceneId#);">Edit</button>
							<button type="button" class="k-button" onclick="deleteScene(#sceneList.SceneId#, '#encodeForHtmlAttribute(thisJsName)#');">Delete</button>
						</td>
					</tr>
					<cfelse>
					<tr>
						<td style="border-top: 1px solid ##ddd;"><a href="javascript:createAdminInterfaceWindow(107, #sceneList.SceneId#);">#encodeForHtml(sceneList.Name)#</a></td>
						<td style="border-top: 1px solid ##ddd;">#encodeForHtml(sceneList.Alias)#</td>
						<td style="border-top: 1px solid ##ddd;">#thisUsedText#</td>
						<td style="border-top: 1px solid ##ddd;">#thisStatus#</td>
						<td style="border-top: 1px solid ##ddd;" align="right" nowrap="nowrap">
							<button type="button" class="k-button" onclick="createAdminInterfaceWindow(107, #sceneList.SceneId#);">Edit</button>
							<button type="button" class="k-button" onclick="deleteScene(#sceneList.SceneId#, '#encodeForHtmlAttribute(thisJsName)#');">Delete</button>
						</td>
					</tr>
					</cfif>
				</cfloop>
				</tbody>
			</table>
		</cfif>
		</td>
	</tr>
</table>
</cfoutput>

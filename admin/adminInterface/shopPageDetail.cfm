<!--- Shop page (window 116, 2026-10-21), opened with createAdminInterfaceWindow(116, postId) from the post editor's Shop details
button, New post > Shop, and the Products window. A shop page is a Page whose text is followed by products: every product shown on
the site, or the ones picked here (common/cfc/Shop.cfc, Shop pages). Saved straight away by ProxyController.cfc's saveShopPage;
Make it an ordinary page takes the products off (removeShopPage). --->
<cfset shopPagePostId = val(URL.optArgs)>
<cfset shopPagePost = application.blog.getPostByPostId(postId = shopPagePostId, showPendingPosts = true, showRemovedPosts = true)>
<cfset shopPageOffer = application.shop.getPageOffer(shopPagePostId)>
<cfset shopPageProducts = application.shop.listProducts(activeOnly = true)>

<script>
	$(document).ready(function() {
		function closeWindow() {
			try { $("#shopPageWindow").data("kendoWindow").close(); } catch (error) {}
		}
		<!--- The product list is only for "Only these products". --->
		function refreshChoice() { $(".shopPagePickRow").toggle($("input[name=shopPageOffer]:checked").val() === "pick"); }
		$("input[name=shopPageOffer]").on("change", refreshChoice);
		refreshChoice();

		$("#shopPageSave").on("click", function() {
			var offer = "*";
			if ($("input[name=shopPageOffer]:checked").val() === "pick") {
				offer = $("input.shopPageProduct:checked").map(function() { return this.value; }).get().join(",");
				if (!offer) {
					kendo.ui.ExtAlertDialog.show({ title: "Choose the products", message: "Tick the products this page shows, or choose Every product.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
					return;
				}
			}
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveShopPage",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#shopPagePostId#</cfoutput>, offer: offer },
				dataType: "json",
				success: function(response) {
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (!response || !response.success) {
						kendo.ui.ExtAlertDialog.show({ title: "Not saved", message: $("<div>").text((response && response.errorMessage) || "The shop page could not be saved.").html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
						return;
					}
					<!--- The post editor keeps its Post Type row current. --->
					$(document).trigger("galaxieShopPageSaved", [{ postId: <cfoutput>#shopPagePostId#</cfoutput>, label: response.label }]);
					try { refreshProductsWindow(); } catch (error) {}
					closeWindow();
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});

		$("#shopPageRemove").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Make it an ordinary page?", message: "The products come off the page. The page and its text stay.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeShopPage",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#shopPagePostId#</cfoutput> },
					dataType: "json",
					success: function(response) {
						if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
						if (response && response.success) {
							$(document).trigger("galaxieShopPageRemoved", [{ postId: <cfoutput>#shopPagePostId#</cfoutput> }]);
							try { refreshProductsWindow(); } catch (error) {}
							closeWindow();
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<!--- No heading (owner, 10-22): the window title already says "Shop page", and the page's own title repeated it. --->
	<tr><td colspan="2" class="#blockClass#">A shop page is a page where visitors buy from you. It stays up for as long as you sell: it isn't dated and doesn't go out in your RSS feed. The page's own text shows first, then the products, each with an Add to cart button.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">What the page shows: every product (new ones join it by themselves), or only the ones you pick. <a href="javascript:createAdminInterfaceWindow(111);">Shop</a></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Shows:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="shopPageOffer" value="*"<cfif shopPageOffer eq "*" or not len(shopPageOffer)> checked</cfif>> Every product</label><br/>
			<label><input type="radio" class="k-radio" name="shopPageOffer" value="pick"<cfif len(shopPageOffer) and shopPageOffer neq "*"> checked</cfif>> Only these products</label>
		</td>
	</tr>
	<tr class="blockSpacer shopPagePickRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="shopPagePickRow">
		<td class="#blockClass#"></td>
		<td class="#blockClass#">
		<cfif not arrayLen(shopPageProducts)>
			You have no products shown on the site yet. <a href="javascript:createAdminInterfaceWindow(112, 0);">Add a product</a>.
		<cfelse>
			<cfloop array="#shopPageProducts#" index="thisProduct">
				<label><input type="checkbox" class="k-checkbox shopPageProduct" value="#encodeForHtmlAttribute(thisProduct.alias)#"<cfif shopPageOffer neq "*" and listFind(shopPageOffer, thisProduct.alias)> checked</cfif>> #encodeForHtml(thisProduct.name)# (#thisProduct.priceText#)</label><br/>
			</cfloop>
		</cfif>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" id="shopPageSave">Save</button><cfif len(shopPageOffer)> <button type="button" class="k-button" id="shopPageRemove">Make it an ordinary page</button></cfif></td>
	</tr>
</table>
</cfoutput>

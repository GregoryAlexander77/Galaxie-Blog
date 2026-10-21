<!--- A product (window 112, 2026-10-21), opened from Products (111) with createAdminInterfaceWindow(112, productId); 0 makes a new
one. Saved by ProxyController.cfc's saveShopProduct -> application.shop.saveProduct (common/cfc/Shop.cfc), which checks everything
again. The picture goes to /images/shop/ (uploadShopProductImage); a download's file goes to the shop's private folder
(uploadShopProductFile), so a new download product is saved first, then its file is added. --->
<cfset productId = val(URL.optArgs)>
<cfset shopProduct = productId gt 0 ? application.shop.getProduct(productId = productId) : {}>
<cfset isNewProduct = structIsEmpty(shopProduct)>
<cfif isNewProduct>
	<cfset shopProduct = { productId: 0, name: "", description: "", imageUrl: "", kind: "physical", price: "", shippingPrice: "",
		trackStock: false, stock: 0, active: true, hasFile: false, fileDisplayName: "" }>
</cfif>
<cfset shopSettings = application.shop.getSettings()>

<script>
	$(document).ready(function() {
		var productId = <cfoutput>#shopProduct.productId#</cfoutput>;
		var csrf = '<cfoutput>#csrfToken#</cfoutput>';
		var proxy = '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc';
		var dialogWidth = "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>";
		function alertBox(title, message, icon) {
			$.when(kendo.ui.ExtAlertDialog.show({ title: title, message: message, icon: icon || "k-ext-warning", width: dialogWidth }));
		}

		<!--- Only what the chosen kind needs: shipping for a shipped item, the file for a download. --->
		function refreshKind() {
			var kind = $("input[name=productKind]:checked").val();
			$(".productShippingRow").toggle(kind === "physical");
			$(".productFileRow").toggle(kind === "digital");
		}
		$("input[name=productKind]").on("change", refreshKind);
		refreshKind();
		$("#productTrackStock").on("change", function() { $("#productStock").prop("disabled", !this.checked); }).trigger("change");

		<!--- Uploads: the picture (any time) and a download's file (once the product is saved). --->
		function upload(method, file, extra, status, done) {
			if (!file) { return; }
			var data = new FormData();
			data.append("csrfToken", csrf);
			$.each(extra, function(key, value) { data.append(key, value); });
			data.append("file", file);
			status.text("Uploading " + file.name + "...");
			jQuery.ajax({
				type: "post", url: proxy + "?method=" + method, data: data, processData: false, contentType: false, dataType: "json",
				success: function(response) {
					status.text("");
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) { done(response); } else { alertBox("Could not upload", (response && response.errorMessage) || "The file could not be uploaded."); }
				},
				error: function(jqXHR, textStatus, error) {
					status.text("");
					if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error while uploading", error, "k-ext-error"); }
				}
			});
		}
		$("#productImageButton").on("click", function() { $("#productImageInput").trigger("click"); });
		$("#productImageInput").on("change", function() {
			upload("uploadShopProductImage", this.files[0], {}, $("#productImageStatus"), function(response) {
				$("#productImageUrl").val(response.url);
				$("#productImagePreview").attr("src", response.url).show();
				$("#productImageRemove").show();
			});
			this.value = "";
		});
		$("#productImageRemove").on("click", function() {
			$("#productImageUrl").val("");
			$("#productImagePreview").hide();
			$(this).hide();
		});
		$("#productFileButton").on("click", function() { $("#productFileInput").trigger("click"); });
		$("#productFileInput").on("change", function() {
			upload("uploadShopProductFile", this.files[0], { productId: productId }, $("#productFileStatus"), function(response) {
				$("#productFileName").text(response.displayName);
				try { refreshProductsWindow(); } catch (error) {}
			});
			this.value = "";
		});

		$("#productSubmit").on("click", function() {
			var productData = {
				productId: productId,
				name: $.trim($("#productName").val()),
				kind: $("input[name=productKind]:checked").val(),
				description: $.trim($("#productDescription").val()),
				imageUrl: $("#productImageUrl").val(),
				price: $.trim($("#productPrice").val()),
				shippingPrice: $.trim($("#productShipping").val()),
				trackStock: $("#productTrackStock").is(":checked"),
				stock: $("#productStock").val(),
				active: $("#productActive").is(":checked")
			};
			if (!productData.name.length) { alertBox("Please check the product", "Give the product a name."); return; }
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the product.", width: dialogWidth, icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post', url: proxy + '?method=saveShopProduct',
				data: { csrfToken: csrf, productJson: JSON.stringify(productData) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) {
						try { refreshProductsWindow(); } catch (error) {}
						<!--- A new download product stays open, saved, so its file can be added. --->
						var needsFile = productData.kind === "digital" && productId === 0;
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: needsFile ? "The product was saved. Now upload the file buyers will download." : "The product was saved.", icon: "k-ext-information" })).done(function() {
							$('#productDetailWindow').kendoWindow('destroy');
							if (needsFile) { createAdminInterfaceWindow(112, response.productId); }
						});
					} else {
						alertBox("Could not save", ((response && response.errorMessage) || "The product could not be saved.").replace(/\n/g, "<br>"));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error while saving the product", error, "k-ext-error"); }
				}
			});
		});

		$("#productDelete").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete this product?", message: "A product that was never ordered is deleted. One with orders is hidden instead, so its orders keep their history.", icon: "k-ext-question", width: dialogWidth })).done(function(answer) {
				if (answer.button !== "Yes") { return; }
				jQuery.ajax({
					type: 'post', url: proxy + '?method=deleteShopProduct', data: { csrfToken: csrf, productId: productId }, dataType: "json",
					success: function(response) {
						if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
						if (response && response.success) {
							try { refreshProductsWindow(); } catch (error) {}
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Done", message: response.message || "The product was deleted.", icon: "k-ext-information" })).done(function() {
								$('#productDetailWindow').kendoWindow('destroy');
							});
						} else { alertBox("Could not delete", (response && response.errorMessage) || "The product could not be deleted."); }
					},
					error: function(jqXHR, textStatus, error) { if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error", error, "k-ext-error"); } }
				});
			});
		});
	});//...document.ready
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<form id="productDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">What it is</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="productName">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="productName" class="k-textbox" maxlength="255" placeholder="eg. Joshua Tree print, 11x14" value="#encodeForHtmlAttribute(shopProduct.name)#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Kind:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="productKind" value="physical"<cfif shopProduct.kind eq "physical"> checked</cfif>> Shipped (a physical item, mailed to the buyer)</label><br/>
			<label><input type="radio" class="k-radio" name="productKind" value="digital"<cfif shopProduct.kind eq "digital"> checked</cfif>> Download (a file, like a PDF or a zip)</label><br/>
			<label><input type="radio" class="k-radio" name="productKind" value="service"<cfif shopProduct.kind eq "service"> checked</cfif>> Service (nothing to send, like a consultation)</label>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="productDescription">Description:</label></td>
		<td class="#blockClass#"><textarea id="productDescription" class="k-textbox" rows="3" style="width: 95%;" placeholder="A line or two that shows under the name">#encodeForHtml(shopProduct.description)#</textarea></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Price</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="productPrice">Price:</label></td>
		<td class="#blockClass#"><input type="text" id="productPrice" class="k-textbox" inputmode="decimal" placeholder="19.99" value="#len(shopProduct.price) ? numberFormat(shopProduct.price, '0.00') : ''#" style="width: 120px;"> <span class="k-form-hint">#encodeForHtml(shopSettings.currency)#, before tax. Tax is set in Blog Options &gt; Payments.</span></td>
	</tr>
	<tr class="blockSpacer productShippingRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="productShippingRow"><td colspan="2" class="#blockClass#">One flat shipping price; leave it empty for free shipping. An order pays the highest shipping of its items, once.</td></tr>
	<tr class="blockSpacer productShippingRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="productShippingRow">
		<td class="#blockClass#" align="right"><label for="productShipping">Shipping:</label></td>
		<td class="#blockClass#"><input type="text" id="productShipping" class="k-textbox" inputmode="decimal" placeholder="Free" value="#len(shopProduct.shippingPrice) and val(shopProduct.shippingPrice) gt 0 ? numberFormat(shopProduct.shippingPrice, '0.00') : ''#" style="width: 120px;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Picture</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Picture:</td>
		<td class="#blockClass#">
			<input type="hidden" id="productImageUrl" value="#encodeForHtmlAttribute(shopProduct.imageUrl)#">
			<img id="productImagePreview" src="#encodeForHtmlAttribute(shopProduct.imageUrl)#" alt="" style="width: 120px; height: 120px; object-fit: cover; border-radius: 6px; vertical-align: middle;<cfif not len(shopProduct.imageUrl)> display: none;</cfif>">
			<input type="file" id="productImageInput" accept="image/jpeg,image/png,image/webp,image/gif" style="display: none;">
			<button type="button" id="productImageButton" class="k-button k-primary">Upload picture</button>
			<button type="button" id="productImageRemove" class="k-button"<cfif not len(shopProduct.imageUrl)> style="display: none;"</cfif>>Remove</button>
			<span id="productImageStatus" class="k-form-hint"></span>
		</td>
	</tr>
	<tr class="blockSpacer productFileRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="productFileRow"><td colspan="2" class="#blockClass#">The file is kept in a private folder. Buyers get a link that works for #shopSettings.downloadDays# days or #shopSettings.downloadLimit# downloads (change that in Products &gt; Shop settings).</td></tr>
	<tr class="blockSpacer productFileRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="productFileRow">
		<td class="#blockClass#" align="right">File:</td>
		<td class="#blockClass#">
		<cfif isNewProduct>
			Save the product first, then upload its file.
		<cfelse>
			<span id="productFileName">#shopProduct.hasFile ? encodeForHtml(shopProduct.fileDisplayName) : "No file yet"#</span>
			<input type="file" id="productFileInput" style="display: none;">
			<button type="button" id="productFileButton" class="k-button k-primary">#shopProduct.hasFile ? "Replace the file" : "Upload the file"#</button>
			<span id="productFileStatus" class="k-form-hint"></span>
		</cfif>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>

	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Stock</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="productTrackStock">Count stock:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" class="k-checkbox" id="productTrackStock"<cfif shopProduct.trackStock> checked</cfif>>
			<input type="number" id="productStock" class="k-textbox" min="0" step="1" value="#shopProduct.stock#" style="width: 90px;"> left
			<span class="k-form-hint">At 0 it shows Sold out.</span>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="productActive">Shown on the site:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="productActive"<cfif shopProduct.active> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#">
			<button id="productSubmit" type="button" class="k-button k-primary">Save</button>
			<cfif not isNewProduct><button id="productDelete" type="button" class="k-button">Delete</button></cfif>
		</td>
	</tr>
</table>
</form>
</cfoutput>

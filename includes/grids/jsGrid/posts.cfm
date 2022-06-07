<!doctype html>
<cfsilent>
<cfset gridName = "postGrid">
</cfsilent>
<html>
<head><cfoutput>
	<link type="text/css" rel="stylesheet" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/jsGrid/jsgrid.min.css" />
	<!---<link type="text/css" rel="stylesheet" href="/test/kendoThemeCss.css" />--->
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
	<script type="text/javascript" src="#application.baseUrl#/common/libs/jsGrid/jsgrid.min.js"></script>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput><!-- Fontawesome css -->
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
	
	<p>All columns are sortable and most are searchable. To search, enter the search term on top of the column and click the search link at the right of the page. <cfif not session.isMobile>To release a post, click on the released checkbox and click on the update checkmark on the right of the page.</cfif> There are extensive post details available by clicking on the post links.</p>
	
	<style>
		body {
			font: 15px Arial, sans-serif;
		}
	
		/* FontAwesome HEX codes:
		Edit f044 or f6d9
		Round edit F05D
		Check f00c
		Delete f1f8
		Search f002
		Eraser f12d
		Cancel f05e
		Add  f067 
		Filter f0b0
		Notes: make sure to remove the .jsgrid .jsgrid-button { background-image: url in the css file in the jsgrid .jsgrid-button declarations (there are two locations in the .css file), otherwise, a big red x will be overlaid on the controls.
		*/

		.jsgrid-button {
			position: relative;
			display: inline-block;
			font-family: "FontAwesome" !important;
			font-size: 16px;
			line-height: 16px;
			font-style: normal;
			font-weight: 400;
			cursor: pointer;
			background: 0 0;
			border: none;
			width: 14px;
			height: 14px;
			padding: 0;
			opacity: .5
		}
		.jsgrid .jsgrid-button + .jsgrid-button {
			margin-left: 5px
		}
		.jsgrid .jsgrid-insert-mode-button {
			color: #FFF;
			opacity: 1
		}
		.jsgrid-edit-button:before {
			content: '\f044' !important;/* Fontawesome edit button */
		}
		.jsgrid .jsgrid-update-button:before {
			content: '\f00c' !important;/* Fontawesome check button */
		}
		.jsgrid .jsgrid-cancel-edit-button:before {
			content: '\f05e' !important;/* Fontawesome cancel button */
		}
		.jsgrid .jsgrid-search-button:before {
			content: '\f002' !important;/* Fontawesome search button */
		}
		.jsgrid .jsgrid-clear-filter-button:before {
			content: '\f0b0' !important;/* Fontawesome filter button */
		}
		.jsgrid .jsgrid-delete-button:before {
			content: '\f1f8' !important;/* Fontawesome delete button */
		}
	</style>
</head>

<body>
	
<form id="postGridForm" action="#" method="post" data-role="validator">
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<!---The first content class in the table should be empty. --->
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td align="left" width="75%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="newSubscriber" name="newCategory" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(24,'newPost');">Create New Post</button>
		</td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!--- After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Container for the grid --->
			<div id="<cfoutput>#gridName#</cfoutput>"></div>
		</td>
	  </tr>
	</table>

	<script>
	// Get the page width. This is necessary to use percentage based widths in the columns.
	var pageWidth = $("#<cfoutput>#gridName#</cfoutput>").parent().width() - 100;

	// Rebind our custom buttons.
	window.FontAwesomeConfig = {
		autoReplaceSvg: 'nest' 
	}

	// Set up the grid.
	$(function() {
			
		jsGrid.setDefaults({
			tableClass: "jsgrid-table table table-striped table-hover"
		});

		jsGrid.setDefaults("control", {
			_createGridButton: function (cls, tooltip, clickHandler) {
				var grid = this._grid;
				return $("<button>").addClass(this.buttonClass).addClass(cls).attr({
					type: "button",
					title: tooltip
				}).on("click", function (e) {
					clickHandler(grid, e)
				})
			}
		});

		jsGrid.setDefaults("select", {
			_createSelect: function () {
				var $result = $("<select>").attr("class", "form-control"),
					valueField = this.valueField,
					textField = this.textField,
					selectedIndex = this.selectedIndex;
				$.each(this.items, function (index, item) {
					var value = valueField ? item[valueField] : index,
					text = textField ? item[textField] : item;
					var $option = $("<option>").attr("value", value).text(text).appendTo($result);
					$option.prop("selected", (selectedIndex === index));
				});
				return $result;
			}
		});
		  
		// Grid declaration
		$("#<cfoutput>#gridName#</cfoutput>").jsGrid({
			height: "720px",
			width: "100%",
			filtering: true,
			editing: true,
			sorting: true,
			paging: true,
			autoload: true,
			pageLoading: false,
			pageSize: 15,
			pageButtonCount: 5,
			deleteConfirm: "Do you really want to delete this post?",
			controller: {
				loadData: function (filter) {
					console.log(filter);
					return $.ajax({
						type: "GET",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/proxyController.cfc?method=getPostsForGrid&gridType=jsGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						data: filter,
						dataType: "json"
					// Note: you can't simply use the xhr done, complete or success methods here. If you do, the 'please wait' dialog will stay up indefinately as jsGrid does not think that the ajax is done. Instead, we must use a promise, ie the 'then' statement like we are doing here.
					}).then(function(result) {
						return result.data;
					// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
					}).fail(function (jqXHR, textStatus, error) {
						// This is a secured function. Display the login screen if there is a 403 response header.
						if (jqXHR.status === 403) { 
							createLoginWindow(); 
						} else {//...if (jqXHR.status === 403) { 
							// The full response is: jqXHR.responseText, but we just want to extract the error.
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the getPosts function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
								).done(function () {
								// Do nothing
							});
						}//...if (jqXHR.status === 403) { 
					});
				},
				updateItem: function(value, item) {
					//alert(mydump(value));//"Approved" => "true"
					return $.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/proxyController.cfc?method=updatePostViaJsGrid",
						// Pass the needed data. The only thing editable in this grid is the released checkbox
						data: {
							// Note: the PostId is not in the grid, but it is within the data that is passed to the grid. Anything coming from the json string that is used to load data is available.
							csrfToken: $("#csrfToken").val(),
							postId: value.PostId,
							// Get the value of the checkbox.
							released: value.Released
						},
						dataType: "json",
						cache: false,
					// Note: you can't simply use the xhr done, complete or success methods here. If you do, the 'please wait' dialog will stay up indefinately as jsGrid does not think that the ajax is done. Instead, we must use a promise, ie the 'then' statement like we are doing here.
					}).then(function(response) {
						// The response contains the postId and the boolean promptToEmailSubscriber. The promptToEmailSubscriber value will be true if the post is eligible to be emailed. If true- raise a dialog asking the user if they want to email the post to the subscribers. If the user chooses yes, send another ajax request along with the postId to have the post emailed.
						if (response.promptToEmailSubscriber){
							$.when(kendo.ui.ExtYesNoDialog.show({ 
								title: "Email Post?",
								message: "Do you want to email this post to the subscribers?",
								icon: "k-ext-question",
								width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
								height: "215px"
							})
							).done(function (response) { // If the user clicked 'yes', send email.
								if (response['button'] == 'Yes'){// remember that js is case sensitive.
									// Mail it
									sendEmailToSubscribers(value.PostId);
								}//..if (response['button'] == 'Yes'){
							});	
						}
					// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
					}).fail(function (jqXHR, textStatus, error) {
	
						// This is a secured function. Display the login screen if there is a 403 response header.
						if (jqXHR.status === 403) { 
							createLoginWindow(); 
						} else {//...if (jqXHR.status === 403) { 
							// The full response is: jqXHR.responseText, but we just want to extract the error.
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the updatePostViaJsGrid function", message: jqXHR.responseText, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
								).done(function () {
								// Do nothing
							});
						}//...if (jqXHR.status === 403) {
					
					});//...return $.ajax({
				},
				deleteItem: function(value, item) {
					return $.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/proxyController.cfc?method=removePostViaJsGrid",
						// Pass the needed data. 
						data: {
							// Pass the Post to the cfc on the back end. 
							// Note: the postId is not in the grid, but it is within the data that is passed to the grid. Anything coming from the json string that is used to load data is available.
							csrfToken: $("#csrfToken").val(),
							postId: value.PostId
						},
						dataType: "json",
						cache: false,
					// Note: you can't simply use the xhr done, complete or success methods here. If you do, the 'please wait' dialog will stay up indefinately as jsGrid does not think that the ajax is done. Instead, we must use a promise, ie the 'then' statement like we are doing here.
					}).then(function(result) {
						// Write the response to the console
						console.log("done", result);
					// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
					}).fail(function (jqXHR, textStatus, error) {
						// This is a secured function.  Display the login screen if there is a 403 response header.
						if (jqXHR.status === 403) { 
							createLoginWindow(); 
						} else {//...if (jqXHR.status === 403) { 
							// The full response is: jqXHR.responseText, but we just want to extract the error.
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the removePostViaGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
								).done(function () {
								// Do nothing
							});
						}//...if (jqXHR.status === 403) { 
					});
				},
				onItemEditing: function(args) {
					if(args.item.additionalfield == false) {
						args.cancel = true;
					}
				},
			},
			// Fields 
			fields: [
				{ 
					name: "FullName", 
					type: "text",
					title: "Author",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>20<cfelse>10</cfif>/100)),
				},
				
				{ name: "Title", 
					type: "text",
					title: "Title",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>40<cfelse>20</cfif>/100)),
					itemTemplate: function(value, item) {
					  return '<a href="javascript:createAdminInterfaceWindow(6, ' + item.PostId + ');">' + value + '</a>';
					}
				},
				<cfif not session.isMobile>
				{ 
					name: "Body", 
					type: "textarea",
					title: "Post",
					editing: false,
					width: (pageWidth*(30/100)),
					itemTemplate: function(value, item) {
						// This does not work to strip out the HTML ($(value).text())
					  	return '<a href="javascript:createAdminInterfaceWindow(6, ' + item.PostId + ');">' + truncateWithEllipses(removeStrBetween(value, "postData"), 125) + '</a>';
					}
				},
				{ 	
					name: "BlogSortDate", 
					type: "date",
					title: "Sort Date",
					editing: true,
					width: (pageWidth*(10/100)),
					sorttype: 'date', 
					itemTemplate: function (value, item) {
						// Format the date using the momentJs lib.
						return dayjs(item.BlogSortDate).format('MM/DD/YYYY h:mm A');
					},
				},
				{ 	
					name: "DatePosted", 
					type: "date",
					title: "Posted",
					editing: false,
					width: (pageWidth*(10/100)),
					sorttype: 'date', 
					itemTemplate: function (value, item) {
						// Format the date using the momentJs lib.
						return dayjs(item.DatePosted).format('MM/DD/YYYY h:mm A');
					},
				},
				{ 
					name: "Released", 
					type: "checkbox",
					// We don't have the room on mobile to put in the approved string. Use a thumbs up icon instead.
					title: '<cfif session.isMobile><i class="fas fa-thumbs-up"></i><cfelse>Released</cfif>',
					width: (pageWidth*(10/100)),
					<!--- editTemplate: function(value, item) {
						return "<input type='checkbox'>" + item.Released;
					} --->
				},
				</cfif>
				{ 
					type: "control",
					width: (pageWidth*(<cfif session.isMobile>15<cfelse>10</cfif>/100)),
				}

				]
			});
		});

		// Helper functions
		function makePostLink(datePosted, postAlias){
			var dt = new Date(datePosted);
			var yyyy = dt.getFullYear();
			var m = dt.getMonth()+1;
			var d = dt.getDay()+1;
			return yyyy + "/" + m + "/" + d + "/" + postAlias;
		}
		
		// Send email to subscribers
		function sendEmailToSubscribers(postId){ 

				jQuery.ajax({
					type: 'post', 
					url: '../../common/cfc/proxyController.cfc?method=sendPostEmailToSubscribers',
					dataType: "json",
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						postId: postId
					},
					success: emailResult, // calls the result function.
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
				}).fail(function (jqXHR, textStatus, error) {

					// The full response is: jqXHR.responseText, but we just want to extract the error.
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the sendPostEmailToSubscribers function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						// Do nothing
					});		
				});	
			}

			// Submit the data and close this window.
			function emailResult(response){
				// Do nothing
			}
		
   	</script>
				
</form>
	
<script>
	// Script to add custom font awesome buttons. This does not need to be editted unless you want to change the css class names (ie jsgrid-button etc).
	(function(jsGrid, $, undefined) {

		var Field = jsGrid.Field;

		function ControlField(config) {
			Field.call(this, config);
			this.includeInDataExport = false;
			this._configInitialized = false;
		}

		ControlField.prototype = new Field({
			css: "jsgrid-control-field",
			align: "center",
			width: 50,
			filtering: false,
			inserting: false,
			editing: false,
			sorting: false,

			buttonClass: "jsgrid-button",
			modeButtonClass: "jsgrid-mode-button",

			modeOnButtonClass: "jsgrid-mode-on-button",
			searchModeButtonClass: "jsgrid-search-mode-button",
			insertModeButtonClass: "jsgrid-insert-mode-button",
			editButtonClass: "jsgrid-edit-button",
			deleteButtonClass: "jsgrid-delete-button",
			searchButtonClass: "jsgrid-search-button",
			clearFilterButtonClass: "jsgrid-clear-filter-button",
			insertButtonClass: "jsgrid-insert-button",
			updateButtonClass: "jsgrid-update-button",
			cancelEditButtonClass: "jsgrid-cancel-edit-button",

			searchModeButtonTooltip: "Switch to searching",
			insertModeButtonTooltip: "Switch to inserting",
			editButtonTooltip: "Edit",
			deleteButtonTooltip: "Delete",
			searchButtonTooltip: "Search",
			clearFilterButtonTooltip: "Clear filter",
			insertButtonTooltip: "Insert",
			updateButtonTooltip: "Update",
			cancelEditButtonTooltip: "Cancel edit",

			editButton: true,
			deleteButton: true,
			clearFilterButton: true,
			modeSwitchButton: true,

			_initConfig: function() {
				this._hasFiltering = this._grid.filtering;
				this._hasInserting = this._grid.inserting;

				if(this._hasInserting && this.modeSwitchButton) {
					this._grid.inserting = false;
				}

				this._configInitialized = true;
			},

			headerTemplate: function() {
				if(!this._configInitialized) {
					this._initConfig();
				}

				var hasFiltering = this._hasFiltering;
				var hasInserting = this._hasInserting;

				if(!this.modeSwitchButton || (!hasFiltering && !hasInserting))
					return "";

				if(hasFiltering && !hasInserting)
					return this._createFilterSwitchButton();

				if(hasInserting && !hasFiltering)
					return this._createInsertSwitchButton();

				return this._createModeSwitchButton();
			},

			itemTemplate: function(value, item) {
				var $result = $([]);

				if(this.editButton) {
					$result = $result.add(this._createEditButton(item));
				}

				if(this.deleteButton) {
					$result = $result.add(this._createDeleteButton(item));
				}

				return $result;
			},

			filterTemplate: function() {
				var $result = this._createSearchButton();
				return this.clearFilterButton ? $result.add(this._createClearFilterButton()) : $result;
			},

			insertTemplate: function() {
				return this._createInsertButton();
			},

			editTemplate: function() {
				return this._createUpdateButton().add(this._createCancelEditButton());
			},

			_createFilterSwitchButton: function() {
				return this._createOnOffSwitchButton("filtering", this.searchModeButtonClass, true);
			},

			_createInsertSwitchButton: function() {
				return this._createOnOffSwitchButton("inserting", this.insertModeButtonClass, false);
			},

			_createOnOffSwitchButton: function(option, cssClass, isOnInitially) {
				var isOn = isOnInitially;

				var updateButtonState = $.proxy(function() {
					$button.toggleClass(this.modeOnButtonClass, isOn);
				}, this);

				var $button = this._createGridButton(this.modeButtonClass + " " + cssClass, "", function(grid) {
					isOn = !isOn;
					grid.option(option, isOn);
					updateButtonState();
				});

				updateButtonState();

				return $button;
			},

			_createModeSwitchButton: function() {
				var isInserting = false;

				var updateButtonState = $.proxy(function() {
					$button.attr("title", isInserting ? this.searchModeButtonTooltip : this.insertModeButtonTooltip)
						.toggleClass(this.insertModeButtonClass, !isInserting)
						.toggleClass(this.searchModeButtonClass, isInserting);
				}, this);

				var $button = this._createGridButton(this.modeButtonClass, "", function(grid) {
					isInserting = !isInserting;
					grid.option("inserting", isInserting);
					grid.option("filtering", !isInserting);
					updateButtonState();
				});

				updateButtonState();

				return $button;
			},

			_createEditButton: function(item) {
				return this._createGridButton(this.editButtonClass, this.editButtonTooltip, function(grid, e) {
					grid.editItem(item);
					e.stopPropagation();
				});
			},

			_createDeleteButton: function(item) {
				return this._createGridButton(this.deleteButtonClass, this.deleteButtonTooltip, function(grid, e) {
					grid.deleteItem(item);
					e.stopPropagation();
				});
			},

			_createSearchButton: function() {
				return this._createGridButton(this.searchButtonClass, this.searchButtonTooltip, function(grid) {
					grid.search();
				});
			},

			_createClearFilterButton: function() {
				return this._createGridButton(this.clearFilterButtonClass, this.clearFilterButtonTooltip, function(grid) {
					grid.clearFilter();
				});
			},

			_createInsertButton: function() {
				return this._createGridButton(this.insertButtonClass, this.insertButtonTooltip, function(grid) {
					grid.insertItem().done(function() {
						grid.clearInsert();
					});
				});
			},

			_createUpdateButton: function() {
				return this._createGridButton(this.updateButtonClass, this.updateButtonTooltip, function(grid, e) {
					grid.updateItem();
					e.stopPropagation();
				});
			},

			_createCancelEditButton: function() {
				return this._createGridButton(this.cancelEditButtonClass, this.cancelEditButtonTooltip, function(grid, e) {
					grid.cancelEdit();
					e.stopPropagation();
				});
			},

			_createGridButton: function(cls, tooltip, clickHandler) {
				var grid = this._grid;

				return $("<input>").addClass(this.buttonClass)
					.addClass(cls)
					.attr({
						type: "button",
						title: tooltip
					})
					.on("click", function(e) {
						clickHandler(grid, e);
					});
			},

			editValue: function() {
				return "";
			}

		});

		jsGrid.fields.control = jsGrid.ControlField = ControlField;

	}(jsGrid, jQuery));
</script>

</body>

</html>
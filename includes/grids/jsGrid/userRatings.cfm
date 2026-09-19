<!doctype html>
<cfsilent>
<cfset gridName = "ratingGrid">
<cfset showEditButton = false>
	
<!---
You can view this in a couple of ways. Typically, the grid displays all records, you can limit it to the ipAddressId by passing in the optional ipAddressId.
The arguments are: createAdminInterfaceWindow(62[,ipAddressId]) (createAdminInterfaceWindow(Id, optArgs, otherArgs, otherArgs1)
--->
<cfparam name="pageTitle" default="" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getReactionsForGrid&gridType=jsGrid'>
<!--- Append the IpAddressId --->
<cfif structKeyExists(URL, "optArgs")  and isNumeric(URL.optArgs) and URL.optArgs gt 0>
	<cfset getUrl = getUrl & '&ipAddressId=' & URL.optArgs>
	<cfset pageTitle = "Reactions By IP">
</cfif>
<!--- Finally, attach the csrfToken --->
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
	
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
	
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and most are searchable. To search, enter the search term on top of the column and click the search link at the right of the page. You can also remove votes by clicking the edit icon, selecting the vote that you wish to remove, and click on the update checkmark on the right of the page.</p>
	
	<style>
		body {
			font: 15px Arial, sans-serif;
		}
	
		<!--- FontAwesome HEX codes: Edit f044 or f6d9 Round edit F05D Check f00c Delete f1f8 Search f002 Eraser f12d Cancel f05e Add f067 Filter f0b0 Notes: make sure to remove the .jsgrid .jsgrid-button { background-image: url in the css file in the jsgrid .jsgrid-button declarations (there are two locations in the .css file), otherwise, a big red x will be overlaid on the controls. --->

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
	
<!--- Container for the grid --->
<div id="<cfoutput>#gridName#</cfoutput>"></div>

	<script>
	<!--- Get the page width. This is necessary to use percentage based widths in the columns. --->
	var pageWidth = $("#<cfoutput>#gridName#</cfoutput>").parent().width() - 100;

	<!--- Rebind our custom buttons. --->
	window.FontAwesomeConfig = {
		autoReplaceSvg: 'nest' 
	}

	<!--- Set up the grid. --->
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
		  
		<!--- Grid declaration --->
		$("#<cfoutput>#gridName#</cfoutput>").jsGrid({
			height: "720px",
			width: "100%",
			filtering: true,
			editing: false,
			sorting: true,
			paging: true,
			autoload: true,
			pageSize: 15,
			pageButtonCount: 5,
			deleteConfirm: "Do you really want to delete this vote?",
			controller: {
				loadData: function (filter) {
					console.log(filter);
					return $.ajax({
						type: "GET",
						url: "<cfoutput>#getUrl#</cfoutput>",
						data: filter,
						dataType: "json"
					<!--- Note: you can't simply use the xhr done, complete or success methods here. If you do, the 'please wait' dialog will stay up indefinately as jsGrid does not think that the ajax is done. Instead, we must use a promise, ie the 'then' statement like we are doing here. --->
					}).then(function(result) {
						return result.data;
					<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
					}).fail(function (jqXHR, textStatus, error) {
						<!--- This is a secured function. Display the login screen if there is a 403 response header. --->
						if (jqXHR.status === 403) { 
							createLoginWindow(); 
						} else {//...if (jqXHR.status === 403) { 
							<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the getReactionsForGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
								).done(function () {
								<!--- Do nothing --->
							});
						}//...if (jqXHR.status === 403) { 
					});
				},
				deleteItem: function(value, item) {
					return $.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteReactionViaJsGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						<!--- Pass the needed data. Here we need to see if the comment was approved, and pass the postId to update the database on the back end. --->
						data: {
							<!--- Pass the ratingId to the cfc on the back end. Note: the ratingId is not in the grid, but it is within the data that is passed to the grid. Anything coming from the json string that is used to load data is available. --->
							postRatingId: value.PostRatingId
						},
						dataType: "json",
						cache: false,
					<!--- Note: you can't simply use the xhr done, complete or success methods here. If you do, the 'please wait' dialog will stay up indefinately as jsGrid does not think that the ajax is done. Instead, we must use a promise, ie the 'then' statement like we are doing here. --->
					}).then(function(result) {
						console.log("done", result);
					<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
					}).fail(function (jqXHR, textStatus, error) {
						<!--- This is a secured function. Display the login screen if there is a 403 response header. --->
						if (jqXHR.status === 403) { 
							createLoginWindow(); 
						} else {//...if (jqXHR.status === 403) { 
							<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the deleteReactionViaJsGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
								).done(function () {
								<!--- Do nothing --->
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
			<!--- Fields --->
			fields: [
				{ 
					name: "AnonymousUserId", 
					type: "text",
					title: "UserId",
					editing: false,
					width: (pageWidth*(10/100)),
					itemTemplate: function(value, item) {
						<!--- Link to the visitor details --->
						return '<a href="javascript:createAdminInterfaceWindow(63, ' + item.AnonymousUserId + ');">' + value + '</a>';
					}
				},
				{ 	
					name: "IpAddress", 
					type: "text",
					title: "Ip Address",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>25<cfelse>10</cfif>/100)),
					itemTemplate: function(value, item) {
					  return '<a href="https://www.ipalyzer.com/' + item.IpAddress + '" target="_new">' + value + '</a>';
					}
				},
				<cfif not session.isMobile>
				{ 	
					name: "HttpUserAgent", 
					type: "text",
					title: "User Agent",
					editing: false,
					width: (pageWidth*(35/100)),
					itemTemplate: function(value, item) {
					  return '<a href="https://gs.statcounter.com/detect?useragent=' + item.HttpUserAgent + '" target="_new">' + value + '</a>';
					}
				},
				</cfif>
				{ name: "Title", 
					type: "text",
					title: "Post",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>30<cfelse>25</cfif>/100)),
					itemTemplate: function(value, item) {
					  return '<a href="javascript:createAdminInterfaceWindow(6, ' + item.PostId + ');">' + value + '</a>';
					}
				},
				{ 
					name: "Helpful", 
					type: "checkbox",
					title: "Like",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>10<cfelse>5</cfif>/100))
				},
				{ 
					name: "UnHelpful", 
					type: "checkbox",
					title: "Dislike",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>10<cfelse>5</cfif>/100))
				},
				{ 	
					name: "Date", 
					type: "date",
					title: "Date",
					editing: true,
					width: (pageWidth*(10/100)),
					sorttype: 'date', 
					itemTemplate: function (value, item) {
						<!--- Format the date using the momentJs lib. --->
						return dayjs(item.Date).format('MM/DD/YYYY h:mm A');
					},
				},
				{ 
					type: "control",
					width: (pageWidth*(<cfif session.isMobile>10<cfelse>5</cfif>/100)),
				}

				]
			});
		});
		
   	</script>
	
	<script>
		<!--- Script to add custom font awesome buttons. This does not need to be editted unless you want to change the css class names (ie jsgrid-button etc). --->
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

				editButton: <cfoutput>#showEditButton#</cfoutput>,
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
			
			<!--- Define a custom radio button field --->
			jsGrid.fields.radio = (function(base) {
				function RadioField(config) {
					base.call(this, config);
				}

				RadioField.prototype = new base({
					sorter: function(value1, value2) {
						return value1 ? 1 : -1;
					},

					itemTemplate: function(value, item) {
						<!--- Create a radio input element --->
						var $radio = $("<input>").attr("type", "radio")
							.attr("name", "selectRow") // Same name groups them together
							.prop("checked", value);

						<!--- Handle selection change --->
						$radio.on("click", function() {
							<!--- Clear checked state for other items in grid if needed --->
							var items = $("#jsGrid").jsGrid("option", "data");
							$.each(items, function(index, destItem) {
								destItem.Selected = false;
							});
							item.Selected = true;
						});

						return $radio;
					},

					insertTemplate: function(value) {
						return this._insertPicker = $("<input>").attr("type", "radio").attr("name", "selectRow");
					},

					editTemplate: function(value) {
						return this._editPicker = $("<input>").attr("type", "radio").attr("name", "selectRow").prop("checked", value);
					},

					insertValue: function() {
						return this._insertPicker.is(":checked");
					},

					editValue: function() {
						return this._editPicker.is(":checked");
					}
				});

				return RadioField;
			}(jsGrid.Field));

			jsGrid.fields.control = jsGrid.ControlField = ControlField;

		}(jsGrid, jQuery));
	</script>

</body>

</html>
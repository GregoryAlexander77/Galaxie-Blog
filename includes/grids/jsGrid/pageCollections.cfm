<!doctype html>
<cfsilent>
<!--- jsGrid version of ../kendo/pageCollections.cfm. Same pattern as ../jsGrid/posts.cfm: read-only except for
	Delete - editing Title/Description/Hero Image/Theme/member order all happens together in the Page Collection
	Detail window (createAdminInterfaceWindow(72, pageCollectionId)), so showEditButton is false here (unlike
	posts.cfm, which has BlogSortDate/DatePosted as genuinely inline-editable fields). Delete reuses the same
	deletePageCollection endpoint the old combined list+expand interface used (configurePageCollections.cfm, now
	superseded by this grid + pageCollectionDetail.cfm). --->
<cfset gridName = "pageCollectionGrid">
<cfset showEditButton = false>
</cfsilent>
<html>
<head><cfoutput>
	<link type="text/css" rel="stylesheet" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/jsGrid/jsgrid.min.css" />
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
	<script type="text/javascript" src="#application.baseUrl#/common/libs/jsGrid/jsgrid.min.js"></script>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput><!-- Fontawesome css -->
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">

	<p>To search, enter the search term on top of the column and click the search link at the right of the page. <cfif not session.isMobile>All columns are sortable and most are searchable.</cfif> Click a collection's title to edit its hero image, theme, and member order.</p>

	<style>
		body {
			font: 15px Arial, sans-serif;
		}

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
			content: '\f044' !important;
		}
		.jsgrid .jsgrid-update-button:before {
			content: '\f00c' !important;
		}
		.jsgrid .jsgrid-cancel-edit-button:before {
			content: '\f05e' !important;
		}
		.jsgrid .jsgrid-search-button:before {
			content: '\f002' !important;
		}
		.jsgrid .jsgrid-clear-filter-button:before {
			content: '\f0b0' !important;
		}
		.jsgrid .jsgrid-delete-button:before {
			content: '\f1f8' !important;
		}
	</style>
</head>

<body>

<form id="pageCollectionGridForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
	  <cfsilent>
			<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td align="left" width="75%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="newPageCollectionBtn" name="newPageCollectionBtn" class="k-button k-primary" type="button" onClick="createAdminInterfaceWindow(24,'newPageCollection');">Create New Page Collection</button>
		</td>
	  </tr>
	  <cfsilent>
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <tr valign="middle" height="30px">
		<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<div id="<cfoutput>#gridName#</cfoutput>"></div>
		</td>
	  </tr>
	</table>

	<script>
	var pageWidth = $("#<cfoutput>#gridName#</cfoutput>").parent().width() - 100;

	window.FontAwesomeConfig = {
		autoReplaceSvg: 'nest'
	}

	$(function() {

		<!--- One-time dissolve notice, shown when the admin next opens this grid (see doc/pageCollectionsDesign - "pops up only once", batched if more than one is pending). Moved here from the old configurePageCollections.cfm since this grid is now the first stop for Page Collections. --->
		jQuery.ajax({
			type: 'post',
			url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAndDismissPendingDissolveNotices',
			data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>' },
			dataType: "json",
			success: function(response) {
				if (JSON.parse(response.hasNotice) == true) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "A page collection was removed", message: response.message, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			}
		});

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

		<!--- Grid declaration --->
		$("#<cfoutput>#gridName#</cfoutput>").jsGrid({
			height: "720px",
			width: "100%",
			filtering: true,
			editing: false,
			sorting: true,
			paging: true,
			autoload: true,
			pageLoading: false,
			pageSize: 15,
			pageButtonCount: 5,
			deleteConfirm: "Do you really want to delete this page collection? Its member pages are not affected.",
			controller: {
				loadData: function (filter) {
					return $.ajax({
						type: "GET",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPageCollectionsForGrid&gridType=jsGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						data: filter,
						dataType: "json"
					}).then(function(result) {
						if (!result){
							createLoginWindow();
						} else {
							return result.data;
						}
					}).fail(function (jqXHR, textStatus, error) {
						if (jqXHR.status === 403) {
							createLoginWindow();
						} else {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the getPageCollectionsForGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
								).done(function () {});
						}
					});
				},
				deleteItem: function(value, item) {
					return $.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePageCollection",
						data: {
							csrfToken: $("#csrfToken").val(),
							pageCollectionId: value.PageCollectionId
						},
						dataType: "json",
						cache: false,
					}).then(function(response) {
						if (!response.success) {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning" }));
						}
					}).fail(function (jqXHR, textStatus, error) {
						if (jqXHR.status === 403) {
							createLoginWindow();
						} else {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the deletePageCollection function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
								).done(function () {});
						}
					});
				}
			},
			<!--- Fields --->
			fields: [
				{
					name: "Title",
					type: "text",
					title: "Title",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>60<cfelse>30</cfif>/100)),
					itemTemplate: function(value, item) {
						return '<a href="javascript:createAdminInterfaceWindow(72, ' + item.PageCollectionId + ');">' + value + '</a>';
					}
				},
				<cfif not session.isMobile>
				{
					name: "Description",
					type: "text",
					title: "Description",
					editing: false,
					width: (pageWidth*(25/100))
				},
				</cfif>
				{
					name: "MemberCount",
					type: "number",
					title: "Pages",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>15<cfelse>8</cfif>/100)),
					sorttype: 'number'
				},
				{
					name: "Status",
					type: "text",
					title: "Status",
					editing: false,
					width: (pageWidth*(<cfif session.isMobile>25<cfelse>12</cfif>/100)),
					itemTemplate: function(value, item) {
						if (value === "Live") {
							return value;
						}
						return '<a href="javascript:createAdminInterfaceWindow(71, ' + item.PageCollectionId + ');" title="Add pages to this collection">' + value + '</a>';
					}
				},
				<cfif not session.isMobile>
				{
					name: "Created",
					type: "date",
					title: "Created",
					editing: false,
					width: (pageWidth*(10/100)),
					sorttype: 'date',
					itemTemplate: function (value, item) {
						return value ? dayjs(value).format('MM/DD/YYYY h:mm A') : '';
					}
				},
				</cfif>
				{
					type: "control",
					width: (pageWidth*(<cfif session.isMobile>15<cfelse>10</cfif>/100))
				}
			]
		});
	});
   	</script>

</form>

<script>
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

		jsGrid.fields.control = jsGrid.ControlField = ControlField;

	}(jsGrid, jQuery));
</script>

</body>

</html>

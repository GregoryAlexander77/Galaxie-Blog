<!doctype html>
<cfsilent>
<!--- jsGrid version of ../kendo/bookingTypes.cfm - the Booking types grid (window 90, 2026-10-14), used when Kendo Professional is not loaded. Copied from the Forms grid, whose button control customization below is reused as is. Delete uses deleteBookingType. --->
<cfset gridName = "bookingTypesJsGrid">
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
<form id="bookingTypesGridForm" action="#" method="post" data-role="validator">
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<div id="<cfoutput>#gridName#</cfoutput>"></div>
	<script>
	var pageWidth = $("#<cfoutput>#gridName#</cfoutput>").parent().width() - 100;

	window.FontAwesomeConfig = {
		autoReplaceSvg: 'nest'
	}

	<!--- jsGrid shows values as text; this keeps a value from being read as HTML. --->
	function encodeGridText(value) {
		return $('<div/>').text(value === null || value === undefined ? '' : String(value)).html();
	}

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
		$("#<cfoutput>#gridName#</cfoutput>").jsGrid({
			height: "560px",
			width: "100%",
			filtering: true,
			editing: false,
			sorting: true,
			paging: true,
			autoload: true,
			pageLoading: false,
			pageSize: 15,
			pageButtonCount: 5,
			deleteConfirm: "Delete this booking type? To stop offering it but keep it for later, edit it and untick Active instead.",
			controller: {
				loadData: function (filter) {
					return $.ajax({
						type: "GET",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getBookingTypesForGrid&gridType=jsGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						data: filter,
						dataType: "json"
					}).then(function(result) {
						if (!result){
							createLoginWindow();
						} else {
							<!--- Filter here: the server returns every booking type. --->
							return $.grep(result.data, function(item) {
								return (!filter.Name || item.Name.toLowerCase().indexOf(filter.Name.toLowerCase()) > -1)
									&& (!filter.Category || (item.Category || "").toLowerCase().indexOf(filter.Category.toLowerCase()) > -1)
									&& (!filter.Locations || (item.Locations || "").toLowerCase().indexOf(filter.Locations.toLowerCase()) > -1)
									&& (!filter.Status || item.Status.toLowerCase().indexOf(filter.Status.toLowerCase()) > -1);
							});
						}
					}).fail(function (jqXHR, textStatus, error) {
						if (jqXHR.status === 403) {
							createLoginWindow();
						} else {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the getBookingTypesForGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
						}
					});
				},
				deleteItem: function(value) {
					return $.ajax({
						type: "post",
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteBookingType",
						data: { csrfToken: $("#csrfToken").val(), bookingTypeId: value.BookingTypeId },
						dataType: "json",
						cache: false
					}).then(function(response) {
						if (!response.success) {
							$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning" }));
						}
					}).fail(function (jqXHR, textStatus, error) {
						if (jqXHR.status === 403) { createLoginWindow(); }
					});
				}
			},
			fields: [
				{
					name: "Name",
					type: "text",
					title: "Name",
					width: (pageWidth*(<cfif session.isMobile>45<cfelse>22</cfif>/100)),
					itemTemplate: function(value, item) {
						return '<a href="javascript:createAdminInterfaceWindow(91, ' + item.BookingTypeId + ');">' + encodeGridText(value) + '</a>';
					}
				},
				{ name: "Category", type: "text", title: "Category", width: (pageWidth*(<cfif session.isMobile>30<cfelse>12</cfif>/100)), itemTemplate: function(value) { return encodeGridText(value); } },
				<cfif not session.isMobile>
				{ name: "Length", type: "text", title: "Length", width: (pageWidth*(12/100)), filtering: false, itemTemplate: function(value) { return encodeGridText(value); } },
				{ name: "Price", type: "text", title: "Price", width: (pageWidth*(8/100)), filtering: false, itemTemplate: function(value) { return encodeGridText(value); } },
				{ name: "Locations", type: "text", title: "Where", width: (pageWidth*(24/100)), itemTemplate: function(value) { return encodeGridText(value); } },
				{ name: "Status", type: "text", title: "Status", width: (pageWidth*(9/100)) },
				</cfif>
				{
					type: "control",
					width: (pageWidth*(<cfif session.isMobile>15<cfelse>8</cfif>/100))
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

<cfsilent>
<!--- Note: sync this with the blog.cfc's getPrimaryColorsByTheme function. --->
<cfswitch expression="#kendoTheme#">
	<cfcase value="black">
		<cfset buttonAccentColor = "db4240">
		<cfset accentColor = "0066cc">
		<cfset baseColor = "363636">
		<cfset headerBgColor = "4D4D4D">
		<cfset headerTextColor = "fff">
		<cfset hoverBgColor = "3d3d3d">
		<cfset hoverBorderColor = "4d4d4d">
		<cfset textColor = "ffffff">
		<cfset selectedTextColor = "ffffff">
		<cfset headerBorderColor = "2a2a2a">
		<cfset contentBgColor = "555">
		<cfset contentBorderColor = "000">
		<cfset alternateBgColor = "4D4D4D">
		<cfset error = "db4240">
		<cfset warning = "ffc000">
		<cfset success = "37b400">
		<cfset info = "0066cc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="blueOpal">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "326891"><!---7bd2f6--->
		<cfset baseColor = "daecf4">
		<cfset headerBgColor = "E3EFF7">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "A1D6F7"><!---13688c--->
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "a3d0e4"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "d9ecf5"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "a3d0e4"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "f5f5f5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "db4240">
		<cfset warning = "ffb400">
		<cfset success = "37b400">
		<cfset info = "0066cc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="bootstrap">
		<cfset buttonAccentColor = "428bca">
		<cfset accentColor = "428bca">
		<cfset baseColor = "ebebeb">
		<cfset headerBgColor = "8e8e8e">
		<cfset headerTextColor = "333333">
		<cfset hoverBgColor = "ebebeb">
		<cfset hoverBorderColor = "333333">
		<cfset textColor = "333333">
		<cfset selectedTextColor = "333333">
		<cfset headerBorderColor = "dfdfdf">
		<cfset contentBgColor = "ffffff">
		<cfset contentBorderColor = "dfdfdf">
		<cfset alternateBgColor = "ebebeb">
		<cfset error = "d9534f">
		<cfset warning = "f0ad4e">
		<cfset success = "5cb85c">
		<cfset info = "5bc0de">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="default">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "f35800">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "e9e9e9">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "bcb4b0">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "c5c5c5"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "d5d5d5"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "f5f5f5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "f35800">
		<cfset warning = "ffc000">
		<cfset success = "37b400">
		<cfset info = "0066cc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="flat">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "10c4b2">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "373940">
		<cfset headerTextColor = "fff">
		<cfset hoverBgColor = "2eb3a6">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "606572"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "fff"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "F5F5F5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "fe633f">
		<cfset warning = "feca3f">
		<cfset success = "2db245">
		<cfset info = "0099cc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="highContrast">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "870074">
		<cfset baseColor = "2B232B">
		<cfset headerBgColor = "4d4d4d">
		<cfset headerTextColor = "fff">
		<cfset hoverBgColor = "a7008f">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "ffffff">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "674c63"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "2c232b"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "674c63"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "1b141a"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "e33a13">
		<cfset warning = "e9a71d">
		<cfset success = "2b893c">
		<cfset info = "007da7">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="material">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "00b0ff">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "ebebeb">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "ebebeb">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "e6e6e6"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "e6e6e6"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "f5f7fa"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "f44336">
		<cfset warning = "ff9800">
		<cfset success = "4caf50">
		<cfset info = "2196f3">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="materialBlack">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "00b0ff">
		<cfset baseColor = "363636">
		<cfset headerBgColor = "5A5A5A">
		<cfset headerTextColor = "fff">
		<cfset hoverBgColor = "606060">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "fff">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "505050"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "363636"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "4d4d4d"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "393a3b"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "f44336">
		<cfset warning = "ff9800">
		<cfset success = "4caf50">
		<cfset info = "2196f3">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="metro">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "7ea700">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "F5F5F5">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "8ebc00">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "dbdbdb"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "dbdbdb"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "F5F5F5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "e20000">
		<cfset warning = "ffb137">
		<cfset success = "2b893c">
		<cfset info = "0c779b">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="moonlight">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "f4af03">
		<cfset baseColor = "424550">
		<cfset headerBgColor = "424852">
		<cfset headerTextColor = "fff">
		<cfset hoverBgColor = "62656F">
		<cfset hoverBorderColor = "3d3d3d">
		<cfset textColor = "fff">
		<cfset selectedTextColor = "000">
		<cfset headerBorderColor = "3E454F"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "424550"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "232d36"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "494C58"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "be5138">
		<cfset warning = "ea9d07">
		<cfset success = "2b893c">
		<cfset info = "0c779b">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="nova">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "7FD2E3">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "FAFAFA">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "f5f6f6">
		<cfset hoverBorderColor = "FAFAFA">
		<cfset textColor = "000">
		<cfset selectedTextColor = "000">
		<cfset headerBorderColor = "e0e0e0"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "FAFAFA"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "FAFAFA"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "ff2637">
		<cfset warning = "ffb82e">
		<cfset success = "479b4a">
		<cfset info = "1ea2b3">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="office365">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "cde6f7">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "FAFAFA">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "f4f4f4">
		<cfset hoverBorderColor = "c9c9c9">
		<cfset textColor = "000">
		<cfset selectedTextColor = "000">
		<cfset headerBorderColor = "ffff0"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "ffff0"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "FAFAFA"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "f44336">
		<cfset warning = "ffdb04">
		<cfset success = "43a047">
		<cfset info = "1976d2">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="silver">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "1984c8">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "FAFAFA">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "b6bdca">
		<cfset hoverBorderColor = "F6F6F6">
		<cfset textColor = "000">
		<cfset selectedTextColor = "fff">
		<cfset headerBorderColor = "ceced2"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "f3f3f4"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "dedee0"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "f5f5f5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "d92800">
		<cfset warning = "ff9800">
		<cfset success = "3ea44e">
		<cfset info = "2498bc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
	<cfcase value="uniform">
		<cfset buttonAccentColor = "0066cc">
		<cfset accentColor = "D4D4D4">
		<cfset baseColor = "fff">
		<cfset headerBgColor = "f5f5f5">
		<cfset headerTextColor = "000">
		<cfset hoverBgColor = "F6F6F6">
		<cfset hoverBorderColor = "F6F6F6">
		<cfset textColor = "000">
		<cfset selectedTextColor = "000">
		<cfset headerBorderColor = "F6F6F6"><!--- in css: .k-separator{border-color:#c5c5c5} --->
		<cfset contentBgColor = "fff"><!---td.k-group-cell{background-color:#eae8e8}--->
		<cfset contentBorderColor = "dedee0"><!---k-textbox{border-color:#d5d5d5--->
		<cfset alternateBgColor = "f5f5f5"><!---.k-status{background-color:#f5f5f5}--->
		<cfset error = "d92800">
		<cfset warning = "ff9800">
		<cfset success = "3ea44e">
		<cfset info = "2498bc">
		<cfset titleColor = "8e8e8e">
	</cfcase>
</cfswitch>
</cfsilent>
	
<style>

	/* Allow links to inherit the color. Otherwise the color of the links won't be shown in the selected row. */
	a {color: inherit; }
	
	/* Set the background color */
	.jsgrid-grid-header,
	.jsgrid-grid-body {
		background: "000";
	}

	/* Set the border, background and text for the entire grid. */
	.jsgrid-grid-header,
	.jsgrid-grid-body,
	.jsgrid-header-row > .jsgrid-header-cell,
	.jsgrid-filter-row > .jsgrid-cell,
	.jsgrid-insert-row > .jsgrid-cell,
	.jsgrid-edit-row > .jsgrid-cell {
		border: 1px solid #<cfoutput>#titleColor#</cfoutput>;
		background: #<cfoutput>#baseColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	.jsgrid-header-row > .jsgrid-header-cell {
		border-top: 0;
		background: #<cfoutput>#headerBgColor#</cfoutput> !important;
		color: #<cfoutput>#headerTextColor#</cfoutput> !important;
	}

	.jsgrid-header-row > .jsgrid-header-cell,
	.jsgrid-filter-row > .jsgrid-cell,
	.jsgrid-insert-row > .jsgrid-cell {
		background: #<cfoutput>#baseColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
		border-bottom: 0;
	}

	.jsgrid-header-row > .jsgrid-header-cell:first-child,
	.jsgrid-filter-row > .jsgrid-cell:first-child,
	.jsgrid-insert-row > .jsgrid-cell:first-child {
		border-left: none;
	}

	.jsgrid-header-row > .jsgrid-header-cell:last-child,
	.jsgrid-filter-row > .jsgrid-cell:last-child,
	.jsgrid-insert-row > .jsgrid-cell:last-child {
		border-right: none;
	}

	.jsgrid-header-row .jsgrid-align-right,
	.jsgrid-header-row .jsgrid-align-left {
		text-align: center;
	}

	.jsgrid-grid-header {
		background: #<cfoutput>#headerBorderColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	.jsgrid-header-scrollbar {
		scrollbar-arrow-color: #f1f1f1;
		scrollbar-base-color: #f1f1f1;
		scrollbar-3dlight-color: #f1f1f1;
		scrollbar-highlight-color: #f1f1f1;
		scrollbar-track-color: #f1f1f1;
		scrollbar-shadow-color: #f1f1f1;
		scrollbar-dark-shadow-color: #f1f1f1;
	}

	.jsgrid-header-scrollbar::-webkit-scrollbar {
		visibility: hidden;
	}

	.jsgrid-header-scrollbar::-webkit-scrollbar-track {
		background: #<cfoutput>#titleColor#</cfoutput>;
	}

	.jsgrid-header-sortable:hover {
		cursor: pointer;
		background: #<cfoutput>#hoverBgColor#</cfoutput>;
	}

	.jsgrid-header-row .jsgrid-header-sort {
		background: #<cfoutput>#hoverBgColor#</cfoutput>;
	}

	.jsgrid-header-sort:before {
		content: " ";
		display: block;
		float: left;
		width: 0;
		height: 0;
		border-style: solid;
	}

	.jsgrid-header-sort-asc:before {
		border-width: 0 5px 5px 5px;
		border-color: transparent transparent #<cfoutput>#headerTextColor#</cfoutput> transparent;
	}

	.jsgrid-header-sort-desc:before {
		border-width: 5px 5px 0 5px;
		border-color: #<cfoutput>#headerTextColor#</cfoutput> transparent transparent transparent;
	}

	.jsgrid-grid-body {
		border-top: none;
		background: #<cfoutput>#baseColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
		
	}

	.jsgrid-cell {
		border: #<cfoutput>#contentBorderColor#</cfoutput> 1px solid;
	}

	.jsgrid-grid-body .jsgrid-row:first-child .jsgrid-cell,
	.jsgrid-grid-body .jsgrid-alt-row:first-child .jsgrid-cell {
		border-top: none;
	}

	.jsgrid-grid-body .jsgrid-cell:first-child {
		border-left: none;
	}

	.jsgrid-grid-body .jsgrid-cell:last-child {
		border-right: none;
	}

	.jsgrid-row > .jsgrid-cell {
		background: #<cfoutput>#contentBgColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	.jsgrid-alt-row > .jsgrid-cell {
		background: #<cfoutput>#alternateBgColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	.jsgrid-header-row > .jsgrid-header-cell {
		background: #<cfoutput>#contentBgColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	.jsgrid-filter-row > .jsgrid-cell {
		background: #<cfoutput>#baseColor#</cfoutput>;
		color: #<cfoutput>#headerTextColor#</cfoutput>;
		border-bottom: 0;
	}

	.jsgrid-insert-row > .jsgrid-cell {
		background: #e3ffe5;
	}

	.jsgrid-edit-row > .jsgrid-cell {
		background: #<cfoutput>#accentColor#</cfoutput>;
		color: #<cfoutput>#selectedTextColor#</cfoutput>;
	}

	.jsgrid-selected-row > .jsgrid-cell {
		background: #<cfoutput>#hoverBgColor#</cfoutput>; 
		border-color: #<cfoutput>#hoverBorderColor#</cfoutput>;
		/* Change the color of the links */
		/* unvisited link */
		a:link {
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}

		/* visited link */
		a:visited {
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}

		/* mouse over link */
		a:hover {
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}

		/* selected link */
		a:active {
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}
	}
	
	/* Change the color of the update icon */
	.jsgrid .jsgrid-update-button:before {
		color: white;
	}

	.jsgrid-nodata-row > .jsgrid-cell {
		background: #fff;
	}

	.jsgrid-invalid input,
	.jsgrid-invalid select,
	.jsgrid-invalid textarea {
		background: #<cfoutput>#error#</cfoutput>;
		border: 1px solid #<cfoutput>#error#</cfoutput>;
	}
	
	.jsgrid-pager {
		background: #<cfoutput>#baseColor#</cfoutput>;
		color: #<cfoutput>#textColor#</cfoutput>;
		padding-left: 5px;
	}

	.jsgrid-pager-current-page {
		font-weight: bold;
	}

	.jsgrid-pager-nav-inactive-button a {
		color: #d3d3d3;
	}

	.jsgrid-button + .jsgrid-button {
		margin-left: 5px;
	}

	.jsgrid-button:hover {
		opacity: .5;
		transition: opacity 200ms linear;
	}

	.jsgrid .jsgrid-button {
		width: 20px;
		height: 20px;
		font-size: 20px;
		border: none;
		cursor: pointer;
		background-repeat: no-repeat;
		background-color: transparent;
		color: #<cfoutput>#textColor#</cfoutput>;
	}

	@media only screen and (-webkit-min-device-pixel-ratio: 2), only screen and (min-device-pixel-ratio: 2) {
		.jsgrid .jsgrid-button {
			background-size: 24px 352px;
		}
	}

	.jsgrid .jsgrid-mode-button {
		width: 24px;
		height: 24px;
	}

	.jsgrid-mode-on-button {
		opacity: .5;
	}

	.jsgrid-cancel-edit-button { background-position: 0 0; width: 16px; height: 16px; }
	.jsgrid-clear-filter-button { background-position: 0 -40px; width: 16px; height: 16px; }
	.jsgrid-delete-button { background-position: 0 -80px; width: 16px; height: 16px; }
	.jsgrid-edit-button { background-position: 0 -120px; width: 16px; height: 16px; }
	.jsgrid-insert-mode-button { background-position: 0 -160px; width: 24px; height: 24px; }
	.jsgrid-insert-button { background-position: 0 -208px; width: 16px; height: 16px; }
	.jsgrid-search-mode-button { background-position: 0 -248px; width: 24px; height: 24px; }
	.jsgrid-search-button { background-position: 0 -296px; width: 16px; height: 16px; }
	.jsgrid-update-button { background-position: 0 -336px; width: 16px; height: 16px; }

	.jsgrid-load-shader {
		background: #ddd;
		opacity: .5;
		filter: alpha(opacity=50);
	}

	.jsgrid-load-panel {
		width: 15em;
		height: 5em;
		background: #fff;
		border: 1px solid #e9e9e9;
		padding-top: 3em;
		text-align: center;
	}

	.jsgrid-load-panel:before {
		content: ' ';
		position: absolute;
		top: .5em;
		left: 50%;
		margin-left: -1em;
		width: 2em;
		height: 2em;
		border: 2px solid #009a67;
		border-right-color: transparent;
		border-radius: 50%;
		-webkit-animation: indicator 1s linear infinite;
		animation: indicator 1s linear infinite;
	}

	@-webkit-keyframes indicator
	{
		from { -webkit-transform: rotate(0deg); }
		50%  { -webkit-transform: rotate(180deg); }
		to   { -webkit-transform: rotate(360deg); }
	}

	@keyframes indicator
	{
		from { transform: rotate(0deg); }
		50%  { transform: rotate(180deg); }
		to   { transform: rotate(360deg); }
	}

	/* old IE */
	.jsgrid-load-panel {
		padding-top: 1.5em\9;
	}
	.jsgrid-load-panel:before {
		display: none\9;
	}
	
</style>
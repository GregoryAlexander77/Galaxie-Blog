
<!---
	Name         : search.cfm
	Author       : Raymond Camden 
				 : Gregory Alexander
	Created      : February 9, 2007
	Last Updated : December 1 2018
	History      : Wholesale changes to the UI by Gregory
	Purpose		 : Search Logic
	Note		 : This will incorporate a Kendo grid in the next version so I did not make any effort to paginate the form. I am trying to get out the basic version using Kendo's open source package (which does not include a grid) asap.
--->

<!--- Include the resource bundle. --->
<cfset getResourceBundle = application.utils.getResource>
<!--- Include the UDF (this is not automatically included when using an application.cfc) --->
<cfinclude template="includes/udf.cfm">

<!--- allow for /xxx shortcut --->
<cfif cgi.path_info is not "/search.cfm">
	<cfset searchAlias = listLast(cgi.path_info, "/")>
<cfelse>
	<cfset searchAlias = "">
</cfif>

<cfif structKeyExists(url, "search")>
	<cfset form.search = url.search>
</cfif>
<cfif structKeyExists(url, "category")>
	<cfset form.category = url.category>
</cfif>

<cfparam name="url.start" default="1">
<cfparam name="form.search" default="#searchAlias#">
<cfparam name="form.category" default="">

<cfset form.search = left(htmlEditFormat(trim(form.search)),255)>

<cfset cats = application.blog.getCategories()>

<cfset params = structNew()>
<cfset params.searchTerms = form.search>
<cfif form.category is not "">
	<cfset params.byCat = form.category>
</cfif>
<cfset params.startrow = url.start>
<cfset params.maxEntries = application.maxEntries>
<!---// dgs: only get released items //--->
<cfset params.releasedonly = true />

<cfif len(form.search) or form.category is not "">
	<cfset results = application.blog.getEntries(params)>
	<cfset searched = true>
<cfelse>
	<cfset searched = false>
</cfif>

<cfset title = getResourceBundle("search")>

	
<script>
	
	// Function to allow the user to hit the enter key to submit a search request.
	(function() {
        var submitSearch = document.getElementById('siteSearchField');
		// Create a listener.
        submitSearch.addEventListener('keypress', function(event) {
            // If the enter key was pressed....
			if (event.keyCode == 13) {
				// Prevent the default action for safety.
                event.preventDefault();
				// Use the on click event of the search button.
                document.getElementById('searchSubmit').click();
            }
        });//..submitSearch.addEventListener('keypress', function(event) {
    }());//..(function() {
	
	// Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', We are using direct binding here to speed up the event.
	var searchTermSubmit = $('#searchSubmit');
	searchTermSubmit.on('click', function(e){      
		// Prevent any other action.
		e.preventDefault();     
		// Call the validator if the form is not valid.
		if (searchFormValidator.validate()) {
			// submit the form.
			// Note: when testing the ui validator, comment out the post line below. It will only validate and not actually do anything when you post.
			// alert('posting');
			postSearchTerm();
		} else {//..if (addCommentFormValidator.validate()) {
			// Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension.
			$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "A search term is required. Please correct the highlighted fields and try again.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "140px" }) // or k-ext-error, k-ext-question
				).done(function () {
				// Do nothing
			});//..$.when(kendo.ui.ExtAlertDialog.show...
		}//..if (addCommentFormValidator.validate()) {
	});//..addCommentSubmit.on('click', function(e){ 
	
	function postSearchTerm(){
		// Get the value of the forms
		var searchTerm = $( "#siteSearchField" ).val();
		var category = $( "#category" ).val();
		var startRow = $( "#startRow" ).val();

		// Open the plese wait window. Note: the ExtWaitDialog's are mine and not a part of the Kendo official library. I designed them as I prefer my own dialog design over Kendo's dialog offerings.
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Searching.", icon: "k-ext-information" }));
		// Use a quick set timeout in order for the data to load.
		setTimeout(function() {
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		}, 500);
		// Get a reference to the add comment window
		var searchWindow = $("#searchWindow").data("kendoWindow");
		// Close the add comment window
		searchWindow.close();

		// Use a quick set timeout in order for the window to load
		setTimeout(function() {
			// Open the search results window. This script is on the index.cfm template
			createSearchResultWindow(searchTerm, category, startRow);
		}, 500);
		// Return false in order to prevent any potential redirection.
		return false;
	}//..function postSearchTerm(){

	$(document).ready(function() {
		
		// create MultiSelect from select HTML element
        var categoryMultiselect = $("#category").kendoMultiSelect().data("kendoMultiSelect");
		
		// Validation
		// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. Also data attributes that are dash separated become camel cased when retrieved using jQuery.
		searchFormValidator = $("#search").kendoValidator({
			// Set up custom validation rules 
			rules: {
				// Search term
				// Name of custom rule. 
				// This can be any name, but I typically put the name of the field and a verb to indicate what I am enforcing ('nameIsRequired'). Note: if you just want to check to see if something was entered you can specify 'required' in the form element.
				searchTermRequired:
				function(input){
					// Trigger by the input name and set up the logic that must be enforced. Note: you can make the logic as long as you want, but I typically apply a new rule for every discreet thing that I want to enforce in order to specify a unique message. The choice is up to you.
					if (input.is("[id='siteSearchField']") && $.trim(input.val()).length < 3 ){
						// Display an error on the page. The input.attr should be 'data-' + name of custom rule + 'Required-msg'. This will embed the custom message in the data-required-msg field on the form when there are errors. You can spedify as many rules as you want to on the form in order to show several messages at once. Remember that the data attributes that are dash separated become camel cased when retrieved using jQuery. For example, the string 'data-commenterNameRequired-msg' will be inserted into the following attribute: 'data-required-msg'. I am not sure why the rule name is inserted into this data-attr, but it is, and can be confusing at first.
						input.attr("data-searchTermRequired-msg", "A search term is required.");
						// Focus on the current element
						$( "#siteSearchField" ).focus();
						// Abort processing the next rule.
						return false;
					} 
					// Continue processing to the next rule.
					return true;
				}//..function(input){
			},//..searchTermRequired: 
		}).data("kendoValidator");
		
	});//..document.ready

</script>

<form id="search" name="search" action="#" method="post">
<table align="center" class="k-content" width="100%" cellpadding="3" cellspacing="0">
	<input type="hidden" id="startRow" name="startRow" value="0"/>
	<tr height="30px">
		<td align="right" width="30%"><label for="siteSearchField">Search Term:</label></td>
		<td align="left"  width="*"><input id="siteSearchField" name="siteSearchField" class="k-textbox" style="width:<cfif session.isMobile>60%<cfelse>250px;</cfif>" required data-required-msg="Enter search term."/></td>
	</tr>
	<tr height="30%">
		<td align="right">Category:</td>
		<td align="left">
		<select id="category"  name="category" multiple="multiple" style="width:85%;" data-placeholder="Select categories...">
			<option value="" <cfif form.category is "">selected="selected"</cfif>>all categories</option>
			<cfoutput query="cats">
			<option value="#categoryid#" <cfif form.category is categoryid>selected="selected"</cfif>>#categoryname#</option>
			</cfoutput>
		</select>
		</td>
	</tr>
	<tr>
		<td class="border" colspan="2"></td>
	</tr>
	<tr>
		<td></td>
		<td><input type="button" id="searchSubmit" name="searchSubmit" value="Search" class="k-button k-primary" style="width: <cfif session.isMobile>115px<cfelse>85px</cfif>" /></td>
	</tr>
	<tr>
		<td class="border" colspan="2"></td>
	</tr>
	<tr>
		<td colspan="2" style="font-size: 14px; color: grey">Note: you may select multiple categories.</td>
	</tr>
</table>
</form>


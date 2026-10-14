	<!--- Instantiate the Render.cfc. This will be used to render our directives and create video and map thumbnails --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	
	<!--- Get the post ( ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) ) 
	<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>--->
	<cfinvoke component="#application.blog#" method="getPostByPostId" returnvariable="getPost">
		<cfinvokeargument name="postId" value="#URL.optArgs#">
		<cfinvokeargument name="showPages" value="true">
		<cfinvokeargument name="showBlogPosts" value="true">
		<cfinvokeargument name="showPendingPosts" value="true">
		<cfinvokeargument name="showRemovedPosts" value="true">		
	</cfinvoke>
	<!---<cfdump var="#getPost#">--->
		
	<!--- Get the Body --->
	<cfset body = getPost[1]["Body"]>
	<!--- And more body (when a <more/> tag is present) --->
	<cfset moreBody = getPost[1]["MoreBody"]>
	<!--- Set the body. We need to determine the content based upon the more tag if it exists. If the more tag exists- append the moreBody to the body ---> 
	<cfif len(moreBody)>
		<!--- Append the more body to the body. TinyMce will append an extra more tag, we might as well do it here. --->
		<cfset body = body & '<more/> ' & moreBody>
	</cfif>	
		
	<!--- If there are scripts, put HTML comments around them to escape the sript- otherwise the content will terminate at the fist script when using the tinymce setContent method. --->
	<cfset body = RendererObj.renderScriptsToTinyMce(body)>
	
	<!--- Also render the post for prism. We need to add pre and script tags here. --->
	<cfset body = RendererObj.renderCodeForPrism(body)>
		
	<!--- Compare the datePosted and blogSortDate to set the initial value of the blogSortDateChange hidden field. We only want to set this to 1 (true) if the two dates are different --->
	<!--- 
	Debugging 
	<cfoutput>
		getPost[1]['DatePosted']: #getPost[1]['DatePosted']#<br/>
		getPost[1]['BlogSortDate']: #getPost[1]['BlogSortDate']#<br/>
		blogSortDateIsDifferent: #blogSortDateIsDifferent#<br/>
		dateCompare(getPost[1]['DatePosted'], getPost[1]['BlogSortDate']): #dateCompare(getPost[1]['DatePosted'], getPost[1]['BlogSortDate'])#<br/>
	</cfoutput>
	--->
	<cfif dateCompare(getPost[1]['DatePosted'], getPost[1]['BlogSortDate']) eq 0>
		<cfset blogSortDateIsDifferent = 0>
	<cfelse>
		<cfset blogSortDateIsDifferent = 1>
	</cfif>
		
	<!--- Subscriber email (2026-10-12). Whether to email is now decided when Submit is clicked (verifyPostEmail below), not
	when this window opens: the old check compared the post's date with the time the window was opened, so a post whose
	date was still a little ahead at that moment never offered to email, however long the window then stayed open.
	- releasedPostEmailMode: Blog Options, Subscriber Email - 'prompt' (ask) or 'auto' (send the first time it is released).
	- a post whose date is still ahead when Submit is clicked is scheduled: savePost creates the task that releases and emails
	  it when it goes live, so the editor only says so.
	- blogNowAtLoad: the blog's own clock (blogNow) when this window opened. The script adds the time the window has been
	  open, so the comparison uses the blog's time zone, not the time zone of the computer the editor runs on. --->
	<cfset releasedPostEmailMode = application.blog.getReleasedPostEmailMode()>
	<cfset postWasMailed = isBoolean(getPost[1]["Mailed"]) and getPost[1]["Mailed"]>
	<cfset blogNowAtLoad = application.blog.blogNow()>

	<!--- Was this already mailed? --->
	<cfif getPost[1]["Mailed"]>
		<!--- The user can still email the post again --->
		<cfset promptEmailTitle = "Do you want to email the post again?">
		<cfset promptEmailMessage = "A previous email was sent, do you want to send the revised post out again?">
	<cfelse>
		<cfset promptEmailTitle = "Do you want to email the post?">
		<cfset promptEmailMessage = "Do you want to send this post out to your subscribers?">
	</cfif>
			
	<!--- When a post is being removed, we will warn the user that the post will be removed. If the user accepts, we will prompt the user again to ask them if they want to redirect the URL. --->
	<cfset postRemoved = getPost[1]['Remove']>
	<cfset postRedirectUrl = getPost[1]['RedirectUrl']>
	<cfset postRedirectType = getPost[1]['RedirectType']>
		
	<cfif postRemoved>
		<cfif len(postRedirectUrl)>
			<cfset postRemovedHtml = '<div class="k-block k-error-colored" align="left"><p>This post has been removed and there is a <a href="javascript:promptForUrlRedirect()">#postRedirectType# URL redirect</a> in place.</p><p>You may permanently <a href="javascript:deletePost();">delete it</a>, however, doing so will delete the redirect as well.</p></div>'>
		<cfelse>
			<cfset postRemovedHtml = '<p class="k-block k-error-colored" align="left">This post has been removed. You may permanently <a href="javascript:deletePost();">delete it</a>.</p>'>
		</cfif>
	</cfif>
	
	<!--- Render the thumnbail HTML. Pass in the getPost obj and if you want to render the thumbnail --->
	<cfset thumbnailHtml = RendererObj.renderMediaPreview(kendoTheme, getPost, true)>
		
	<cfif not arrayLen(getPost)>
		<p>Post does not exist</p>
		<cfabort>
	</cfif>
	
	<!--- Drop down queries --->
	<!--- Get all of the selected categories. We need this to display the current categories in the dropdown menu --->
	<cfset getSelectedCategories = application.blog.getCategoriesForPost(URL.optArgs)>
	<cfset getSelectedTags = application.blog.getTagsForPost(URL.optArgs)>
	<cfset getRelatedPosts = application.blog.getRelatedPosts(postId=URL.optArgs)>
	<!---Related Posts: <cfdump var="#getRelatedPosts#">--->
	<!--- Page Collections - which Collection(s) this Page belongs to, plus every Collection that exists to populate the multi-select. Only relevant for a Page, not a Post. --->
	<cfset getSelectedPageCollections = application.blog.getPageCollectionsForPost(URL.optArgs)>
	<cfset getAllPageCollectionsForDropdown = application.blog.getAllPageCollections()>
		
	<!--- Create a list of categories --->
	<cfset thisSelectedCategoryIdList = "">
	<!--- Loop through the selected categories (note: listAppend can be used here too. I am used to this approach) --->
	<cfloop from="1" to="#arrayLen(getSelectedCategories)#" index="i">
		<cfif i eq 1>
			<cfset thisSelectedCategoryIdList = getSelectedCategories[i]['CategoryId']>
		<cfelse>
			<cfset thisSelectedCategoryIdList = thisSelectedCategoryIdList & ',' & getSelectedCategories[i]['CategoryId']>
		</cfif>
	</cfloop>

	<style>
		label {
			font-weight: normal;
		}

		normalFontWeight {
			font-weight: normal;
		}
	</style>

	<!---//***************************************************************************************************************
				TinyMce Scripts
	//****************************************************************************************************************--->
		
	<!---********************* Post Detail editor *********************--->
	<!--- Set the common vars for tinymce. --->
	<cfsilent>
	<cfset selectorId = "postEditor">
	<cfif smallScreen>
		<cfset editorHeight = "600">
	<cfelse>
		<cfset editorHeight = "650">
	</cfif>
	<!--- This string is used by the tiny mce editor to handle image uploads --->
	<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=post&mediaType=image&postId=" & getPost[1]['PostId'] & "&selectorId=" & selectorId & "&csrfToken=" & csrfToken>
	<cfset contentVar = body><!---EncodeForHTMLAttribute--->
	<cfset imageMediaIdField = "imageMediaId">
	<cfset imageClass = "entryImage">

	<cfif smallScreen>
		<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
	<cfelse>
		<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | tox | hr | link | image editimage | media | fancyBoxGallery | map mapRouting | customWindow webForm | emoticons">
	</cfif>
	<cfset includeGallery = true>
	<cfset includeCustomWindow = true>
	<!--- Forms (2026-10-13): the Insert Form button. --->
	<cfset includeWebForm = true>
	</cfsilent>
	<!--- Include the tinymce js template --->
	<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
		
	<cfsilent>
	
	<!---//***************************************************************************************************************
				Kendo Scripts
	//****************************************************************************************************************--->
	</cfsilent>
	
	<script>
		
		<!--- Raise a dialog when the post has been released and the title has changed. Chaning the title can be detrimental to SEO once the post is released, however, there are times when the user may want to change it. --->
		function checkTitle(){
			<!--- Set a var to determine if the post has been released. We also want to check the dates when the post is first released, but not afterward --->
			var postReleased = <cfif getPost[1]["Released"]>true<cfelse>false</cfif>;
			
			if ( postReleased && ( $("#title").val() != '<cfoutput>#getPost[1]["Title"]#</cfoutput>' ) ) {
				<!--- If the title has changed, raise an alert --->
				$.when(kendo.ui.ExtYesNoDialog.show({ 
						title: "Change Title and Link?",
						message: "Changing the post link after the post has been released can have adverse effects on SEO especially if Goolgle indexed the URL. Do you also want to change the link to your post?",
					icon: "k-ext-info",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
					height: "275px"
					})
				).done(function (response) { // If the user clicked 'yes'
					if (response['button'] == 'Yes'){// remember that js is case sensitive.
						<!--- Change the hidden form to indicate that we will change the title and link --->
						$("#changeTitleAndLink").val(1);
					} else {
						<!--- We are changing the title, but not the link --->
						$("#changeTitleAndLink").val(0);
					}
				});//).done(function (response)...
			}
		}

		$(document).ready(function() {

			<!--- The window's title/height/width are set generically by createAdminInterfaceWindow() before this content even loads (it doesn't know yet whether postId is a Page or a Post), so this is the one place that actually knows - update the title here instead. --->
			<cfif getPost[1]['IsPage']>
			try {
				$("#postDetailWindow").data("kendoWindow").title("Edit Page");
			} catch (e) {
				<!--- Do nothing --->
			}
			</cfif>

			<!--- Set a var to determine if the post has been released. We also want to check the dates when the post is first released, but not afterward --->
			var postReleased = <cfif getPost[1]["Released"]>true<cfelse>false</cfif>;
			var todaysDate = new Date(); 
			<!--- Are the post dates and sort dates the same? If so, we are assuming that the two dates are identical when suggesting a date change. If they are different dates, we will leave the sort date alone when suggesting dates. --->
			var originalPostDate = <cfoutput>#application.Udf.jsDateFormat(getPost[1]['DatePosted'])#</cfoutput>;
			var originalBlogSortDate = <cfoutput>#application.Udf.jsDateFormat(getPost[1]['BlogSortDate'])#</cfoutput>;
			
			<!--- Compare the post date to the sort date and set a var --->
			if (originalPostDate.getTime() === originalBlogSortDate.getTime() ){
				var syncPostAndSortDate = true;
			} else {
				var syncPostAndSortDate = false;
			}
			
			<!--- Check and recommend dates when the date is changed or the post has just been released. --->
			function checkAndRecommendDates(selectedDate) {				
				<!--- Check to see if the selected date is greater than today --->
				if (selectedDate > todaysDate){
					$.when(kendo.ui.ExtYesNoDialog.show({ 
							title: "Release post in the future?",
							message: "You are posting at a later date in the future. If you continue and submit this post, it will be scheduled to be automatically published on your selected date in the future. Do you want to continue?",
						icon: "k-ext-info",
						width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
						height: "275px"
						})
					).done(function (response) { // If the user clicked 'yes'
						if (response['button'] == 'Yes'){// remember that js is case sensitive.
							<!--- Do nothing --->
						} else {
							<!--- Change the date to now --->
							$("#datePosted").kendoDateTimePicker({
								value: new Date(Date.now())
							});
						}
					});//).done(function (response)..
				<!--- Is the selected date less than today's date? --->
				} else if (selectedDate < todaysDate){
					<!--- Suggest changing the post date --->
					$.when(kendo.ui.ExtYesNoDialog.show({ 
						title: "Can we change the post date to the current time and date?",
						message: "You are using an older date and this may negatively impact the post placement and your RSS feeds. Can we change the post date using the current date?",
						icon: "k-ext-info",
						width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
						height: "275px"
						})
					).done(function (response) { // If the user clicked 'yes'
						if (response['button'] == 'Yes'){// remember that js is case sensitive.
							<!--- Change the date posted to now --->
							$("#datePosted").kendoDateTimePicker({
								value: new Date(Date.now())
							});
							<!--- Change the sort date in the hidden field when they are the same --->
							$("#newBlogSortDate").val( todaysDate );
						} else {
							<!--- Do nothing --->
						}
					});//).done(function (response)..
				}//} else if (this.value() < todaysDate){{..
            }//..onDatePostedChange
			
			<!--- Kendo Dropdowns Date posted date/time picker - Pages have no Date Posted field (no #datePosted element in the DOM to match, it's hidden below), so this whole init/change setup is Post-only. --->
			<cfif not getPost[1]['IsPage']>
			$("#datePosted").kendoDateTimePicker({
                componentType: "modern",
				value: <cfif len(getPost[1]['DatePosted'])>originalPostDate<cfelse>new Date()</cfif>,
				change: onDatePostedChange
            });

			<!--- Check the dates when the post date is changed. --->
			function onDatePostedChange() {
                <!--- Check and recommend dates depending upon the selected date --->
				checkAndRecommendDates(this.value());
            }//..onDatePostedChange
			</cfif><!---<cfif not getPost[1]['IsPage']>--->

			<!--- Also check the dates when the released button is clicked - guarded since a Page has the Released checkbox but no #datePosted widget to read. --->
			$('#released').click(function(){
				if($(this).is(':checked') && $("#datePosted").data("kendoDateTimePicker")){
					var selectedDate = kendo.toString($("#datePosted").data("kendoDateTimePicker").value());
					checkAndRecommendDates(selectedDate);
				}
			});
			
			<!--- --- author dropdown. --- --->
			<!--- Pages have no author field, and no #author select in the DOM to match (its HTML is hidden below) - same reasoning as the Tags/Related Posts blocks. --->
			<cfif not getPost[1]['IsPage']>
			var authorDs = new kendo.data.DataSource({
				transport: {
					read: {
						cache: false,
						<!--- Note: since this template is in a different directory, we can't specify the cfc template without the full path name. --->
						url: function() { // The cfc component which processes the query and returns a json string.
							return "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAuthorsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>";
						},
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					}
				} //...transport:
			});//...var authorDs...

			<!--- Create the top level dropdown --->
			var author = $("#author").kendoDropDownList({
				<!--- cascadeFrom: "agencyRateCompanyCode", --->
				optionLabel: "Select...",
				<!--- Template to add a new type when no data was found. --->
				noDataTemplate: $("#addUser").html(),
				autoBind: false,
				dataTextField: "FullName",
				dataValueField: "UserId",
				filter: "contains",
				dataSource: authorDs,
				<!--- Use the close event to fire off events. The change event is fired off when setting the value of this dropdown list. --->
				close: onAuthorChange
			}).data("kendoDropDownList");

			<!--- Set default value by the value (this is used when the container is populated via the datasource). --->
			var author = $("#author").data("kendoDropDownList");
			author.value( <cfoutput>#getPost[1]['UserId']#</cfoutput> );
			author.trigger("change");

			<!--- On change function to save the selected value. --->
			function onAuthorChange(e){
				<!--- Get the value --->
				userId = this.value();
			}//...function onAuthorChange(e)
			</cfif><!---<cfif not getPost[1]['IsPage']>--->
			
			<!--- --- category dropdown. --- --->
			<!--- Pages only ever use Page Collections for grouping, not Categories (deliberately not both, to avoid reintroducing the tangled category-based membership the Page Collections redesign replaced) - no #postCategories select in the DOM for a Page (hidden below), so this whole block is Post-only. --->
			<cfif not getPost[1]['IsPage']>
			<!--- Category datasource. --->
			var categoryDs = new kendo.data.DataSource({
				<!--- serverFiltering: "true",// Since we are using serverFiltering, the values from the previous dropdown will be sent to the server for processing. --->
				transport: {
					read: {
						<!--- We are using a function to pass additional selected arguments to the cfc. --->
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCategoriesForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					},//...read:
				}//...transport:
			});//...var categoryDs...

			<!--- Note: categories is a reserved Kendo word- if you name this categories, it will fail. --->
			$("#postCategories").kendoMultiSelect({
				autoBind: true,
				filter: "contains",
				<!--- Template to add a new type when no data was found. --->
				noDataTemplate: $("#addCategoryNoData").html(),
				placeholder: "Select Category...",
				dataTextField: "Category",
				dataValueField: "CategoryId",
				dataSource: categoryDs,
				value: [<cfloop from="1" to="#arrayLen(getSelectedCategories)#" index="i">
					<cfsilent>
					<cfset categoryId = getSelectedCategories[i]['CategoryId']>
					<cfset category = getSelectedCategories[i]['Category']>
					</cfsilent>
                    { CategoryId: "<cfoutput>#categoryId#</cfoutput>", Category: "<cfoutput>#category#</cfoutput>" },
                </cfloop>],
				change: function(e){
					<!--- Get the value --->
					var selectedCategories = $("#postCategories").data("kendoMultiSelect").value();
					<!--- And set it into the hidden form --->
					$("#selectedPostCategories").val(selectedCategories);
				}
			});//...$("#postCategories")
			</cfif><!---<cfif not getPost[1]['IsPage']>--->
			
			<!--- --- tags dropdown. --- --->
			<!--- Pages have no tags, and no #postTags select in the DOM to match (its HTML is hidden below) - skip this entire block for a Page, or kendoMultiSelect() ends up binding to a jQuery selection that matches nothing, which throws downstream. --->
			<cfif not getPost[1]['IsPage']>
			<!--- tag datasource. --->
			var tagDs = new kendo.data.DataSource({
				<!--- serverFiltering: "true",// Since we are using serverFiltering, the values from the previous dropdown will be sent to the server for processing. --->
				transport: {
					read: {
						<!--- We are using a function to pass additional selected arguments to the cfc. --->
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getTagsForDropdown&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					},//...read:
				}//...transport:
			});//...var tagDs...

			<!--- Note: categories is a reserved Kendo word- if you name this categories, it will fail. --->
			$("#postTags").kendoMultiSelect({
				autoBind: true,
				filter: "contains",
				<!--- Template to add a new type when no data was found. --->
				noDataTemplate: $("#addTagNoData").html(),
				placeholder: "Select Tag...",
				dataTextField: "Tag",
				dataValueField: "TagId",
				dataSource: tagDs,
				value: [<cfloop from="1" to="#arrayLen(getSelectedTags)#" index="i">
					<cfsilent>
					<cfset tagId = getSelectedTags[i]['TagId']>
					<cfset tag = getSelectedTags[i]['Tag']>
					</cfsilent>
                    { TagId: "<cfoutput>#tagId#</cfoutput>", Tag: "<cfoutput>#tag#</cfoutput>" },
                </cfloop>]
			});//...$("#postTags")
			</cfif><!---<cfif not getPost[1]['IsPage']>--->

			<!--- Which Page Collection(s) this Page belongs to - reads its options straight from the server-rendered <option> list rather than a separate datasource, since Page Collections is a short, blog-wide list already rendered into the page. Pages only, so this element may not exist on a Post. noDataTemplate offers a way to create one on the spot when none exist yet, same pattern as the Category/Tag "not found, add it?" templates above. --->
			<cfif getPost[1]['IsPage']>
			$("#postPageCollections").kendoMultiSelect({
				autoBind: true,
				filter: "contains",
				noDataTemplate: $("#addPageCollectionNoData").html(),
				placeholder: "Select Page Collection...",
				value: [<cfloop array="#getSelectedPageCollections#" index="pcSel">
					<cfoutput>"#pcSel.pageCollectionId#",</cfoutput>
				</cfloop>]
			});//...$("#postPageCollections")
			</cfif>

			<!--- --- related posts dropdown. --- --->
			<!--- Pages have no related-posts concept, and no #relatedPosts select in the DOM (its HTML is hidden below) - same reasoning as the Tags block above. --->
			<cfif not getPost[1]['IsPage']>
			<!--- Related Posts datasource. --->
			var relatedPostsDs = new kendo.data.DataSource({
				transport: {
					read: {
						<!--- We are using a function to pass additional selected arguments to the cfc. --->
						url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPostsTitleAndId&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
						dataType: "json",
						contentType: "application/json; charset=utf-8", // Note: when posting json via the request body to a coldfusion page, we must use this content type or we will get a 'IllegalArgumentException' on the ColdFusion processing page.
						type: "GET" //Note: for large payloads coming from the server, use the get method. The post method may fail as it is less efficient.
					},//...read:
				}//...transport:
			});//...var categoryDs...

			$("#relatedPosts").kendoMultiSelect({
				autoBind: true,
				placeholder: "Select Related Post...",
				dataTextField: "Title",
				dataValueField: "PostId",
				filter: "contains",
				dataSource: relatedPostsDs,
				value: [<cfloop from="1" to="#arrayLen(getRelatedPosts)#" index="i">
					<cfsilent>
					<cfset PostId = getRelatedPosts[i]["PostId"]>
					<cfset Title = getRelatedPosts[i]["Title"]>
					</cfsilent>
                    { PostId: "<cfoutput>#PostId#</cfoutput>", Title: "<cfoutput>#Title#</cfoutput>" },
                </cfloop>]
			});//...$("#relatedPosts")
			</cfif><!---<cfif not getPost[1]['IsPage']>--->
			
			<!--- --- form validation --- --->
		
			// !!! Note on the validators, all forms need a name attribute, otherwise the positioning of the messages will not work. --->
			var postDetailFormValidator = $("#postDetails").kendoValidator({
				<!--- Set up custom validation rules --->
				rules: {
					<!--- title --->
					titleRequired:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length < 3){
							<!--- Display an error on the page. --->
							input.attr("data-titleRequired-msg", "The title must be at least 3 characters");
							<!--- Focus on the current element --->
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					titleMaxLen:
					function(input){
						if (input.is("[id='title']") && $.trim(input.val()).length > 125){
							<!--- Display an error on the page. --->
							input.attr("data-titleMaxLen-msg", "The title can't have more than 125 characters");
							<!--- Focus on the current element --->
							$( "#title" ).focus();
							return false;
						}                                    
						return true;
					},
					<!--- Desc --->
					descriptionRequired:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length < 3){
							<!--- Display an error on the page. --->
							input.attr("data-descriptionRequired-msg", "The description is required");
							<!--- Focus on the current element --->
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					},
					descriptionLen:
					function(input){
						if (input.is("[id='description']") && $.trim(input.val()).length > 1250){
							<!--- Display an error on the page. --->
							input.attr("data-descriptionLen-msg", "The description needs to be under 1250 characters");
							<!--- Focus on the current element --->
							$( "#description" ).focus();
							return false;
						}                                    
						return true;
					}
				}
			}).data("kendoValidator");
		
			<!--- Invoked when the submit button is clicked. Instead of using '$("form").submit(function(event) {' and 'event.preventDefault();', we are using direct binding here to speed up the event. --->
			var postDetailSubmit = $('#postDetailSubmit');
			postDetailSubmit.on('click', function(e){  
                e.preventDefault();         
				if (postDetailFormValidator.validate()) {
					<!--- If the selected postType radio button is page, submit the page. Otherwise, raise a dialog asking the admin if they want to send email to subscribers --->
					if ($("input[type=radio][name=postType]:checked" ).val() == 'page'){
						<!--- Submit the page and don't generate an email (postDetails(action, sendEmail)) --->
						postDetails('update', false);
					} else {
						<!--- Raise a prompt to see if the author wants to send email --->
						verifyPostEmail('update');
					}
				} else { //if (postDetailFormValidator.validate()) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "There are errors", message: "Required fields have not been filled out. Please correct the highlighted fields and try again", icon: "k-ext-warning" }) // or k-ext-error, k-ext-question
						).done(function () {
						<!--- Do nothing --->
					});
				}//if (postDetailFormValidator.validate()) {
			});
		});//...document.ready
		
		function confirmPostRemoval(){
			
			<!--- Confirm post removal Note: this is a custom library that I am using. The ExtAlertDialog is not a part of Kendo but an extension. --->
			$.when(kendo.ui.ExtYesNoDialog.show({ 
				title: "Remove post?",
				message: "Are you sure? This will remove the post from the blog.",
				icon: "k-ext-warning",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes', post it.
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					<!--- Raise a dialog asking the admin if they want to create a redirect --->
					promptForUrlRedirect('update');
				} else {
					<!--- Uncheck the remove checkbox --->
					$('#remove').prop('checked', false);
				}//..if (response['button'] == 'Yes'){
			});
		}
		
		function promptForUrlRedirect(action){
			<!--- If the post is released and it removed, prompt to see if we should create a URL redirect --->
			if ( $('#released').is(':checked') && $('#remove').is(':checked') ){
				$.when(kendo.ui.ExtYesNoDialog.show({ 
					title: "Create URL Redirect?",
					message: "Do you want to redirect this post to another URL?",
					icon: "k-ext-question",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", 
					height: "215px"
				})
				).done(function (response) { // If the user clicked 'yes'
					if (response['button'] == 'Yes'){// remember that js is case sensitive.
						<!--- Open a new interface to enter the new URL --->
						createAdminInterfaceWindow(56,<cfoutput>#getPost[1]['PostId']#</cfoutput>)
					} else {
						<!--- postDetails(action, sendEmail) --->
						postDetails('update', false);
					}//..if (response['button'] == 'Yes'){
				});//..if ($('#released').is(':checked')){
			} else {
				<!--- postDetails(action, sendEmail) --->
				postDetails('update', false);
			}
		}
		
		<!--- The blog's clock when this window opened, and when that was on this computer (see blogNowAtLoad at the top). --->
		var postDetailBlogNowAtLoad = new Date(<cfoutput>#year(blogNowAtLoad)#, #month(blogNowAtLoad) - 1#, #day(blogNowAtLoad)#, #hour(blogNowAtLoad)#, #minute(blogNowAtLoad)#, #second(blogNowAtLoad)#</cfoutput>);
		var postDetailOpenedAt = Date.now();

		function verifyPostEmail(action){
			var releasedPostEmailMode = "<cfoutput>#releasedPostEmailMode#</cfoutput>";
			var postWasMailed = <cfoutput>#postWasMailed ? "true" : "false"#</cfoutput>;
			<!--- Nothing to email: not released, or being removed. --->
			if ( !$('#released').is(':checked') || $('#remove').is(':checked') ){
				postDetails('update', false);
				return;
			}
			<!--- Scheduled: the post's date is still ahead of the blog's clock right now. savePost schedules the release, and the
			subscribers are emailed when it goes live (whatever Blog Options says), so only tell the author. --->
			var datePicker = $("#datePosted").data("kendoDateTimePicker");
			var blogNow = new Date(postDetailBlogNowAtLoad.getTime() + (Date.now() - postDetailOpenedAt));
			if (datePicker && datePicker.value() && datePicker.value() > blogNow){
				$.when(kendo.ui.ExtAlertDialog.show({
					title: "Scheduled",
					message: "This post is scheduled for " + kendo.toString(datePicker.value(), "MMM d, yyyy h:mm tt") + ". Subscribers will be emailed when it goes live.",
					icon: "k-ext-information",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>"
				})).done(function () {
					postDetails('update', false);
				});
				return;
			}
			<!--- Blog Options, Subscriber Email = send automatically: email it the first time it is saved as released, without asking. --->
			if (releasedPostEmailMode == "auto"){
				postDetails('update', !postWasMailed);
				return;
			}
			<!--- Otherwise ask, every time a released post is saved (the title says so when it was emailed before). --->
			$.when(kendo.ui.ExtYesNoDialog.show({
				title: "<cfoutput>#promptEmailTitle#</cfoutput>",
				message: "<cfoutput>#promptEmailMessage#</cfoutput>",
				icon: "k-ext-question",
				width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>",
				height: "215px"
			})
			).done(function (response) { // If the user clicked 'yes'
				if (response['button'] == 'Yes'){// remember that js is case sensitive.
					postDetails('update', true);
				} else {
					postDetails('update', false);
				}//..if (response['button'] == 'Yes'){
			});
		}
		
		<!--- Post method on the detail form called from the commentDetailFormValidator method on the detail page. The action variable will either be 'update' or 'insert'. --->
		function postDetails(action, sendEmail){
			
			<!--- Get a reference to the post editor and run a final pass to make sure any table-of-contents anchors use descriptive slugs (see rewriteTocAnchors in tinyMce.cfm) rather than the toc plugin's random mcetoc_ ids, in case the TOC was inserted/updated without triggering the editor's own ExecCommand hook for some reason. This guarantees the saved content is always clean. --->
			var postEditor = tinymce.get("<cfoutput>#selectorName#</cfoutput>");
			rewriteTocAnchors(postEditor);

			<!--- Get the post content --->
			var postContent = postEditor.getContent();
			//  Bypass ColdFusions global script protection to allow JavaScripts in a post. This is done by replacing '<script', '<style' and '<meta' with '<attachScript', '<attachStyle' and '<attachMeta' before the post content gets processed by the server. This JavaScript is in the blogJsContent.cfm template.
			var postContentNoScripts = bypassScriptProtection(postContent);

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePost',
				data: { // arguments
					<!--- We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#formName").serialize()' or use the stringify method to pass it as an array of values. --->
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: $("#postId").val(),
					postType: $("input[type=radio][name=postType]:checked" ).val(),
					postAlias: $("#postAlias").val(),
					<!--- Only present in the DOM for a Post - a Page has no Date Posted field to change, so fall back to its own existing date/time unchanged, same reasoning as author above. --->
					datePosted: $("#datePosted").data("kendoDateTimePicker") ? kendo.toString($("#datePosted").data("kendoDateTimePicker").value(), 'MM/dd/yyyy') : "<cfoutput>#dateFormat(getPost[1]['DatePosted'], 'mm/dd/yyyy')#</cfoutput>",
					timePosted: $("#datePosted").data("kendoDateTimePicker") ? kendo.toString($("#datePosted").data("kendoDateTimePicker").value(), 'hh:mm tt') : "<cfoutput>#timeFormat(getPost[1]['DatePosted'], 'hh:mm tt')#</cfoutput>",
					<!--- The next two values are hidden form fields populated by the post sort date interface --->
					blogSortDate: $("#newBlogSortDate").val(),
					blogSortDateChanged: $("#blogSortDateChanged").val(),
					themeId: $("#postThemeId").val(),
					<!--- Only present in the DOM for a Post - a Page has no author field to change, so fall back to its own existing author unchanged (blog.cfc's savePost() always looks up a Users row by this value, so it can't be sent blank). --->
					author: $("#author").data("kendoDropDownList") ? $("#author").data("kendoDropDownList").value() : "<cfoutput>#getPost[1]['UserId']#</cfoutput>",
					title: $("#title").val(),
					changeTitleAndLink: $("#changeTitleAndLink").val(),
					// Pass in the contents of the editor with all <script tags replaced with attach script
					post: postContentNoScripts,
					<!--- Get the value of the checkboxes --->
					released: $('#released').is(':checked'), // checkbox boolean value.
					allowComment: $('#allowComment').is(':checked'), // checkbox boolean value.
					promote: $('#promote').is(':checked'), // checkbox boolean value.
					<!--- Only present in the DOM for a Post, same as promote above - jQuery on a missing selector safely returns false rather than throwing. --->
					displayOnRss: $('#displayOnRss').is(':checked'), // checkbox boolean value.
					remove: $('#remove').is(':checked'), // checkbox boolean value.
					redirectUrl: $("#redirectUrl").val(),
					redirectType: $("#redirectType").val(),
					description: $('#description').val(), 
					<!--- We are storing the post categories in a hidden field in order to preserve the selected category order --->
					postCategories: $("#selectedPostCategories").val(),
					<!--- These multi-selects are in an array. We need to use the toString method to turn the array into comma separated values postCategories: $("#postCategories").data("kendoMultiSelect").value().toString(), --->
					<!--- Only present in the DOM for a Post - a Page has neither the field nor the widget, so guard the same way pageCollectionIdList already does below. --->
					postTags: $("#postTags").data("kendoMultiSelect") ? $("#postTags").data("kendoMultiSelect").value().toString() : "",
					relatedPosts: $("#relatedPosts").data("kendoMultiSelect") ? $("#relatedPosts").data("kendoMultiSelect").value().toString() : "",
				pageCollectionIdList: $("#postPageCollections").data("kendoMultiSelect") ? $("#postPageCollections").data("kendoMultiSelect").value().toString() : "",
					<!--- The following media items are held in hidden forms. There should only be zero or one value that is sent --->
					imageMediaId: $("#imageMediaId").val(),
					videoMediaId: $("#videoMediaId").val(),
					videoMediaId: $("#mapId").val(),
					emailSubscriber: sendEmail
				},
				dataType: "json",
				success: postDetailsResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
			}).fail(function (jqXHR, textStatus, error) {
				<!--- This is a secured function. Display the login screen. --->
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the savePost function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						<!--- Do nothing --->
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};
		
		function postDetailsResult(response){
			<!--- Are the credentials correct? --->
			if (JSON.parse(response.success) == true){
				// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#postsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				<!--- Try to refresh the post grid by refreshing the window. It may not be open so we are using a try block --->
				try {
					$("#PostsWindow").data("kendoWindow").refresh();
				} catch (error) {
					<!--- Do nothing --->
				}
				<!--- Pages are a separate grid/window (id 57) from Posts - same try-block refresh, copied from the block above, so saving a Page actually refreshes the Pages grid too. --->
				try {
					$("#PageWindow").data("kendoWindow").refresh();
				} catch (error) {
					<!--- Do nothing --->
				}
			</cfif>
				<!--- Close the window --->
				jQuery('#postDetailWindow').kendoWindow('destroy');
			} else {
				<!--- Alert the user that the process has failed. --->
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					<!--- Do nothing --->
				});
			}//..if (JSON.parse(response.success) == true){
		}//function postDetailsResult(response){
		
	<cfif postRemoved>	
		function deletePost(){

			jQuery.ajax({
				type: 'post', 
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePost',
				data: { // arguments
					<!--- We are going to map the extact same arguments, in order, of the method in the cfc here. Notes: we can also use 'data: $("#formName").serialize()' or use the stringify method to pass it as an array of values. --->
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					postId: <cfoutput>#getPost[1]['PostId']#</cfoutput>
				},
				dataType: "json",
				success: deletePostResult, // calls the result function.
				error: function(ErrorMsg) {
					console.log('Error' + ErrorMsg);
				}
			<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
			}).fail(function (jqXHR, textStatus, error) {
				<!--- This is a secured function. Display the login screen. --->
				if (jqXHR.status === 403) { 
					createLoginWindow(); 
				} else {//...if (jqXHR.status === 403) { 
					<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the deletePost function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
						).done(function () {
						<!--- Do nothing --->
					});
				}//...if (jqXHR.status === 403) { 
			});//...jQuery.ajax({
		};//function deletePost(){
		
		function deletePostResult(response){
			<!--- Are the credentials correct? --->
			if (JSON.parse(response.success) == true){
				// Refresh the <cfif application.kendoCommercial>kendo<cfelse>jsgrid</cfif> grid 
			<cfif application.kendoCommercial and 1 eq 2><!---We are not using the Kendo grids right now.--->
				$('#postsGrid').data('kendoGrid').dataSource.read();
			<cfelse>
				<!--- Try to refresh the post grid by refreshing the window. It may not be open so we are using a try block --->
				try {
					$("#PostsWindow").data("kendoWindow").refresh();
				} catch (error) {
					<!--- Do nothing --->
				}
				<!--- Pages are a separate grid/window (id 57) from Posts - same try-block refresh, copied from the block above, so deleting a Page actually refreshes the Pages grid too. --->
				try {
					$("#PageWindow").data("kendoWindow").refresh();
				} catch (error) {
					<!--- Do nothing --->
				}
			</cfif>
				<!--- Close the window --->
				jQuery('#postDetailWindow').kendoWindow('destroy');
			} else {
				<!--- Alert the user that the process has failed. --->
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error deleting post", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" }) // or k-ext-error, k-ext-question
				).done(function () {
					<!--- Do nothing --->
				});
			}//..if (JSON.parse(response.success) == true){
		}
		
	</cfif>
		
		<!--- Helper functions for the noData templates This adds a new option to the post author multi-select --->
        function addNewPostAuthor(userId,fullName) {
			<!--- Get the multiselect --->
			var multiSelect = $("#author").data("kendoMultiSelect"); 
			<!--- Get the datasource --->
            var multiSelectDs = $("#author").data("kendoMultiSelect").dataSource;
			

			<!--- Add the new item to the multiselects datasource --->
			multiSelectDs.add({
				UserId: userId,
				FullName: fullName 
			});
			
			<!--- Select the inserted value that was just added- it's in the last position in the list --->
			multiSelectDs.one("sync", function() {
				multiSelect.select(multiSelectDs.view().length - 1);
			});
			
			<!--- Sync the the datasource --->
			multiSelectDs.sync();
        };
		
		<!--- This adds a new option to the post category multi-select --->
        function addNewPostCategory(categoryId,category) {
			<!--- Get the multiselect --->
			var multiSelect = $("#postCategories").data("kendoMultiSelect"); 
			<!--- Get the datasource --->
            var multiSelectDs = $("#postCategories").data("kendoMultiSelect").dataSource;
			
			<!--- 2026-10-10: the new category was never selected. This used to add it, then wait for a "sync" event before
			selecting it - but this list's data source only reads (it has no create transport), so it never synced and the
			selection never ran; MultiSelect also has no select(index) like a DropDownList. Instead: clear the search text
			that is still filtering the list (eg. "Gotcha's"), add the item, and add its id to the picker's selected values. --->
			multiSelect.input.val("");
			multiSelectDs.filter([]);
			multiSelectDs.add({
				CategoryId: categoryId,
				Category: category
			});
			var selectedCategoryIds = multiSelect.value().slice();
			selectedCategoryIds.push(categoryId);
			multiSelect.value(selectedCategoryIds);
			multiSelect.close();
        };
		
		<!--- This adds a new option to the post tags multi-select --->
        function addNewPostTag(tagId,tag) {
			
			<!--- Get the multiselect --->
			var multiSelect = $("#postTags").data("kendoMultiSelect"); 
			<!--- Get the datasource --->
            var multiSelectDs = $("#postTags").data("kendoMultiSelect").dataSource;
		
			<!--- 2026-10-10: same fix as addNewPostCategory above - the old sync-then-select never ran. --->
			multiSelect.input.val("");
			multiSelectDs.filter([]);
			multiSelectDs.add({
				TagId: tagId,
				Tag: tag
			});
			var selectedTagIds = multiSelect.value().slice();
			selectedTagIds.push(tagId);
			multiSelect.value(selectedTagIds);
			multiSelect.close();
        };
		
	</script>
		
	<form id="postDetails" data-role="validator">
	<input type="hidden" name="postId" id="postId" value="<cfoutput>#getPost[1]['PostId']#</cfoutput>" />
	<!--- Pass the current alias --->
	<input type="hidden" name="postAlias" id="postAlias" value="<cfoutput>#getPost[1]['PostAlias']#</cfoutput>" />
	<!--- Pass a form to determine if we can change the title and the link when the title is changed. --->
	<input type="hidden" name="changeTitleAndLink" id="changeTitleAndLink" value="<cfif getPost[1]['Released']>0<cfelse>1</cfif>" />
	<!--- Pass the imageMediaId for new images or videos that have been uploaded --->
	<input type="hidden" name="imageMediaId" id="imageMediaId" value="" />
	<!-- Pass the mediaId for a video -->
	<input type="hidden" name="videoMediaId" id="videoMediaId" value="" />
	<!-- Pass the mapId for a static map -->
	<input type="hidden" name="mapId" id="mapId" value="" />
	<!--- The post theme id allows authors to select a certain theme to be displayed when this post is viewed. --->
	<input type="hidden" name="postThemeId" id="postThemeId" value="<cfoutput>#getPost[1]['ThemeRef']#</cfoutput>" />
	<!--- The post sort date is used to sort the posts on the main blog page. --->
	<input type="hidden" name="newBlogSortDate" id="newBlogSortDate" value="<cfoutput>#getPost[1]['BlogSortDate']#</cfoutput>" />
	<!--- We need to track if the blogSortDate has changed when using the blogSortDate.cfm adminInterface template in order to sync the dates --->
	<input type="hidden" name="blogSortDateChanged" id="blogSortDateChanged" value="<cfoutput>#blogSortDateIsDifferent#</cfoutput>" />
	<!--- Pass the csrfToken --->
	<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
	<!--- We need to store the categories since the postCategories Kendo multiselect widget does not pass them in order --->
	<input type="hidden" name="selectedPostCategories" id="selectedPostCategories" value="<cfoutput>#thisSelectedCategoryIdList#</cfoutput>" />
	<!--- Redirects. These values are only used when the post is being removed and there is a new URL --->
	<input type="hidden" name="redirectUrl" id="redirectUrl" value="<cfoutput>#getPost[1]['RedirectUrl']#</cfoutput>" />
	<!--- We need to store the categories since the postCategories Kendo multiselect widget does not pass them in order --->
	<input type="hidden" name="redirectType" id="redirectType" value="<cfoutput>#getPost[1]['RedirectType']#</cfoutput>" />
	
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0">
	  <cfsilent>
		<!---The first content class in the table should be empty. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
		<!--- Set the colspan property for borders --->
		<cfset thisColSpan = "2">
	  </cfsilent>
	<!--- Delete post interface (only shows up when a post is removed) --->
	<cfif postRemoved>	
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
    <cfif session.isMobile or session.isTablet>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>#postRemovedHtml#</cfoutput>
		</td>
	   </tr>
	<cfelse><!---<cfif session.isMobile or session.isTablet>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<cfoutput>#postRemovedHtml#</cfoutput>
		</td>
	  </tr>
	</cfif><!---<cfif session.isMobile or session.isTablet>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	</cfif>
			
	  <tr height="1px">
		  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif not getPost[1]['IsPage']>
    <cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="datePosted">Date Posted</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input id="datePosted" name="datePosted" value="<cfoutput>#dateTimeFormat(getPost[1]['DatePosted'], "medium")#</cfoutput>" style="width: 58%" />
				<!--- Moved here from the Misc section at the bottom of the form, right next to the date picker where it's more visible, and sized small to fit alongside it on mobile too. --->
				<button id="scheduleRelease" class="k-button normalFontWeight" type="button" style="width: 36%; min-width: 78px;" onClick="createAdminInterfaceWindow(69,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Schedule</button>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"> 
			<label for="datePosted">Date Posted</label>
		</td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Using a table to constrain the time picker after it changes --->
			<table cellpadding="5" cellspacing="0" width="100%">
				<tr>
					<td width="40%">
						<input id="datePosted" name="datePosted" value="<cfoutput>#dateTimeFormat(getPost[1]['DatePosted'], "medium")#</cfoutput>" style="width: 100%" /> 
					</td>
					<td width="60%">
						<!--- Moved here from the Misc section at the bottom of the form, right next to Sort Date where it's more visible. Placed first/ahead of Sort Date since it's expected to be used more often. --->
						<button id="scheduleRelease" class="k-button normalFontWeight" type="button" style="width: 100px" onClick="createAdminInterfaceWindow(69,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Schedule</button>
						<button id="sortDate" class="k-button normalFontWeight" type="button" style="width: 115px; margin-left: 4px;" onClick="createAdminInterfaceWindow(43,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Sort Date</button>
					</td>
				</tr>
			</table>
		</td>
	  </tr>
	</cfif>
	<!--- Pages have no user-facing Date Posted / Schedule Release / Sort Date - those are tied to a publish date, which a Page does not have. --->
	</cfif><!---<cfif not getPost[1]['IsPage']>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<cfif not getPost[1]['IsPage']>
	  <cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="post">Author</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="author" style="width: 95%"></select>
			<!--- Inline template to add a new user. --->
			<script id="addUser" type="text/x-kendo-tmpl">
				<div>
					Author not found. Do you want to add '#: instance.filterInput.val() #'?
				</div>
				<br />
				<button class="k-button" onclick="createAdminInterfaceWindow(7, #= kendo.htmlEncode(JSON.stringify(instance.filterInput.val())) #, 'addUser')">Add Author</button>
			</script> 
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <!-- Form content -->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="post">Author</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="author" style="width: 50%"></select>
			<!--- Inline template to add a new user. --->
			<script id="addUser" type="text/x-kendo-tmpl">
				<div>
					Author not found. Do you want to add '#: instance.filterInput.val() #'?
				</div>
				<br />
				<button class="k-button" onclick="createAdminInterfaceWindow(7, #= kendo.htmlEncode(JSON.stringify(instance.filterInput.val())) #, 'addUser')">Add Author</button>
			</script>  
		</td>
	  </tr>
	</cfif>
	<!--- Pages have no user-facing Author field - the dropdown still exists in the DOM/JS for the underlying save, just hidden here. --->
	</cfif><!---<cfif not getPost[1]['IsPage']>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
  	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="post">Title</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="title" name="title" value="<cfoutput>#getPost[1]['Title']#</cfoutput>" class="k-textbox" style="width: 95%" onChange="javascript:checkTitle();" />
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="post">Title</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="text" id="title" name="title" value="<cfoutput>#getPost[1]['Title']#</cfoutput>" class="k-textbox" style="width: 66%" onChange="javascript:checkTitle();" />
		</td>
	  </tr>
	</cfif>
	<!--- Forms shown below this post's text, chosen under "Show on" in the form editor (2026-10-13), so nobody wonders where they come from. --->
	<cfif structKeyExists(application, "webForms") and isNumeric(URL.optArgs)>
		<cfset postWebFormPlacements = application.webForms.getPlacementsForPost(val(URL.optArgs))>
		<cfif arrayLen(postWebFormPlacements)>
			<cfset postWebFormNotes = []>
			<cfloop array="#postWebFormPlacements#" index="thisPlacement">
				<cfset arrayAppend(postWebFormNotes, encodeForHtml(thisPlacement.title) & " (" & (thisPlacement.showForm and thisPlacement.showList ? "form and sign-up list" : (thisPlacement.showList ? "sign-up list" : "form")) & ")")>
			</cfloop>
		  <tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
				<div class="k-form-hint">Shows below the text: <cfoutput>#arrayToList(postWebFormNotes, ", ")#</cfoutput>. Change this under Forms.</div>
			</td>
		  </tr>
		</cfif>
	</cfif>
		
		<!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
		<!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="postType">Post Type</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="radio" name="postType" value="blogPost" <cfif !getPost[1]['IsPage']>checked</cfif> /> Blog Post <input type="radio" name="postType" value="page" <cfif getPost[1]['IsPage']>checked</cfif>/> Page
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="postType">Post Type</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<input type="radio" name="postType" value="blogPost" <cfif !getPost[1]['IsPage']>checked</cfif> /> Blog Post &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="postType" value="page" <cfif getPost[1]['IsPage']>checked</cfif>/> Page 
		</td>
	  </tr>
	</cfif>  
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">

		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Enclosure thumbnail -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label>Enclosure</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="mediaPreview" name="mediaPreview"><cfoutput>#thumbnailHtml#</cfoutput></div>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	   <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label>Enclosure</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Debugging
			<cfset mapThumbnail = RendererObj.renderMapPreview(11, true)>
			<cfoutput>#mapThumbnail#</cfoutput>
			<img src="<cfoutput>#thumbnailUrl#</cfoutput>">
			--->
			<div id="mediaPreview" name="mediaPreview"><cfoutput>#thumbnailHtml#</cfoutput></div>
		</td>
	  </tr>
	</cfif><!---<cfif smallScreen>--->
	  <!--- Editor button --->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="enclosure" class="k-button normalFontWeight" type="button" style="width: 235px" onClick="createAdminInterfaceWindow(13,<cfoutput>#URL.optArgs#</cfoutput>)">Enclosure Editor</button>
		</td>
	  </tr>
	<cfelse>
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="enclosure" class="k-button normalFontWeight" type="button" style="width: 235px" onClick="createAdminInterfaceWindow(13,<cfoutput>#URL.optArgs#</cfoutput>)">Enclosure Editor</button>
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>  
	<!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<i class="far fa-edit"></i> 
			<label for="post">CSS and Scripts</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="jsonLd" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(46,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">CSS</button>
			<button id="changeAlias" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(47,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JavaScript</button>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<i class="far fa-edit"></i> 
			<label for="post">CSS and Scripts</label>
		</td>
		<td align="center" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inner table --->
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0">
				<tr>
					<td width="25%">
						<button id="changeAlias" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(23,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Alias</button>
					</td>
					<td width="25%">
						<button id="postHeader" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(42,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Post Header</button>
					</td>
					<td width="25%">
						<button id="cssButton" class="k-button normalFontWeight" type="button" style="width: 125px" onClick="createAdminInterfaceWindow(46,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">CSS</button>
					</td>
					<td width="25%">
						<button id="javascriptButton" class="k-button normalFontWeight" type="button" style="width: 125px" onClick="createAdminInterfaceWindow(47,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JavaScript</button>
					</td>
				</tr>
			</table>
		</td>
	  </tr>
	</cfif>
	<!-- Form content -->
	<!-- ****************************************** TinyMce Editor ****************************************** -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<div id="dynamicGalleryInputFields" name="dynamicGalleryInputFields"></div>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="<cfoutput>#selectorName#</cfoutput>">Post</label>   
		</td>
	  </tr>
	  <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr>
		<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>"><div id="dynamicGalleryLabel"></div></td>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"><div id="dynamicGalleryInputFields" name="dynamicGalleryInputFields"></div></td>
	  </tr>
	  <tr valign="middle">
		<td align="right" valign="middle" height="35" class="<cfoutput>#thisContentClass#</cfoutput>">
		<label for="<cfoutput>#selectorName#</cfoutput>">Post</label>
		</td>
		<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>"> 
		<input type="text" id="<cfoutput>#selectorName#</cfoutput>" name="<cfoutput>#selectorName#</cfoutput>" />   
		</td>
	  </tr>
	</cfif>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	<!-- Form content -->
	<cfif smallScreen><!--- i.e. mobile devices --->
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<i class="far fa-edit"></i>
			<label for="post">Misc.</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<button id="jsonLd" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(15,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JSON-LD (SEO)</button>
			<button id="changeAlias" class="k-button normalFontWeight" type="button" style="width: 175px" onClick="createAdminInterfaceWindow(23,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Change Alias</button>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<i class="far fa-edit"></i> 
			<label for="post">Misc.</label>
		</td>
		<td align="center" class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inner table --->
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0">
				<tr>
					<td width="20%" align="left">
						<cfset postUrl = application.blog.makeLink(
							isPage=getPost[1]["IsPage"], 
							postAlias=getPost[1]["PostAlias"], 
							datePosted=getPost[1]["DatePosted"])>
						<button id="postPreview" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="window.open('<cfoutput>#postUrl#</cfoutput>?showPendingPosts');">Preview</button>
					</td>
					<td width="20%" align="left">
						<button id="setTheme" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(44,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">Set Theme</button>
					</td>
					<td width="20%" align="left">
						<button id="jsonLd" class="k-button normalFontWeight" type="button" style="width: 165px" onClick="createAdminInterfaceWindow(15,<cfoutput>#getPost[1]['PostId']#</cfoutput>)">JSON-LD (SEO)</button>
					</td>
					<td width="20%" align="left">
					</td>
					<td width="20%" align="left">
<!--- Schedule Release moved up next to the Date Posted picker, see the Date Posted row near the top of the form. --->
					</td>
				</tr>
			</table>
		</td>
	  </tr>
	</cfif><!---<cfif smallScreen>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr>
	  <cfif not smallScreen>
		<td class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </cfif>
		<td align="center" class="<cfoutput>#thisContentClass#</cfoutput>" <cfif smallScreen>colspan="2"</cfif>>
			<table align="center" class="<cfoutput>#thisContentClass#</cfoutput>" width="100%" cellpadding="5" cellspacing="0" border="0">
				<tr>
					<td width="20%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "Released" )>
								<cfset released = getPost[1]["Released"]>
							<cfelse>
								<cfset released = 0>
							</cfif>
						</cfsilent>
						<input id="released" name="released" type="checkbox" <cfif released>checked</cfif> class="normalFontWeight">
						<label for="released">Released</label>
					</td>
					<td width="20%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "AllowComment" )>
								<cfset allowComment = getPost[1]["AllowComment"]>
							<cfelse>
								<!--- By default, comments are turned off for pages --->
								<cfif getPost[1]['IsPage']>
									<cfset allowComment = false>
								<cfelse>
									<cfset allowComment = true>
								</cfif>
							</cfif>
						</cfsilent>
						<input id="allowComment" name="allowComment" type="checkbox" <cfif allowComment>checked</cfif> class="normalFontWeight">
						<label for="allowComment">Allow Comments</label>
					</td>
				<cfif not getPost[1]['IsPage']>
					<!--- RSS/Promote only apply to a blog post, not a Page. RSS is placed before Promote per feedback. --->
					<td width="20%" align="left" <cfif smallScreen>style="display:none;"</cfif>>
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "DisplayOnRss")>
								<cfset displayOnRss = getPost[1]["DisplayOnRss"]>
							<cfelse>
								<cfset displayOnRss = true>
							</cfif>
						</cfsilent>
						<!--- Hidden (not removed) on mobile, per feedback - no room there, but the checkbox still needs
						to exist in the DOM so its current value keeps submitting unchanged; removing it outright would
						make $('#displayOnRss').is(':checked') always read false and silently turn RSS off on every
						save made from a phone. --->
						<input id="displayOnRss" name="displayOnRss" type="checkbox" <cfif displayOnRss>checked</cfif> class="normalFontWeight">
						<label for="displayOnRss">Include in RSS Feed</label>
					</td>
					<td width="20%" align="left">
						<cfsilent>
						<!--- This field may not be defined (it may be null in the database) --->
						<cfif structKeyExists(getPost[1], "Promoted" )>
							<cfset promote = getPost[1]["Promoted"]>
						<cfelse>
							<cfset promote = 0>
						</cfif>
						</cfsilent>
						<input id="promote" name="promote" type="checkbox" <cfif promote>checked</cfif> class="normalFontWeight">
						<label for="promote">Promote</label>
					</td>
				</cfif><!---<cfif not getPost[1]['IsPage']>--->
					<td width="20%" align="left">
						<cfsilent>
							<!--- This field may not be defined (it may be null in the database) --->
							<cfif structKeyExists(getPost[1], "Remove")>
								<cfset remove = getPost[1]["Remove"]>
							<cfelse>
								<cfset remove = 0>
							</cfif>
						</cfsilent>
						<!--- Use the onclick event to confirm the removal if the post has not already been removed --->
						<input id="remove" name="remove" type="checkbox" <cfif remove>checked</cfif> class="normalFontWeight" <cfif !postRemoved>onClick="confirmPostRemoval()"</cfif>>
						<label for="remove">Remove</label>
					</td>
					<!--- Put 2 empty cells for pages, since they skip both the RSS and Promote cells above. --->
				<cfif getPost[1]['IsPage']>
					<td width="20%" align="left"></td>
					<td width="20%" align="left"></td>
				</cfif>
				</tr>
			</table>
		</td>
	  </tr>			
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="description">Description</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width:95%"><cfoutput>#getPost[1]['Description']#</cfoutput></textarea>   
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="description">Description</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<textarea id="description" name="description" maxlength="1250" class="k-textbox" style="width: 66%"><cfoutput>#getPost[1]['Description']#</cfoutput></textarea> 
		</td>
	  </tr>
	</cfif>
	<!--- Border + Categories together (Post only) - a Page uses Page Collections exclusively, not both, to avoid reintroducing the tangled category-based membership the redesign replaced. --->
	<cfif not getPost[1]['IsPage']>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postCategories">Categories</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- Inline template to add a new category. --->
			<select id="postCategories" style="width: 95%"></select>
			<!--- Inline template to add a new category. Note: the noData templates are different depending upon the widget.--->
			<script id="addCategoryNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Category not found. Do you want to add new category - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(12,#= kendo.htmlEncode(JSON.stringify(value)) #)" ontouchend="createAdminInterfaceWindow(12,#= kendo.htmlEncode(JSON.stringify(value)) #)">Add new item</button>
			</script>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="postCategories">Categories</label>
		</td>
		<td align="left" width="90% class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inline template to add a new category. --->
			<select id="postCategories" style="width: 95%"></select>
			<!--- Inline template to add a new category. Note: the noData templates are different depending upon the widget.--->
			<script id="addCategoryNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Category not found. Do you want to add new category - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(12,#= kendo.htmlEncode(JSON.stringify(value)) #)" ontouchend="createAdminInterfaceWindow(12,#= kendo.htmlEncode(JSON.stringify(value)) #)">Add new item</button>
			</script>
		</td>
	  </tr>
	</cfif>
	</cfif><!---<cfif not getPost[1]['IsPage']> (Categories) ---->
	<!--- Border + Tags together, so a Page (which has no tags) doesn't get an orphaned empty divider here. --->
	<cfif not getPost[1]['IsPage']>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>

	 <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postTags">Tags</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<!--- Inline template to add a new tag. --->
			<select id="postTags" style="width: 95%"></select>
			<!--- Inline template to add a new tag. Note: the noData templates are different depending upon the widget.--->
			<script id="addTagNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Tag not found. Do you want to add new tag - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(49,#= kendo.htmlEncode(JSON.stringify(value)) #)" ontouchend="createAdminInterfaceWindow(49,#= kendo.htmlEncode(JSON.stringify(value)) #)">Add new item</button>
			</script>    
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="postTags">Tags</label>
		</td>
		<td align="left" width="90% class="<cfoutput>#thisContentClass#</cfoutput>">
			<!--- Inline template to add a new tag. --->
			<select id="postTags" style="width: 95%"></select>
			<!--- Inline template to add a new tag. Note: the noData templates are different depending upon the widget.--->
			<script id="addTagNoData" type="text/x-kendo-tmpl">
				# var value = instance.input.val(); #
				# var id = instance.element[0].id; #
				<div>
					Tag not found. Do you want to add new tag - '#: value #' ?
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(49,#= kendo.htmlEncode(JSON.stringify(value)) #)" ontouchend="createAdminInterfaceWindow(49,#= kendo.htmlEncode(JSON.stringify(value)) #)">Add new item</button>
			</script> 
		</td>
	  </tr>
	</cfif>
	<!--- Pages have no tags. --->
	</cfif><!---<cfif not getPost[1]['IsPage']>--->
	<!--- Border + Related Posts together, so a Page (which has no related-posts concept) doesn't get an orphaned empty divider here. --->
	<cfif not getPost[1]['IsPage']>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>

	  <!-- Form content -->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="relatedPosts">Related Posts</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="relatedPosts" style="width: 95%; font-weight: 300;"></select> 
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="relatedPosts">Related Posts</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="relatedPosts" style="width: 100%; font-weight: 300;"></select> 
		</td>
	  </tr>	
	</cfif>
	<!--- Pages have no related-posts concept. --->
	</cfif><!---<cfif not getPost[1]['IsPage']>--->
	<!--- Border + Page Collections together (Pages only), same reasoning as the two blocks above - a Post gets neither the border nor the (empty) content here. --->
	<cfif getPost[1]['IsPage']>
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!--- Which Page Collection(s) this Page belongs to - a Page's counterpart to a Post's Categories, the only place this membership is set (never curated from inside the Collection itself). Same noData "not found, add it?" pattern as Category/Tag - here it fires whenever none exist yet at all, not just when a search finds nothing. --->
	<cfif smallScreen>
	  <tr valign="middle">
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<label for="postPageCollections">Page Collections</label>
		</td>
	   </tr>
	   <tr>
		<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
			<select id="postPageCollections" multiple="multiple" style="width: 95%">
				<cfloop array="#getAllPageCollectionsForDropdown#" index="pcOption">
					<option value="<cfoutput>#pcOption.pageCollectionId#</cfoutput>"><cfoutput>#pcOption.title#</cfoutput></option>
				</cfloop>
			</select>
			<script id="addPageCollectionNoData" type="text/x-kendo-tmpl">
				<div>
					No page collections exist yet.
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(24,'newPageCollection')" ontouchend="createAdminInterfaceWindow(24,'newPageCollection')">Create one</button>
			</script>
		</td>
	  </tr>
	<cfelse><!---<cfif smallScreen>--->
	  <tr valign="middle" height="35">
		<td align="right" valign="middle" width="10%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<label for="postPageCollections">Page Collections</label>
		</td>
		<td align="left" width="90%" class="<cfoutput>#thisContentClass#</cfoutput>">
			<select id="postPageCollections" multiple="multiple" style="width: 95%">
				<cfloop array="#getAllPageCollectionsForDropdown#" index="pcOption">
					<option value="<cfoutput>#pcOption.pageCollectionId#</cfoutput>"><cfoutput>#pcOption.title#</cfoutput></option>
				</cfloop>
			</select>
			<script id="addPageCollectionNoData" type="text/x-kendo-tmpl">
				<div>
					No page collections exist yet.
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(24,'newPageCollection')" ontouchend="createAdminInterfaceWindow(24,'newPageCollection')">Create one</button>
			</script>
		</td>
	  </tr>
	</cfif>
	</cfif><!---<cfif getPost[1]['IsPage']>--->
	  <!-- Border -->
	  <tr height="2px">
		  <td align="left" valign="top" colspan="<cfoutput>#thisColSpan#</cfoutput>" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <cfsilent>
	  <!--- Set the class for alternating rows. --->
	  <!---After the first row, the content class should be the current class. --->
	  <cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)>
	  </cfsilent>
	  <tr height="2px">
		  <td align="left" valign="top" colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
	  </tr>
	  <!-- Form content -->
	  <tr valign="middle">
		<td height="25" valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>">&nbsp;</td>
		<td height="25" valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
			<button id="postDetailSubmit" name="postDetailSubmit" class="k-button k-primary" type="button">Submit</button>
		</td>
	  </tr>
	</table>
	</form>
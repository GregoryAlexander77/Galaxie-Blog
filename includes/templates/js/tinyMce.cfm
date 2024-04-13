	<!---<cfoutput>selectorId: #selectorId#</cfoutput>--->
	<cfsilent>	
	<!--- 
	Important note: the selector name must be completely unique. Furthermore, the selector name must be unique and contain a unique value even if the page is reloaded, or a window widget was reloaded. If the selector name is not unique we have two major issues that cause this entire editor to be useless. Read below.
	We can load the tiny mce scripts in two places- in the index.cfm header 1), or whithin the window logic here 2).

	1) If we place the script in the header, we will be able to use the insertContent and setContent methods, but once the Kendo window closes or is refreshed, we will not be able to open up the editor again. This is due to how tincymce prepares the dom and how the Kendo window operates. Without a unique name, the editor will work once, but if opened again, it will dissapear. 

	2) If we put the tinymce scripts in this window, the editor's will not disappear, however, the editors will not be in memory and we can't use any get or set methods to insert new content. The only way that I found around this is to use a getTick (or other random generator) to make the selector name unique every single time that it is called. This is a necessary hack as tincyMce does not hanlle single page applications all that well. 

	With that out of the way, this is how the template should be used:
	<cfset mediaProcessType = "enclosure">// either enclosure (which can be an image or video), gallery, post, or comment.
	<cfset selectorName = "post" & second(now())>
	<cfset eidtorHeight = "300">
	<cfset imageHandlerUrl = "../../common/cfc/proxyController.cfc?method=uploadImage&mediaProcessType=enclosure&postId=" & getPost[1]["PostId"]>
	<cfset contentVar = getPost[1]["Body"]>
	<cfset imageMediaIdField = "imageMediaId">
	<cfset imageClass = "entryImage">
	<cfset pluginList = "advlist autolink lists link image charmap print preview anchor',
		'searchreplace visualblocks code codesample fullscreen',
		'insertdatetime media table paste imagetools wordcount iconfonts">

	<cfif session.isMobile>
		<cfset toolbarString = "undo redo | bold italic | link | image media fancyBoxGallery">
	<cfelse>
		<cfset toolbarString = "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image media | fancyBoxGallery">
	</cfif>
	<cfset includeGallery = true>

	Custom menu example:
	tinymce.init({
		selector: 'textarea',  // change this value according to your HTML
		menu: {
			file: {title: 'File', items: 'newdocument'},
			edit: {title: 'Edit', items: 'undo redo | cut copy paste pastetext | selectall'},
			insert: {title: 'Insert', items: 'link media | template hr'},
			view: {title: 'View', items: 'visualaid'},
			format: {title: 'Format', items: 'bold italic underline strikethrough superscript subscript | formats | removeformat'},
			table: {title: 'Table', items: 'inserttable tableprops deletetable | cell row column'},
			tools: {title: 'Tools', items: 'spellchecker code'}
		}
	});

	tinymce.init({
		selector: 'textarea',  // change this value according to your HTML
		menubar: 'file edit insert view format table tools help'
	});

	To loop through the editors use:
	$(document).ready(function(){
		for (i=0; i < tinyMCE.editors.length; i++){
			var content = tinyMCE.editors[i].getContent();
			alert('Editor-Id(' + tinyMCE.editors[i].id + '):' + content);
		}

		setTimeout(function() {
			// Close the wait window that was launched in the calling function.
			tinymce.activeEditor.setContent("<p>test foo gore poo</p>");
			//tinymce.get("postEnclosure15").setContent("<p>9898 foo gore poo</p>");
		}, 5000);

	});	

	To set the content, you can also use: tinymce.get("postEnclosure15").setContent("test");
 	--->
		
	<!--- Get all of the fonts that are used for this theme and include all of the web safe fonts --->
	<cfinvoke component="#application.blog#" method="getThemeFonts" returnvariable="getThemeAndWebSafeFonts">
		<cfinvokeargument name="themeId" value="#themeId#">
		<cfinvokeargument name="selfHosted" value="1">
		<cfinvokeargument name="includeWebSafeFonts" value="1">
	</cfinvoke>
			
	<!--- Just get the self hosted fonts. --->
	<cfinvoke component="#application.blog#" method="getThemeFonts" returnvariable="getSelfHostedFonts">
		<cfinvokeargument name="themeId" value="#themeId#">
		<cfinvokeargument name="selfHosted" value="1">
		<cfinvokeargument name="includeWebSafeFonts" value="0">
	</cfinvoke>
		
	<!--- Preset vars that are not always used --->
	<cfparam name="includeGallery" default="false">
	<cfparam name="includeCarousel" default="false">
	<cfparam name="includeCustomWindow" default="false">
	<cfparam name="includeVideoUpload" default="false">
	<cfparam name="includeFileUpload" default="false">
	<cfparam name="disableWebVttAndVideoCoverButtons" default="true">
	<cfparam name="includeMaps" default="true">
	<!--- Note: don't use the autosave plugin. its buggy! --->
	<cfparam name="pluginList" default="'advlist autolink lists hr link image charmap print preview anchor',
		'searchreplace visualblocks code codesample fullscreen',
		'insertdatetime media table paste imagetools wordcount iconfonts textpattern toc emoticons nonbreaking'">
	</cfsilent>

	<cfif  application.serverSupportsWoff2>
		<cfset fontExtension = "woff2">
	<cfelse>
		<cfset fontExtension = "woff">
	</cfif>
		
	<!--- Code to keep track of the unique selector names. We are going to use cookies to keep track of the current selector names and remove the editors that are no longer being used. The selectorId is what we are going to use to get to the unqique selectorName (ie cookie.postEditor will provide the unique selector name). --->
	<!--- Create our unique selector name. This should be something like 'post' & 12 & 30> --->
	<cfset selectorName = selectorId & minute(now()) & second(now())>
	
	<!--- If the cookie name exists, the cookie name is equal to the Remove any unused editors from our editor array in memory --->
	<cfif isDefined("cookie.#selectorId#") and evaluate("cookie.#selectorId#") neq selectorName>
		<!--- Include the get-video-id script. This will be used to determine the video provider and the video id --->
		<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/get-video-id/getVideoId.min.js"></script>
		<!--- Remove the unused editor --->
		<script>
			<cfoutput>
			tinymce.EditorManager.execCommand('mceRemoveControl', true, '#evaluate("cookie.#selectorId#")#');
			try {
				// In order to make sure that *all* references are removed, use the destroy command. We are putting this in a try block in case the editor is removed. Notes: while testing the efficacy of the mceRemoveControl (above), I noticed that the editor is still referenced using the displayEditorNames() function. It is my educated guess that get method below determines that the editor is no longer active and automatically removes it rather than the destroy statement. That said, if I don't  use this line the editor is still in memory and this line will remove it.
				tinymce.get("#evaluate("cookie.#selectorId#")#").destroy();
			} catch {
				// Do nothing
			}
			</cfoutput>
		</script>
	</cfif>
	<!--- Finally, save the current unique selectorName in a cookie --->
	<cfcookie name="#selectorId#" value="#selectorName#">
		
	<style>
		.fontAwesomeIcon {
			font-family: FontAwesome !important; 
			font-weight: 900 !important; 
			font-size: 19px !important;
		}		
	</style>

	<script type="text/javascript">
		
		//function initEditor(){

			// Initiate the tinymce editor.
			tinymce.init({
				schema: 'html5',
				selector: '#<cfoutput>#selectorName#</cfoutput>',
				<cfif session.isMobile>// On mobile devices, subtract 25 pixels (for padding) from the content container pixel width 
				width: (getContentPixelWidth()-25),</cfif>
				// Skin
				skin: "<cfoutput>#kendoTheme#</cfoutput>",//This points to the folder in the ui directory
				// Point to a common content.css. This does not impact the dynamic nature of the skin.
				content_css: "<cfoutput>#application.baseUrl#</cfoutput>/includes/templates/blogContentCss.cfm?standalone=true,<cfoutput>#application.baseUrl#</cfoutput>/common/libs/tinymce/skins/ui/oxide/content.css",
				height: "<cfoutput>#editorHeight#</cfoutput>",
				// This only works with tinymce 5.6+
				images_file_types: 'peg,jpg,jpe,jfi,jif,jfif,png,gif,bmp,webp',
				// Custom plugin argument to allow us to use fontawesome icons
				iconfonts_selector: '.fa, .fab, .fal, .far, .fas, .glyphicon', // optional (default shown)
			<!--- Set the menu depending upon the selector name. --->
			<cfswitch expression="#selectorId#">
				<cfcase value="enclosureEditor">
				menubar: 'file edit insert view',
				menu: {
					file: {title: 'File', items: 'preview print'},
					edit: {title: 'Edit', items: 'undo redo | cut copy paste | selectall'},
					insert: {title: 'Insert', items: 'image | media | carousel | videoUpload webVttUpload videoCoverUpload | map mapRouting'},
					view: {title: 'View', items: 'code | visualaid | preview fullscreen'}
				},
				</cfcase>
				<cfcase value="webVttEditor">
				menubar: 'file edit insert view',
				menu: {
					file: {title: 'File', items: 'preview print'},
					edit: {title: 'Edit', items: 'undo redo | cut copy paste | selectall'},
					insert: {title: 'Insert', items: 'fileUpload'},
					view: {title: 'View', items: 'code | visualaid | preview fullscreen'}
				},
				</cfcase>
				<cfcase value="videoCoverEditor">
				menubar: 'file edit insert view',
				menu: {
					file: {title: 'File', items: 'preview print'},
					edit: {title: 'Edit', items: 'undo redo | cut copy paste | selectall'},
					insert: {title: 'Insert', items: 'image'},
					view: {title: 'View', items: 'code | visualaid | preview fullscreen'}
				},
				</cfcase>
				<cfcase value="imageUploadEditor">
				menubar: 'file edit insert view',
				menu: {
					file: {title: 'File', items: 'preview print'},
					edit: {title: 'Edit', items: 'undo redo | cut copy paste | selectall'},
					insert: {title: 'Insert', items: 'image'},
					view: {title: 'View', items: 'code | visualaid | preview fullscreen'}
				},
				</cfcase>
				<cfdefaultcase>
				menubar: 'file edit insert view format table ',
				menu: {
					file: { title: 'File', items: 'newdocument restoredraft | preview | print ' },
					edit: { title: 'Edit', items: 'undo redo | cut copy paste | selectall | searchreplace' },
					view: { title: 'View', items: 'code | visualaid visualchars visualblocks | spellchecker | preview fullscreen' },
					insert: { title: 'Insert', items: 'image link media | fancyBoxGallery carousel | customWindow | map mapRouting | template codesample inserttable | charmap emoticons hr | pagebreak nonbreaking anchor toc | insertdatetime' },
					format: { title: 'Format', items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align lineheight | forecolor backcolor | removeformat' },
					table: { title: 'Table', items: 'inserttable | cell row column | tableprops deletetable' }
				},
				</cfdefaultcase>
			</cfswitch>
				toolbar_sticky: true, // Makes the toolbar float at the top of the page
				toolbar_sticky: "80px",// This fixes when the toolbar disappears with the toolbar_sticky
				plugins: [<cfoutput>#pluginList#</cfoutput>],
				// Change the toc_depth to support h4 tags (the default is h1-3)
				toc_depth: 5,
				// Allow the Prism folder to be the prism engine instead of the embedded version of Prism within TinyMce. This is required to have line numbers
				codesample_global_prismjs: true,
				// Set the prism languages
				codesample_languages: [
					{ text: 'HTML/XML', value: 'markup' },
					{ text: 'JavaScript', value: 'javascript' },
					{ text: 'CSS', value: 'css' },
					{ text: 'C#', value: 'csharp' },
					{ text: 'CFScript', value: 'cfscript' },
					{ text: 'Java', value: 'java' },
					{ text: 'JSON', value: 'json' },
					{ text: 'JSONP', value: 'jsonp' }, 
					{ text: 'PHP', value: 'php' },
					{ text: 'Python', value: 'python' },
					{ text: 'Ruby', value: 'ruby' },
					{ text: 'SQL', value: 'sql' }
				],
				toolbar: '<cfoutput>#toolbarString#</cfoutput>',
				media_live_embeds: true,
				// Load our custom fonts
				font_formats: "<cfloop from="1" to="#arrayLen(getThemeAndWebSafeFonts)#" index="i"><cfoutput>#getThemeAndWebSafeFonts[i]['Font']#=<cfif len(getThemeAndWebSafeFonts[i]['WebSafeFallback'])>#lCase(getThemeAndWebSafeFonts[i]['WebSafeFallback'])#<cfelse>#lCase(getThemeAndWebSafeFonts[i]['Font'])#</cfif>;</cfoutput></cfloop>",
				// Declare the font faces and set the font properties for the editor body
				content_style: '<cfoutput><cfloop from="1" to="#arrayLen(getSelfHostedFonts)#" index="i">@font-face {font-family: "#getSelfHostedFonts[i]['Font']#"; src: url("#application.baseUrl#/common/fonts/#getSelfHostedFonts[i]['FileName']#.#fontExtension#") format("#fontExtension#");}</cfloop> body { font-family:#themeBodyFont#; font-size:14px; }',</cfoutput>
				// allow scripts: tinymce_allow_script_urls=true
				// all: valid_elements : '+*[*],+body[style]'
				// Alow a list item in order to incorporate font awesome icons, we also put onClick events on buttons.
				extended_valid_elements: 'i[*],a[href|class|id|onClick],button[*],span[*],script[src|async|defer|type|charset],input[*],more',
				// Allows all elements
				// valid_elements : '*[*]',
				// Allow custom more tags
				custom_elements: 'more',
				//autosave_interval: "240s",
				// Set the content and add certain events
				setup: function (editor) {
					// Load the intial content
					editor.on('init', function (e) {
						// Note: this string is a template literal (ie using ``) in order to deal with both single and double qoutes without breaking the editor
						editor.setContent(`<cfoutput>#contentVar#</cfoutput>`);
					});
						  
				<cfif selectorId eq 'enclosureEditor' or selectorId eq 'videoCoverEditor' or selectorId eq 'imageUploadEditor'>
					// Listen to events to determine if a new image or video has been added
					editor.on('NodeChange', function (e) {
						// The NodeChange may have several thousands of events if your not careful and try to inspect it. I have also tried the following events but have not made them work.
						// editor.on('Change', function (e) {
						// editor.on('SetContent', function(e) { 
						// save_callback : "myCustomSaveContent"
					
						// Here, we are looking to see when an image has been added to the editor and save the URL into a hidden form in order to save the url to the database. 
						if (e.element.tagName === "IMG" && e.element.currentSrc != e.element.src) { 
							// console.log('e.element.currentSrc:' + e.element.currentSrc + ' e.element.src:' + e.element.src);
							// alert('newImage')
							/* 	Original logic to find external links. 
								if (e.element.tagName === "IMG" && e.element.currentSrc != e.element.src && e.element.src.indexOf(window.location.host) == -1) { 
							*/
						<!--- This logic only applies when using the enclosure editor --->
						<cfif selectorId eq 'enclosureEditor'>
							// Clear the previous content
							clearPreviousEditorContent();
						</cfif>
						  
						  	/* Define the boolean urlSentToServer var if it not defined. Since null === undefined is false, this statement will catch only null or undefined. If the var is defined, set it to the element.src. This is needed as this logical branch will be raised twice with tinymce and we only want to call the saveExternalUrl one time. */
						  	if (typeof urlSentToServer === 'undefined') {
						  		urlSentToServer = "";
							} else {
								urlSentToServer = e.element.src;
						  	}
							// alert('e.element.src: ' + e.element.src + ' urlSentToServer: ' + urlSentToServer);
						  
						  	// Send the data to the server to update the database. Also, don't invoke the saveExternalUrl if the image was just uploaded. Only do this once per URL. The last argument is used for debugging purposes
						  	if ( (e.element.src != urlSentToServer) ){
						
								// Custom save external URL function is on the various interfaces that use this code
								saveExternalUrl(e.element.src, 'image', '<cfoutput>#selectorId#</cfoutput>', '')
								// Clear any previous url's
								$("#externalImageUrl").val('');
								// Insert the new url into the externalImageUrl hidden form
								$("#externalImageUrl").val(e.element.src);
								// Set a var to indicate that this has been processed.
								urlSentToServer = e.element.src;
						  	}
						}
						  
						/* The onChange event can be used instead of the onNodeChage as well:
							editor.on('change', function (e) {
							console.log('change event fired');
							console.log(e);
						*/
					});//..editor.on('NodeChange', function (e) {
				</cfif>
				
					function clearPreviousEditorContent(){
						//alert('clearing content');
						
						// There can be only one image or video (an iframe) in an enclosure. Before doing this, we first need to get the current contents of the editor to determine if there are more than 1 images or videos. */
						// Get the current editor html content
						currentEditorContent = tinymce.activeEditor.getContent();
					
						// Find and remove any previous images or videos from YouTube or Vimeo. 
						if (($(currentEditorContent).find("img").length > 1) || ($(currentEditorContent).find("img","iframe").length > 1)){
						  	// alert($(currentEditorContent).find("img","iframe").length)
							
							// Remove the content
							tinymce.activeEditor.setContent('');
					
							// For the external image or video preview, let tinymce resolve the URL natively (this is a tinymce function). When we display the video from the database plyr will take over.
          					tinymce.resolve({ html: '' });
						
						}
						// Code to get current selected item
   						// console.log(editor.selection.getNode())
					}

				<cfif includeGallery>
					// Custom dialogs that are invoked via the toolbar
					
					// FancyBox Gallery. This opens up an uppy dialog. Note: this also needs to be added to the toolBarString			
					editor.ui.registry.addButton('fancyBoxGallery', {
						icon: "gallery",
						tooltip: 'Image Gallery',
						onAction: function (_) {
							$('#image').val('');
							// console.log('gallery' + tinymce.activeEditor.selection.getNode());
							// Open up a new gallery window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(3,<cfoutput>#URL.optArgs#</cfoutput>,'gallery');
						}
					});
				
					editor.ui.registry.addMenuItem('fancyBoxGallery', {
						icon: 'gallery',
						text: 'Image Gallery',
						onAction: function () {
							createAdminInterfaceWindow(3,<cfoutput>#URL.optArgs#</cfoutput>,'gallery');
						}
					});
				</cfif>
				<cfif includeCarousel or 1 eq 1>
					// Custom dialogs that are invoked via the toolbar
					// Carousel. This opens up the same uppy dialog as the gallery. Note: this also needs to be added to the toolBarString	
					
					// Create the icon
					editor.ui.registry.addIcon(
						'carousel',
						'<svg><span data-fa-symbol="carousel" class="fontAwesomeIcon fa-solid fa-panorama">&nbsp;</span></svg>'
					);
				
					// Create the button (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('carousel', {
						text: '<i class="fontAwesomeIcon fa-solid fa-panorama"></i>',
						tooltip: 'Carousel',
						onAction: function (_) {
							$('#image').val('');
							// Open up the uppy upload window.
							createAdminInterfaceWindow(3,<cfoutput>#URL.optArgs#</cfoutput>,'carousel');
						}
					});
				
					editor.ui.registry.addMenuItem('carousel', {
						icon: 'carousel',
						text: 'Carousel',
						onAction: function () {
							createAdminInterfaceWindow(3,<cfoutput>#URL.optArgs#</cfoutput>,'carousel');
						}
					});
				</cfif>
				<cfif includeCustomWindow>
					// Create the icon
					editor.ui.registry.addIcon(
						'customWindow', 
						'<svg><span data-fa-symbol="customWindow" class="fontAwesomeIcon fa-regular fa-up-right-from-square">&nbsp;</span></svg>'
					);
				
					// Custom dialogs that are invoked via the toolbar
					// Custom window. This opens up a dialog to create a popup window (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('customWindow', {
						text: '<i class="fontAwesomeIcon fa-regular fa-up-right-from-square"></i>',
						tooltip: 'Create Custom Window',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new video upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(45, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
				
					editor.ui.registry.addMenuItem('customWindow', {
						text: 'Create Custom Window',
						icon: 'customWindow',
						onAction: function () {
							createAdminInterfaceWindow(45, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
				</cfif>				
				<cfif includeVideoUpload>
					// Create the icon
					editor.ui.registry.addIcon(
						'videoUpload', 
						'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-file-video">&nbsp;</span></svg>'
					);
				
					// Custom dialogs that are invoked via the toolbar
					// Video upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('videoUpload', {
						text: '<i class="fontAwesomeIcon fas fa-file-video"></i>',
						tooltip: 'Upload Video',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new video upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(14, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
				
					editor.ui.registry.addMenuItem('videoUpload', {
						text: 'Upload Video',
						icon: 'videoUpload',
						onAction: function () {
							createAdminInterfaceWindow(14, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
				
					// Create the icon
					editor.ui.registry.addIcon(
						'webVttUpload', 
						'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-closed-captioning">&nbsp;</span></svg>'
					);
						  
					// WebVTT file upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('webVttUpload', {
						text: '<i class="fontAwesomeIcon fas fa-closed-captioning"></i>',
						tooltip: 'Upload WebVTT file for video captioning',
						id: 'webVttUpload',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new video upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(16, <cfoutput>#URL.optArgs#</cfoutput>);
						}
					});
							
					editor.ui.registry.addMenuItem('webVttUpload', {
						icon: 'webVttUpload',
						text: 'Upload WebVTT file for video captioning',
						onAction: function () {
							createAdminInterfaceWindow(16, <cfoutput>#URL.optArgs#</cfoutput>);
						}
					});
							
					// Create the icon
					editor.ui.registry.addIcon(
						'videoCoverUpload', 
						'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-file-image">&nbsp;</span></svg>'
					);
						  
					// WebVTT file upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('videoCoverUpload', {
						text: '<i class="fontAwesomeIcon fas fa-file-image"></i>',
						tooltip: 'Upload video image cover',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new image upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(18,<cfoutput>#URL.optArgs#</cfoutput>);
						}
					});
							
					editor.ui.registry.addMenuItem('videoCoverUpload', {
						icon: 'videoCoverUpload',
						text: 'Upload video image cover',
						onAction: function () {
							createAdminInterfaceWindow(18,<cfoutput>#URL.optArgs#</cfoutput>);
						}
					});
				</cfif>
				<cfif includeFileUpload>
					// Custom dialogs that are invoked via the toolbar
					// File upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('fileUpload', {
						icon: "upload",
						tooltip: 'Upload File',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new file upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(17, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
							
					editor.ui.registry.addMenuItem('fileUpload', {
						text: 'Upload File',
						onAction: function () {
							createAdminInterfaceWindow(17, '<cfoutput>#URL.optArgs#</cfoutput>');
						}
					});
				</cfif>
				<cfif includeMaps>
					// Map	
					// Create the icon
					editor.ui.registry.addIcon(
						'map',
						'<svg><span data-fa-symbol="map" class="fontAwesomeIcon fas fa-globe">&nbsp;</span></svg>'
					);
							
					// Create the button (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('map', {
						text: '<i class="fontAwesomeIcon fas fa-globe"></i>',
						tooltip: 'Create a map',
						onAction: function (_) {
							$('#image').val('');
							// See if a current map is selected. If it is, pass along the mapid in order to edit a current map
							var selectedContent = tinymce.activeEditor.selection.getNode();
							// Get the map id. Note: tinymce appends 'mce-p-' to the data-map-id.
							mapId = $(selectedContent).attr("data-mce-p-data-id");
							// Open up a new image upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(19,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>,mapId);
						}
					});
						
					// Add the menu item
					editor.ui.registry.addMenuItem('map', {
						icon: 'map',
						text: 'Map',
						onAction: function () {
							// See if a current map is selected. If it is, pass along the mapid in order to edit a current map
							var selectedContent = tinymce.activeEditor.selection.getNode();
							// Get the map id. Note: tinymce appends 'mce-p-' to the data-map-id.
							mapId = $(selectedContent).attr("data-mce-p-data-id");
							// Open up a new image upload window. The code for this window is the next switch block below.
							createAdminInterfaceWindow(19,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>,mapId);
						}
					});
							
					// Map routing	
					// Create the icon
					editor.ui.registry.addIcon(
						'mapRouting',
						'<svg><span data-fa-symbol="mapRouting" class="fontAwesomeIcon fas fa-location-arrow">&nbsp;</span></svg>'
					);
							
					// Create the button (note: this also needs to be added to the toolBarString)
					editor.ui.registry.addButton('mapRouting', {
						text: '<i class="fontAwesomeIcon fas fa-location-arrow"></i>',
						tooltip: 'Map Directions between 2 or more points',
						onAction: function (_) {
							$('#image').val('');
							// Open up a new map window. The code for this window is the next switch block below.
							// Note: we are also sending the selectorId to determine what interface we are on
							createAdminInterfaceWindow(20,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>);
						}
					});
							
					// Add the menu item
					editor.ui.registry.addMenuItem('mapRouting', {
						icon: 'mapRouting',
						text: 'Map Directions',
						onAction: function () {
							// Note: we are also sending the selectorId to determine what interface we are on
							createAdminInterfaceWindow(20,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>);
						}
					});
				</cfif>

					try {
						// Set an data-mediaId attribute. We will insert the value when the image was succesfully uploaded and the mediaId was returned from the server. We saved the mediaId into the imageId hidden input field when the server returned data. Here, we are taking that value and inserting the mediaId.
						e.element.setAttribute("data-mediaid", $("#<cfoutput>#imageMediaIdField#</cfoutput>").val()); 
						// Wrap the image with the class that we want
						if (!$('.<cfoutput>#imageClass#</cfoutput>').length){
							$(e.element).wrap("<div class='<cfoutput>#imageClass#</cfoutput>'></div>");
						}
						// Important note: in order to be able to do other intented actions, such as editting an image, we must put a return here.
						return true;
					} catch {
						return true;
					}	
				},
				// Force tinymce to use the image path that I return it insted of changing the image url
				relative_urls: false,
				remove_script_host: false,
				convert_urls: true,
				// What is the URL on the server side that will save this image? This URL will return a json string indicating the full path of the image.
				/* images_upload_url does not set a header on mobile devices. This causes an 'tinymce image upload failed due to a xhr transport error. Code 0' error when using an iPhone. When using mobile, we need to use a custom function that is used with the images_upload_handler argument instead. */ 
				//images_upload_url: 'https://gregorysblog.org/common/cfc/proxyController.cfc?method=uploadImage',
				images_upload_handler: imageUploadHandler,
				// Custom function that is called when we embed videos using the media plugin. We need to use this for enclosures in order to save the URL to the database.
				media_url_resolver: function (data, resolve/*, reject*/) { 
					// Do not try to inspect the events here, there are thousands of them and you're going to crash the browser.
					
					// Upload post related media
					jQuery.ajax({
						type: 'post', 
						url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/proxyController.cfc?method=saveExternalMediaEnclosure&template=tinyMce',
						data: { // arguments
							csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
							// Pass the mediaId saved in the mediaId hidden form if it is available
							mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
							externalUrl: data.url,
							postId: <cfoutput>#URL.optArgs#</cfoutput>,
							mediaType: 'video',
							// Get the videoid and provider using the get-video-id javascript library. This script should be included on the UI that calls this template
							providerVideoId: getVideoId(data.url).id,
							videoProvider: getVideoId(data.url).service,
							selectorId: '<cfoutput>#selectorId#</cfoutput>'
						},
						dataType: "json",
						//success: saveWebVttResponse, // calls the result function.
						error: function(ErrorMsg) {
							console.log('Error' + ErrorMsg);
						}
					// Extract any errors. This is a new jQuery promise based function as of jQuery 1.8.
					}).fail(function (jqXHR, textStatus, error) {

						// The full response is: jqXHR.responseText, but we just want to extract the error.
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning. You can also specify height.
							).done(function () {
							// Do nothing
						});		
					});
				<cfif selectorId eq 'enclosureEditor'>	
					// Refresh the enclosure media preview- pass in the postId
					reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
					// Remove previous enclosure editor content
					tinymce.activeEditor.setContent('');
				</cfif>
					// For the external video preview, let tinymce resolve the URL natively (this is a tinymce function). When we display the video from the database plyr will take over (Note: this does not remove prior content)
          			resolve({ html: '' });
				},
				// Turn off the 'powered by Tiny' advertisement at the bottom of the editor
				branding: false
			});

		//}
						
		// Print the current menu (useful to get the current menu items for a given editor): 
		// console.log(tinyMCE.activeEditor.ui.registry.getAll().menuItems);
		
		function imageUploadHandler(blobInfo, success, failure) {
			var xhr, formData;

			xhr = new XMLHttpRequest();
			xhr.withCredentials = true;
			xhr.open('POST', "<cfoutput>#imageHandlerUrl#</cfoutput>");
			//xhr.setRequestHeader('Content-Type', 'multipart/form-data;'); // manually set header

			// Set a timeout for Safari on mobile
			xhr.timeout = 50000; // time in milliseconds (50 seconds)
			// Onload event 
			xhr.onload = function() {
				var json;

				if (xhr.status != 200) {
					failure("HTTP Error: " + xhr.status);
					return;
				}

				// Extract the data from the json array. There should be the location and the new media id.
				// Note: we don't need to loop thorugh anything as there is only one record in the response array.
				var json = JSON.parse(xhr.responseText);
				var location = json.location; // or json["location"]
				var mediaId = json.mediaId; // or json["mediaId"]
				var mediaActions = json.mediaActions; // This is only present with image enclosures at this time
				
				// Remove and save the media id into the imageMediaId hidden form field. We need to retain the mediaId in order to append it to the image to associate the image to the record of the database. We can't perform any further action on the new source code here as the image has not yet been placed into the editor and is not available in the DOM. 
				// Remove the prior mediaId 
				$("#<cfoutput>#imageMediaIdField#</cfoutput>").val('');
				// And save it...
				$("#<cfoutput>#imageMediaIdField#</cfoutput>").val(mediaId);
							
			<cfif selectorId neq 'imageUploadEditor'>
				// Raise a dialog indicating the actions taken 
				var mediaActionHtmlList = "The images have been optimized for social media sharing and the following images have been created:<br/><ul>";
				// Loop through the comma separated list and get each action
				for (i = 0; i < listLen(mediaActions); i++) {
					mediaActionHtmlList = mediaActionHtmlList + "<li>" + listGetAt(mediaActions, i) + "</li>";
				}
				mediaActionHtmlList = mediaActionHtmlList + "</ul>";

				/* Note: this is showing up in the background of the image picker. I need to figure out the timing of the events before I show this and fix in the next version. For now I am commenting this out.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Your image was saved", message: mediaActionHtmlList, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "300px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});	*/
			</cfif>
				
				// Note: we can't reset the content of the editor here as it would remove the current image when editing is taking place.
				// Call the tinymce success function and pass along the location to populate the editor. This is a native tinymce function.
				success(location);
				
				<cfif selectorId eq 'enclosureEditor'>
				try {
					// When the enclosureEditor is being used, update the enclosure thumbnail image.
					if (location.includes(".png") || location.includes(".gif") || location.includes(".jpg")){
						var thumbnailImage = document.getElementById("thumbnailImage");
						thumbnailImage.src = location;
					}
				} catch(e) {
					// Do nothing 
				}
				</cfif>
			};

			xhr.onabort = function (e) {
				// XMLHttpRequest aborted.
				alert('Process aborted');
			};

			xhr.onerror = function (e) {
				// XMLHttpRequest errored. 
				alert('Error: ' + xhr.status);
			};

			xhr.ontimeout = function (e) {
				// XMLHttpRequest timed out. 
				tinymce.activeEditor.windowManager.close();
			};

			formData = new FormData();
			// The file is the editor field
			formData.append('file', blobInfo.blob(), blobInfo.filename());

			xhr.send(formData);
		}//function imageUploadHandler(blobInfo, success, failure) {
		
		// Displays the editors. Used for debugging
		function displayEditorNames(){
			if (!tinyMCE.editors.length) {
				alert('none');
			}
			for (i=0; i < tinyMCE.editors.length; i++){
				var content = tinyMCE.editors[i].getContent();
				alert('Editor-Id(' + tinyMCE.editors[i].id + '):' + content);
			}
		}
		
		/* Another way of setting content- but it also does not solve the problems that I am having as the editors are not defined:
		for(i=0; i < tinymce.editors.length; i++){
			alert('inserting content into ' + tinymce.editors[i])
			tinymce.editors[i].setContent('content');
		} 
		*/
	
	</script>
	
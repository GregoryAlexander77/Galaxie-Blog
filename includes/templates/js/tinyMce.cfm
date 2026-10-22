	<!---<cfoutput>selectorId: #selectorId#</cfoutput>--->
	<cfsilent>	
	<!--- 
	Important notes: the selector name must be completely unique. Furthermore, the selector name must be unique and contain a unique value even if the page is reloaded, or a window widget was reloaded. If the selector name is not unique we have two major issues that cause this entire editor to be useless. Read below.
	We can load the tiny mce scripts in two places- in the index.cfm header 1), or whithin the window logic here 2).

	1) If we place the script in the header, we will be able to use the insertContent and setContent methods, but once the Kendo window closes or is refreshed, we will not be able to open up the editor again. This is due to how tincymce prepares the dom and how the Kendo window operates. Without a unique name, the editor will work once, but if opened again, it will dissapear. 

	2) If we put the tinymce scripts in this window, the editor's will not disappear, however, the editors will not be in memory and we can't use any get or set methods to insert new content. The only way that I found around this is to use a getTick (or other random generator) to make the selector name unique every single time that it is called. This is a necessary hack as tincyMce does not hanlle single page applications all that well. 

	With that out of the way, this is how the template should be used:
	<cfset mediaProcessType = "enclosure">// either enclosure (which can be an image or video), gallery, post, or comment.
	<cfset selectorName = "post" & second(now())>
	<cfset eidtorHeight = "300">
	<cfset imageHandlerUrl = "../../common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=enclosure&postId=" & getPost[1]["PostId"]>
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
	These vars are not needed
	<cfset includeGallery = true>
	<cfset includeCarousel = false>
	<cfset includeCustomWindow = false>
	<cfset includeVideoUpload = false>
	<cfset includeFileUpload = false>
	<cfset disableWebVttAndVideoCoverButtons = true>
	<cfset includeMaps = true>
	<cfset includeCommonCss = false>

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
			//tinymce.get("postEnclosure15").setContent("<p>9898 foo gore moo</p>");
		}, 5000);

	});	

	To set the content, you can also use: tinymce.get("postEnclosure15").setContent("test"); Note: the setContent method will break if you're using any scripts in the code!
 	--->
		
	<!--- Instantiate the Render.cfc. This will be used to inject comments around any scripts to tinyMce. This is critical as using scripts with the setContent tinyMce method will break the editor. We will remove these comments using server side logic in order to allow scripts to be used --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		
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
	<cfparam name="includeWebForm" default="false">
<cfparam name="includeBooking" default="false">
<cfparam name="includeProduct" default="false">
	<cfparam name="includeVideoUpload" default="false">
	<cfparam name="includeGradient" default="false">
	<cfparam name="includeHeroAnimation" default="false">
	<cfparam name="includeHeroCoverImage" default="false">
	<!--- The Hero editor (2026-10-20, owner): Scene (Insert menu and ribbon) and Hero text (Format menu and ribbon), which were
	separate buttons in the post editor. --->
	<cfparam name="includeScene" default="false">
	<cfparam name="includeHeroText" default="false">
	<cfparam name="includeFileUpload" default="false">
	<cfparam name="disableWebVttAndVideoCoverButtons" default="true">
	<cfparam name="includeMaps" default="true">
	<cfparam name="includeCommonCss" default="false">
	
	<!--- Code Mirror Code Editor Vars --->
	<!--- Path to the plugin (plugin.js). --->
	<cfset codeMirrorPluginPath = application.baseUrl & "/common/libs/tinymce/plugins/codemirror/plugin.js">
	<!--- Note: this path should point to the foler for the Code Mirror library. Do not point to the folder where codemirror.js is found. --->
	<cfset codeMirrorLibPath = application.baseUrl & "/common/libs/codemirror5/">
	
	<!--- Note: don't use the autosave plugin- its buggy! I removed the codemirror plugin in May of 26. I used to use 'codemirror' as a plugin that replaced 'code', however, it has security issues. --->
	<cfparam name="pluginList" default="'advlist autolink lists hr link image charmap print preview anchor',
		'searchreplace visualblocks code codesample fullscreen',
		'insertdatetime media table paste imagetools wordcount iconfonts textpattern toc emoticons nonbreaking'">

	<cfif  application.serverSupportsWoff2>
		<cfset fontExtension = "woff2">
	<cfelse>
		<cfset fontExtension = "woff">
	</cfif>
		
	<!--- Code to keep track of the unique selector names. We are going to use cookies to keep track of the current selector names and remove the editors that are no longer being used. The selectorId is what we are going to use to get to the unqique selectorName (ie cookie.postEditor will provide the unique selector name). --->
	<!--- Create our unique selector name. This should be something like 'post' & 12 & 30> --->
	<cfset selectorName = selectorId & minute(now()) & second(now())>
		
	</cfsilent>
	<!--- If the cookie name exists, the cookie name is equal to the Remove any unused editors from our editor array in memory --->
	<cfif isDefined("cookie.#selectorId#") and evaluate("cookie.#selectorId#") neq selectorName>
		<!--- Include the get-video-id script. This will be used to determine the video provider and the video id --->
		<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/get-video-id/dist/get-video-id.umd.min.js"></script>
		<!--- Remove the unused editor --->
		<script>
			<cfoutput>
			tinymce.EditorManager.execCommand('mceRemoveControl', true, '#evaluate("cookie.#selectorId#")#');
			try {
				<!--- In order to make sure that *all* references are removed, use the destroy command. We are putting this in a try block in case the editor is removed. Notes: while testing the efficacy of the mceRemoveControl (above), I noticed that the editor is still referenced using the displayEditorNames() function. It is my educated guess that get method below determines that the editor is no longer active and automatically removes it rather than the destroy statement. That said, if I don't use this line the editor is still in memory and this line will remove it. --->
				tinymce.get("#evaluate("cookie.#selectorId#")#").destroy();
			} catch {
				<!--- Do nothing --->
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

		<!--- Rewrites the built-in 'toc' plugin's auto-generated anchor ids (mcetoc_xxxxxxxxxx) into human-readable slugs built from each heading's own text (eg. "background", or "background-1" for a repeated heading). This keeps the free toc plugin but gives us descriptive, stable anchors instead of the random ones it generates by default. Declared at the top level (not inside setup()) so it is available both to the ExecCommand hook below and to the save-time cleanup pass in postDetail.cfm. --->
		function rewriteTocAnchors(editor) {
			try {
				var body = editor.getBody();
				if (!body) return;

				<!--- Build a url-fragment-safe slug: lower case, spaces/punctuation collapsed to single dashes, leading/trailing dashes trimmed. --->
				function slugify(text) {
					var clean = (text || '').replace(/\u00a0/g, ' ').trim().toLowerCase();
					var slug = clean.replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
					return slug || 'section';
				}

				<!--- TinyMCE serializes a link from its data-mce-href attribute, not its href. Changing only href is silently undone on save, so both are set together. --->
				function setTocLinkTarget(link, target) {
					link.setAttribute('href', target);
					link.setAttribute('data-mce-href', target);
				}

				var usedSlugs = {};
				var headings = body.querySelectorAll('h1[id^="mcetoc_"], h2[id^="mcetoc_"], h3[id^="mcetoc_"], h4[id^="mcetoc_"], h5[id^="mcetoc_"], h6[id^="mcetoc_"]');

				headings.forEach(function (heading) {
					var oldId = heading.id;
					var baseSlug = slugify(heading.textContent);
					var newSlug = baseSlug;

					<!--- Only append a numeric suffix when the plain slug is not already unique on this page. --->
					var counter = 1;
					while (usedSlugs[newSlug]) {
						newSlug = baseSlug + '-' + counter;
						counter++;
					}
					usedSlugs[newSlug] = true;

					heading.id = newSlug;

					<!--- Keep the matching TOC link (built by the toc plugin) pointed at the new id. --->
					var tocLink = body.querySelector('.mce-toc a[href="#' + oldId + '"]');
					if (tocLink) {
						setTocLinkTarget(tocLink, '#' + newSlug);
					}
				});

				<!--- Safety net: any TOC link still pointing at an mcetoc_ id that no longer exists on the page (the link
				update above can miss on a first save, leaving the saved TOC broken until a second save) is re-pointed at
				the heading with the same text. The toc plugin builds each link from its heading's text. --->
				body.querySelectorAll('.mce-toc a[href^="#mcetoc_"]').forEach(function (tocLink) {
					var targetId = tocLink.getAttribute('href').substring(1);
					if (body.querySelector('[id="' + targetId + '"]')) return;
					var linkText = tocLink.textContent.trim();
					body.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach(function (heading) {
						if (heading.textContent.trim() === linkText) {
							setTocLinkTarget(tocLink, '#' + heading.id);
						}
					});
				});
			} catch (err) {
				<!--- Never let a TOC rewrite problem break saving/editing. --->
				console.error('Error rewriting TOC anchors:', err);
			}
		}//..function rewriteTocAnchors(editor)

		<!--- Initiate the tinymce editor. --->
		tinymce.init({
			schema: 'html5',
			selector: '#<cfoutput>#selectorName#</cfoutput>',
			<cfif session.isMobile>// On mobile devices, subtract 25 pixels (for padding) from the content container pixel width 
			width: (getContentPixelWidth()-25),</cfif>
			<!--- Skin --->
			skin: "<cfoutput>#kendoTheme#</cfoutput>",//This points to the folder in the ui directory
		<cfif includeCommonCss>
			<!--- The Kendo folder for the editor's stylesheets, worked out the same way as head.cfm does for the page
			(2026-10-10): the Kendo folder from Blog Options when one is set, otherwise the built-in Kendo Core folder, and
			the blog's base path added only if the folder doesn't already start with it (or is a full http address). This
			used to add the base path every time, so with the blog in /blog and the Kendo folder set to
			/blog/common/libs/kendo/ the editor asked for /blog/blog/common/libs/kendo/... and got 404s. --->
			<cfset editorKendoLocation = len(trim(application.kendoFolderPath)) ? trim(application.kendoFolderPath) : application.baseUrl & "/common/libs/kendoCore/">
			<cfif left(editorKendoLocation, 4) neq "http" and len(application.baseUrl) and findNoCase(application.baseUrl, editorKendoLocation) neq 1>
				<cfset editorKendoLocation = application.baseUrl & editorKendoLocation>
			</cfif>
			<!--- Point to a common content.css. This does not impact the dynamic nature of the skin. --->
			content_css: ["<cfoutput>#application.baseUrl#</cfoutput>/includes/templates/blogContentCss.cfm?standalone=true",
			"<cfoutput>#editorKendoLocation##trim(getTheme[1]['KendoCommonCssFileLocation'])#</cfoutput>",
			"<cfoutput>#editorKendoLocation##trim(getTheme[1]['KendoThemeCssFileLocation'])#</cfoutput>",
			<!--- Include font awesome --->
			"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css"],
		<cfelse>
			<!--- Include font awesome --->
			content_css: ["https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.7.2/css/all.min.css"],
		</cfif>
			//<cfoutput>#application.baseUrl#</cfoutput>/common/libs/tinymce/skins/ui/oxide/content.css"
			height: "<cfoutput>#editorHeight#</cfoutput>",
			<!--- This only works with tinymce 5.6+ --->
			images_file_types: 'jpeg,jpg,jpe,jfi,jif,jfif,png,gif,bmp<cfif application.imageEngineSupportsWebP>,webp</cfif>',<!--- No WebP where this server can't read it (2026-10-16) --->
			<!--- Custom plugin argument to allow us to use fontawesome icons --->
			iconfonts_selector: '.fa, .fab, .fal, .far, .fas, .glyphicon', // optional (default shown)
		<!--- Set the menu depending upon the selector name. --->
		<cfswitch expression="#selectorId#">
		<cfcase value="enclosureEditor">
			menubar: 'file edit insert format view',
			menu: {
				file: {title: 'File', items: 'preview print'},
				edit: {title: 'Edit', items: 'undo redo | cut copy paste | selectall'},
				insert: {title: 'Insert', items: 'image | media | gradient heroAnimation heroCoverImage carousel | scene | videoUpload webVttUpload videoCoverUpload | map mapRouting'},
				format: {title: 'Format', items: 'heroText'},
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
		<!--- Scene text (2026-10-19, Galaxie 5): the short text over a scene section (sceneDetail.cfm). Toolbar only - none of the
		Insert menu's galleries, maps or forms belong in it. --->
		<cfcase value="sceneTextEditor">
			menubar: false,
		</cfcase>
		<cfdefaultcase>
			<!--- Every custom toolbar button needs its menu item listed under Insert too (2026-10-13). Items an editor doesn't register, such as webForm outside the post editor, are skipped by TinyMCE. --->
			menubar: 'file edit insert view format table ',
			menu: {
				file: { title: 'File', items: 'newdocument restoredraft | preview | print ' },
				edit: { title: 'Edit', items: 'undo redo | cut copy paste | selectall | searchreplace' },
				view: { title: 'View', items: 'code | visualaid visualchars visualblocks | spellchecker | preview fullscreen' },
				<!--- Same order as the toolbar buttons (owner, 10-16): link, pictures, video and art, maps, interactive, writing extras, small bits, page structure. --->
				insert: { title: 'Insert', items: 'link | image fancyBoxGallery carousel | media gradient heroAnimation | map mapRouting | webForm booking product customWindow | codesample inserttable template | hr emoticons charmap | toc anchor pagebreak nonbreaking insertdatetime' },
				format: { title: 'Format', items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align lineheight | forecolor backcolor | removeformat' },
				table: { title: 'Table', items: 'inserttable | cell row column | tableprops deletetable' }
			},
		</cfdefaultcase>
		</cfswitch>
			toolbar_sticky: true, // Makes the toolbar float at the top of the page
			toolbar_sticky: "80px",// This fixes when the toolbar disappears with the toolbar_sticky
			plugins: [<cfoutput>#pluginList#</cfoutput>],
			<!--- Code Mirror is our code viewer and is a custom plugin --->
			/* Depracated in April 2026
			external_plugins: {
				codemirror: "<cfoutput>#codeMirrorPluginPath#</cfoutput>"
			},
			codemirror: {
				indentOnInit: true,
				path: '<cfoutput>#codeMirrorLibPath#</cfoutput>',
				config: {
					lineNumbers: true,
					lineWrapping: true
				}
			},*/
			<!--- Change the toc_depth to support h4 tags (the default is h1-3) --->
			toc_depth: 5,
			<!--- Allow the Prism folder to be the prism engine instead of the embedded version of Prism within TinyMce. This is required to have line numbers --->
			codesample_global_prismjs: true,
			<!--- Set the prism languages --->
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
			<!--- Callouts (2026-10-22, owner): Styles > Callouts wraps the selected paragraphs in a quote block with a Kendo color class, drawn
			softly by blogContentCss.cfm. Added to TinyMCE's own styles, not in place of them. --->
			style_formats: [
				{ title: 'Callouts', items: [
					{ title: 'Callout: Info', block: 'blockquote', classes: 'k-notification-info', wrapper: true, preview: false },
					{ title: 'Callout: Tip', block: 'blockquote', classes: 'k-notification-success', wrapper: true, preview: false },
					{ title: 'Callout: Warning', block: 'blockquote', classes: 'k-notification-warning', wrapper: true, preview: false },
					{ title: 'Callout: Important', block: 'blockquote', classes: 'k-notification-error', wrapper: true, preview: false }
				] }
			],
			style_formats_merge: true,
			media_live_embeds: true,
			<!--- Load our custom fonts --->
			font_formats: "<cfloop from="1" to="#arrayLen(getThemeAndWebSafeFonts)#" index="i"><cfoutput>#getThemeAndWebSafeFonts[i]['Font']#=<cfif len(getThemeAndWebSafeFonts[i]['WebSafeFallback'])>#lCase(getThemeAndWebSafeFonts[i]['WebSafeFallback'])#<cfelse>#lCase(getThemeAndWebSafeFonts[i]['Font'])#</cfif>;</cfoutput></cfloop>",
			<!--- Declare the font faces and set the font properties for the editor body --->
			content_style: '<cfoutput><cfloop from="1" to="#arrayLen(getSelfHostedFonts)#" index="i">@font-face {font-family: "#getSelfHostedFonts[i]['Font']#"; src: url("#application.baseUrl#/common/fonts/#getSelfHostedFonts[i]['FileName']#.#fontExtension#") format("#fontExtension#");}</cfloop> body { font-family:#themeBodyFont#; font-size:14px; } blockquote[class*=k-notification-] { margin: 1em 0; padding: 10px 16px; border: 1px solid; border-left-width: 5px; border-radius: 4px; } blockquote.k-notification-info { border-color: ##7fb2e5; border-left-color: ##0066cc; background: ##eef5fc; } blockquote.k-notification-success { border-color: ##9fd49a; border-left-color: ##37b400; background: ##f0f9ee; } blockquote.k-notification-warning { border-color: ##f3d38a; border-left-color: ##e8a400; background: ##fdf7e8; } blockquote.k-notification-error { border-color: ##ef9f97; border-left-color: ##d9372b; background: ##fcefee; }',</cfoutput>
			<!--- I am turning off script support as the setContent method will break if scripts are included. If you want it enabled add this string to the extended_valid_elements var below- 'script[src|async|defer|type|charset]', and use a different method to populate the editor. Alow a list item in order to incorporate font awesome icons, we also put onClick events on buttons. --->
			extended_valid_elements: 'i[*],a[href|class|id|onClick],button[*],span[*],input[*],script[src|async|defer|type|charset],more',
			<!--- Allows all elements: valid_elements : '*[*]', We need to allow javascript within URL's as are using javascript links in the navigation menu. Without this argument tinymce strips out the 'javascript:' string in URL's --->
			allow_script_urls: true,
			<!--- Allow custom more tags --->
			custom_elements: 'more',
			<!--- autosave_interval: "240s", Set the content and add certain events --->
			setup: function (editor) {
				<!--- Load the intial content --->
				editor.on('init', function (e) {
					<!--- Note: the content is JSON-encoded before being embedded here (rather than dropped into a backtick template literal) so that a stored `${...}` sequence in the content can't be evaluated as a live JS expression the moment this script runs - a raw backtick literal is vulnerable to that regardless of the script-tag comment-wrapping below. We are also sanitizing the scripts by putting HTML comments around any script tag found before inserting it into the editor. --->
					editor.setContent(<cfoutput>#serializeJSON(RendererObj.renderScriptsToTinyMce(contentVar))#</cfoutput>);
					<!--- Clean up any table of contents that was already present in the loaded content (eg. an older post saved before this rewrite existed, or content reloaded after a prior insert). --->
					rewriteTocAnchors(editor);
				});

				<!--- Whenever the built-in toc plugin inserts or refreshes the table of contents, immediately replace its random mcetoc_xxxxxxxxxx anchor ids with descriptive slugs so what you see in the editor already matches what will be saved. --->
				editor.on('ExecCommand', function (e) {
					if (e.command === 'mceInsertToc' || e.command === 'mceUpdateToc') {
						rewriteTocAnchors(editor);
					}
				});

			<cfif selectorId eq 'enclosureEditor' or selectorId eq 'videoCoverEditor' or selectorId eq 'imageUploadEditor' or selectorId eq 'heroCoverImageEditor'>
				<!--- Listen to events to determine if a new image or video has been added --->
				editor.on('NodeChange', function (e) {
					<!--- The NodeChange may have several thousands of events if your not careful and try to inspect it. I have also tried the following events but have not made them work. editor.on('Change', function (e) { editor.on('SetContent', function(e) { save_callback : "myCustomSaveContent" --->

					<!--- Here, we are looking to see when an image has been added to the editor and save the URL into a hidden form in order to save the url to the database. --->
					if (e.element.tagName === "IMG" && e.element.currentSrc != e.element.src) { 
						<!--- console.log('e.element.currentSrc:' + e.element.currentSrc + ' e.element.src:' + e.element.src); alert('newImage') --->
						<!--- Original logic to find external links. if (e.element.tagName === "IMG" && e.element.currentSrc != e.element.src && e.element.src.indexOf(window.location.host) == -1) { --->
					<!--- This logic only applies when using the enclosure editor --->
					<cfif selectorId eq 'enclosureEditor'>
						<!--- Clear the previous content and send the current URL that was chosen to populate the tinymce control --->
						clearPreviousEditorContent( e.element.src );
					</cfif>

						<!--- alert('e.element.src: ' + e.element.src + ' $("#externalImageUrl").val(): ' + $("#externalImageUrl").val() ); --->

						<!--- If the image has changed, send the data to the server to update the database. I only want to do this once per URL. --->
						if ( e.element.src != $("#externalImageUrl").val() ){
							<!--- Custom save external URL function is on the various interfaces that use this code --->
							saveExternalUrl(e.element.src, 'image', '<cfoutput>#selectorId#</cfoutput>', '');
							<!--- Once the URL has been sent to the server, save the new url into the externalImageUrl hidden form. We will use this string to compare to the editor image src to see if something is new in order to pass the URL to the server --->
							$("#externalImageUrl").val(e.element.src);
						}
					}

					<!--- The onChange event can be used instead of the onNodeChage as well: editor.on('change', function (e) { console.log('change event fired'); console.log(e); --->
				});//..editor.on('NodeChange', function (e) {
			</cfif>

			<cfif selectorId eq 'enclosureEditor' or selectorId eq 'videoCoverEditor' or selectorId eq 'imageUploadEditor' or selectorId eq 'heroCoverImageEditor'>
				<!--- 2026-09-25, extended 2026-09-26: bridges TinyMCE's own native "Insert/Edit Image" dialog to a
				standalone Uppy cropping window - clicking the dialog's "Upload" tab opens a separate window
				(createAdminInterfaceWindow Id 74/75/76, one per screen - see each *UppyUploadWindow.cfm's own
				comments) instead of using the dialog's own plain dropzone, which is left in place, unaffected, as a
				second option. Per the "get all uploads onto Uppy" roadmap goal (see
				[[reminder-unify-image-uploader]]), this covers every screen that shares the single-image
				NodeChange handling above (enclosureEditor, videoCoverEditor, imageUploadEditor) - started with
				enclosureEditor only, extended to the other two once that first bridge was confirmed working. On a
				successful upload, each window file closes this dialog itself
				(tinymce.activeEditor.windowManager.close()), then itself, then the screen's own containing window -
				see each file for specifics. Kendo's own z-index counter didn't reliably clear the still-open
				dialog's tox-dialog-wrap (z-index up to 1400) on its own, so the Id==74/75/76 branches of
				createAdminInterfaceWindow (blogJsContent.cfm) force the new window's z-index explicitly after
				creation. --->
				editor.on('OpenWindow', function (e) {
					setTimeout(function() {
						var dialogRoot = $('.tox-dialog:visible').last();
						if (dialogRoot.find('.tox-dialog__title').text().trim() !== 'Insert/Edit Image') { return; }
						var uploadTab = dialogRoot.find('.tox-dialog__body-nav-item').filter(function() {
							return $(this).text().trim() === 'Upload';
						});
						if (!uploadTab.length || uploadTab.data('uppyUploadBound')) { return; }
						uploadTab.data('uppyUploadBound', true);
						uploadTab.on('click', function() {
							<cfif selectorId eq 'enclosureEditor'>
								createAdminInterfaceWindow(74, <cfoutput>#URL.optArgs#</cfoutput>);
							<cfelseif selectorId eq 'videoCoverEditor'>
								createAdminInterfaceWindow(75, <cfoutput>#URL.optArgs#</cfoutput>);
							<cfelseif selectorId eq 'imageUploadEditor'>
								createAdminInterfaceWindow(76, <cfoutput>#URL.optArgs#</cfoutput>, '<cfoutput>#URL.otherArgs#</cfoutput>');
							<cfelseif selectorId eq 'heroCoverImageEditor'>
								createAdminInterfaceWindow(81, <cfoutput>#URL.optArgs#</cfoutput>);
							</cfif>
						});
					}, 50);
				});
			</cfif>

			<!--- 2026-09-30: this editor instance is itself hosted inside a Kendo window (eg. the main Post
			Editor is a window opened via newPost.cfm, included from adminInterface.cfm). TinyMCE's own dialogs
			(.tox-dialog-wrap) cap out around z-index 1400 in the tox skin's CSS - a fixed, not climbing, value -
			while Kendo's own z-index counter keeps climbing every time a window opens and can easily exceed
			that. Once it does, any TinyMCE dialog (View > Source Code being the one that surfaced this) renders
			behind its own containing Kendo window instead of on top of it, making the dialog look like it
			silently failed to open.

			2026-10-07: raising the dialog's own z-index is not enough by itself - see galaxieRaiseToxFloatingUi
			below for the full explanation (TinyMCE's floating-UI host sets its own fixed z-index and creates a
			CSS stacking context that caps every descendant, however high its own z-index is set). This handler
			is kept as a fast first response to OpenWindow; the shared function below also runs on an interval as
			a safety net, so a dialog gets fixed even if this specific event is ever missed. --->
			editor.on('OpenWindow', function (e) {
				setTimeout(galaxieRaiseToxFloatingUi, 0);
			});

			<!--- 2026-10-07: FOUND AND CONFIRMED LIVE, after five earlier attempts (each fixed one failure mode and
			was then disproven by a new one - see the session transcript / memory for the full story). None of
			those attempts worked because they were all aimed at the wrong target.

			The actual cause: TinyMCE renders every dialog AND every menu into its own floating-UI host element,
			.tox-tinymce-aux. That element has a fixed z-index (16000 in the tox skin's CSS) and position:relative
			of its own, which makes it a CSS stacking context root. Once an element creates a stacking context, no
			z-index on any of its DESCENDANTS, however high, can ever escape that context when compared to a
			SIBLING outside it (like a Kendo window) - the entire subtree paints as one unit at the CONTAINER's own
			z-index. Every attempt tonight raised the z-index of the dialog or menu ITSELF, which was always
			futile once a Kendo window's z-index passed 16000 (which happens quickly, confirmed by this session's
			own earlier logs showing k-window values like 100044-100048) - confirmed directly with
			document.elementFromPoint(): the menu had the believed-correct z-index, yet an unrelated iframe still
			painted on top, because the menu's real container was never touched.

			It gets worse with more than one TinyMCE instance open at once (eg. the Post Enclosure editor open
			over the main post editor, exactly the "upload an image, then open a menu" sequence that kept
			reproducing this): there is then more than one .tox-tinymce-aux on the page, one per instance, and a
			single global selector for it always finds the SAME one regardless of which editor is actually being
			used - confirmed live that it was finding the OTHER (hidden, inactive) instance's container every
			time, never the one that actually held the open menu. The fix has to find the right container
			per-element, via closest(), never via a single querySelector.

			Defined on window, guarded to run only once, even though this whole script block runs once per editor
			instance on the page - every instance's OpenWindow handler above calls the bare identifier
			galaxieRaiseToxFloatingUi, which resolves to this single shared one via normal scope lookup. --->
			if (!window.galaxieTocMenuObserverAttached) {
				window.galaxieTocMenuObserverAttached = true;
				window.galaxieRaiseToxFloatingUi = (function() {
					var pinned = (typeof WeakSet !== 'undefined') ? new WeakSet() : null;
					var pin = function(el, z) {
						el.style.setProperty('z-index', z, 'important');
						if (pinned) {
							if (pinned.has(el)) { return; }
							pinned.add(el);
						}
						<!--- Re-applies if TinyMCE's own position/style recalculation ever overwrites this later - confirmed live this does happen to a dialog/menu element itself (though not to its aux container, which is what actually matters - kept as a belt-and-suspenders measure). --->
						new MutationObserver(function() {
							if (getComputedStyle(el).zIndex !== String(z)) {
								el.style.setProperty('z-index', z, 'important');
							}
						}).observe(el, { attributes: true, attributeFilter: ['style'] });
					};
					return function() {
						var found = $('.tox-menu:visible, .tox-dialog-wrap:visible');
						if (!found.length) { return; }
						var topZ = 100000;
						$('.k-window:visible').each(function(){
							var z = parseInt($(this).css('zIndex'), 10);
							if (!isNaN(z) && z > topZ) { topZ = z; }
						});
						found.each(function() {
							pin(this, topZ + 10);
							<!--- The actual fix: raise this element's own containing floating-UI host too, found
							relative to THIS element (not a single page-wide lookup), so it is correct even with
							more than one editor instance open at once. --->
							var aux = this.closest('.tox-tinymce-aux');
							if (aux) { pin(aux, topZ + 10); }
						});
					};
				})();
				<!--- Menu-bar and toolbar dropdowns (eg. Insert > Table of Contents) never fire OpenWindow, so
				also re-check shortly after anything is clicked that could plausibly open one, and on a short
				recurring interval as a safety net for whatever that click-based check misses (eg. a menu TinyMCE
				creates some time after the click, such as after an image upload finishes). --->
				document.addEventListener('mousedown', function(e) {
					if (!e.target || !e.target.closest) { return; }
					if (e.target.closest('.tox-mbtn, .tox-tbtn, .tox-menu, .tox-collection__item')) {
						setTimeout(window.galaxieRaiseToxFloatingUi, 30);
						setTimeout(window.galaxieRaiseToxFloatingUi, 150);
					}
				}, true);
				setInterval(window.galaxieRaiseToxFloatingUi, 100);
			}

				function clearPreviousEditorContent(currentSrc){
					<!--- alert('clearing content'); --->

					<!--- There can be only one image or video (an iframe) in an enclosure. Before doing this, we first need to get the current contents of the editor to determine if there are more than 1 images or videos. */ Get the current editor html content --->
					currentEditorContent = tinymce.activeEditor.getContent();

					<!--- Find and remove any previous images or videos from YouTube or Vimeo. --->
					if (($(currentEditorContent).find("img").length > 1) || ($(currentEditorContent).find("img","iframe").length > 1)){
						<!--- alert($(currentEditorContent).find("img","iframe").length) --->
						
						<!--- Create the new image --->
						var newImage = '<img src="' + currentSrc + '">';

						<!--- Only keep the first image or video --->
						tinymce.activeEditor.setContent( newImage );

						<!--- For the external image or video preview, let tinymce resolve the URL natively (this is a tinymce function). When we display the video from the database plyr will take over. This may fail if the saveExternalUrl function is called the 2nd time --->
						try {
							tinymce.resolve({ html: '' });
						} catch(e){
							<!--- Do nothing --->
						}
		
					}
					<!--- Code to get current selected item console.log(editor.selection.getNode()) --->
				}

			<cfif includeGallery>
				<!--- Custom dialogs that are invoked via the toolbar --->

				<!--- FancyBox Gallery. This opens up an uppy dialog. Note: this also needs to be added to the toolBarString --->
				editor.ui.registry.addButton('fancyBoxGallery', {
					icon: "gallery",
					tooltip: 'Image Gallery',
					onAction: function (_) {
						$('#image').val('');
						<!--- console.log('gallery' + tinymce.activeEditor.selection.getNode()); Open up a new gallery window. The code for this window is the next switch block below. --->
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
			<cfif includeCarousel>
				<!--- Custom dialogs that are invoked via the toolbar Carousel. This opens up the same uppy dialog as the gallery. Note: this also needs to be added to the toolBarString --->

				<!--- Create the icon --->
				editor.ui.registry.addIcon(
					'carousel',
					'<svg><span data-fa-symbol="carousel" class="fontAwesomeIcon fa-solid fa-panorama">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('carousel', {
					text: '<i class="fontAwesomeIcon fa-solid fa-panorama"></i>',
					tooltip: 'Carousel',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up the uppy upload window. --->
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
			<cfif includeGradient>
				<!--- Insert/Edit Gradient - opens the Grapick+Pickr popup (window 77). Same pattern as carousel
				above; note: this also needs to be added to the toolBarString. --->

				<!--- Create the icon - fa-swatchbook is Font Awesome's free tier, matching the toolbar's existing
				fas solid-icon convention (not a brand icon). --->
				editor.ui.registry.addIcon(
					'gradient',
					'<svg><span data-fa-symbol="gradient" class="fontAwesomeIcon fas fa-swatchbook">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('gradient', {
					text: '<i class="fontAwesomeIcon fas fa-swatchbook"></i>',
					tooltip: 'Insert/Edit Gradient',
					onAction: function (_) {
						createAdminInterfaceWindow(77,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});

				editor.ui.registry.addMenuItem('gradient', {
					icon: 'gradient',
					text: 'Gradient',
					onAction: function () {
						createAdminInterfaceWindow(77,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});
			</cfif>
			<cfif includeHeroAnimation>
				<!--- Choose Animation - opens the animation effect picker (window 79, currently Vanta.js). Same
				pattern as carousel/gradient above; note: this also needs to be added to the toolBarString.
				2026-10-03: renamed from includeVanta/'vanta' while still dev-only/unmigrated. --->

				<!--- Create the icon - fa-water matches the admin button's own icon choice before this was
				folded into TinyMCE's native toolbar/menu. --->
				editor.ui.registry.addIcon(
					'heroAnimation',
					'<svg><span data-fa-symbol="heroAnimation" class="fontAwesomeIcon fas fa-water">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('heroAnimation', {
					text: '<i class="fontAwesomeIcon fas fa-water"></i>',
					tooltip: 'Choose Animation',
					onAction: function (_) {
						createAdminInterfaceWindow(79,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});

				editor.ui.registry.addMenuItem('heroAnimation', {
					icon: 'heroAnimation',
					text: 'Choose Animation',
					onAction: function () {
						createAdminInterfaceWindow(79,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});
			</cfif>
			<cfif includeScene>
				<!--- Scene (2026-10-20): the scrolling scene at the top of the post (window 108), in the Insert menu and on the ribbon
				like the carousel - a scene takes the place of the picture at the top. --->
				editor.ui.registry.addIcon('scene', '<svg><span data-fa-symbol="scene" class="fontAwesomeIcon fas fa-layer-group">&nbsp;</span></svg>');
				editor.ui.registry.addButton('scene', {
					text: '<i class="fontAwesomeIcon fas fa-layer-group"></i>',
					tooltip: 'Scene',
					onAction: function (_) { createAdminInterfaceWindow(108,<cfoutput>#URL.optArgs#</cfoutput>); }
				});
				editor.ui.registry.addMenuItem('scene', {
					icon: 'scene',
					text: 'Scene',
					onAction: function () { createAdminInterfaceWindow(108,<cfoutput>#URL.optArgs#</cfoutput>); }
				});
			</cfif>
			<cfif includeHeroText>
				<!--- Hero text (2026-10-20): the heading over the picture at the top of the post (window 109), in the Format menu (it
				sits on top of the media rather than being media) and on the ribbon. --->
				editor.ui.registry.addIcon('heroText', '<svg><span data-fa-symbol="heroText" class="fontAwesomeIcon fas fa-heading">&nbsp;</span></svg>');
				editor.ui.registry.addButton('heroText', {
					text: '<i class="fontAwesomeIcon fas fa-heading"></i>',
					tooltip: 'Hero text',
					onAction: function (_) { createAdminInterfaceWindow(109,<cfoutput>#URL.optArgs#</cfoutput>); }
				});
				editor.ui.registry.addMenuItem('heroText', {
					icon: 'heroText',
					text: 'Hero text',
					onAction: function () { createAdminInterfaceWindow(109,<cfoutput>#URL.optArgs#</cfoutput>); }
				});
			</cfif>
			<cfif includeHeroCoverImage>
				<!--- Hero Cover Image - opens the cover-image upload editor (window 80). Same pattern as carousel/
				gradient/the animation picker above; note: this also needs to be added to the toolBarString. 2026-10-01. --->

				<!--- Create the icon - fa-camera-retro matches a "cover photo" concept, distinct from the plain
				fa-image icon the "image" button already uses. --->
				editor.ui.registry.addIcon(
					'heroCoverImage',
					'<svg><span data-fa-symbol="heroCoverImage" class="fontAwesomeIcon fas fa-camera-retro">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('heroCoverImage', {
					text: '<i class="fontAwesomeIcon fas fa-camera-retro"></i>',
					tooltip: 'Cover Image',
					onAction: function (_) {
						createAdminInterfaceWindow(80,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});

				editor.ui.registry.addMenuItem('heroCoverImage', {
					icon: 'heroCoverImage',
					text: 'Cover Image',
					onAction: function () {
						createAdminInterfaceWindow(80,<cfoutput>#URL.optArgs#</cfoutput>);
					}
				});
			</cfif>
			<cfif includeCustomWindow>
				<!--- Create the icon --->
				editor.ui.registry.addIcon(
					'customWindow', 
					'<svg><span data-fa-symbol="customWindow" class="fontAwesomeIcon fa-regular fa-up-right-from-square">&nbsp;</span></svg>'
				);

				<!--- Custom dialogs that are invoked via the toolbar Custom window. This opens up a dialog to create a popup window (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('customWindow', {
					text: '<i class="fontAwesomeIcon fa-regular fa-up-right-from-square"></i>',
					tooltip: 'Create Custom Window',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new video upload window. The code for this window is the next switch block below. --->
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
			</cfif>			<cfif includeWebForm>
				<!--- Forms (2026-10-13): places one of the blog's forms in the post. Opens the Insert Form window (86), which inserts
				<div class="galaxieWebForm" data-webform="alias">[Form: Title]</div>; common/js/webForms.js shows the real form there. --->
				editor.ui.registry.addIcon(
					'webForm',
					'<svg><span data-fa-symbol="webForm" class="fontAwesomeIcon fa-regular fa-pen-to-square">&nbsp;</span></svg>'
				);
				editor.ui.registry.addButton('webForm', {
					text: '<i class="fontAwesomeIcon fa-regular fa-pen-to-square"></i>',
					tooltip: 'Insert Form',
					onAction: function (_) {
						createAdminInterfaceWindow(86);
					}
				});
				<!--- The real look of a form in the editor (2026-10-17, owner), instead of only "[Form: Title]": the form as visitors
				see it, from the same call the site uses (getWebFormForPage). The preview is data-mce-bogus="all", so TinyMCE never
				saves it: the post keeps its small placeholder. It can't be typed in; Insert > Form > Edit this form changes it. --->
				function galaxieShowFormPreviews(editor) {
					$.each(editor.dom.select("div.galaxieWebForm"), function(i, box) {
						if (editor.dom.select(".galaxieWebFormPreview", box).length) { return; }
						var alias = box.getAttribute("data-webform") || "";
						if (!alias) { return; }
						$.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getWebFormForPage", data: { alias: alias }, dataType: "json", cache: false })
							.done(function(response) {
								if (editor.dom.select(".galaxieWebFormPreview", box).length) { return; }
								var html = '<div class="galaxieWebFormPreviewLabel">Form: how visitors see it</div>' +
									(response && response.success === true ? response.html : '<p>This form is turned off or was deleted, so visitors don\'t see it.</p>');
								editor.dom.add(box, "div", { "class": "galaxieWebFormPreview", "data-mce-bogus": "all", "contenteditable": "false" }, html);
							});
					});
				}
				editor.on("init", function() {
					editor.dom.addStyle(
						".galaxieWebForm { font-size: 0; border: 1px dashed #bbb; border-radius: 6px; padding: 10px 14px; margin: 1em 0; }" +
						".galaxieWebForm:not(:has(.galaxieWebFormPreview)) { font-size: inherit; }" +
						".galaxieWebFormPreview { font-size: 1rem; cursor: default; }" +
						".galaxieWebFormPreview input, .galaxieWebFormPreview textarea, .galaxieWebFormPreview select, .galaxieWebFormPreview button { pointer-events: none; }" +
						".galaxieWebFormPreview input[type=text], .galaxieWebFormPreview input[type=email], .galaxieWebFormPreview input[type=tel], .galaxieWebFormPreview input[type=number], .galaxieWebFormPreview input[type=date], .galaxieWebFormPreview textarea, .galaxieWebFormPreview select { display: block; width: 100%; max-width: 30em; box-sizing: border-box; margin: 0.2em 0 0.6em 0; padding: 4px 6px; }" +
						".galaxieWebFormPreviewLabel { font-size: 0.8em; opacity: 0.65; margin-bottom: 0.5em; }"
					);
					galaxieShowFormPreviews(editor);
				});
				<!--- After the post loads, and after Insert Form adds one. --->
				editor.on("SetContent", function() { galaxieShowFormPreviews(editor); });
				editor.ui.registry.addMenuItem('webForm', {
					text: 'Form',
					icon: 'webForm',
					onAction: function () {
						createAdminInterfaceWindow(86);
					}
				});
			</cfif>
			<cfif includeBooking>
				<!--- Bookings (2026-10-14): places a booking widget in the post. Opens the Insert Booking window (93), which inserts
				<div class="galaxieBooking" data-booking="alias or *">[Booking: Name]</div>; common/js/bookings.js shows it there. --->
				editor.ui.registry.addIcon(
					'booking',
					'<svg><span data-fa-symbol="booking" class="fontAwesomeIcon fa-regular fa-calendar-check">&nbsp;</span></svg>'
				);
				editor.ui.registry.addButton('booking', {
					text: '<i class="fontAwesomeIcon fa-regular fa-calendar-check"></i>',
					tooltip: 'Insert Booking',
					onAction: function (_) {
						createAdminInterfaceWindow(93);
					}
				});
				<!--- The real look of a booking in the editor (2026-10-17, owner), instead of only "[Booking: Name]": the booking
				choices visitors see (name, length, price, description, Book), from the same call the site uses (getBookingWidget).
				The preview is data-mce-bogus="all", so TinyMCE never saves it: the post keeps its small placeholder, which the site,
				feeds and emails use as before. The placeholder's own text is hidden while the preview shows. --->
				var galaxieBookingPreviewTypes = {};
				function galaxieBookingPreviewText(value) { return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html(); }
				function galaxieBookingPreviewHtml(types, alias) {
					var html = '<div class="galaxieBookingPreviewLabel">' + (alias === "*" ? "Bookings" : "Booking") + ': how visitors see it</div>';
					var lastCategory = null;
					if (!types.length) {
						return html + '<p>No booking types to show yet. Add them under Bookings.</p>';
					}
					$.each(types, function(i, type) {
						var minutes = Number(type.durationMinutes) || 0;
						var length = minutes % 60 === 0 ? (minutes / 60) + (minutes === 60 ? " hour" : " hours") : (minutes > 60 ? Math.floor(minutes / 60) + " h " + (minutes % 60) + " min" : minutes + " minutes");
						var price = Number(type.price) > 0 ? (type.priceText || Number(type.price).toFixed(2)) : "Free";
						if (type.category !== lastCategory) {
							lastCategory = type.category;
							if (type.category) { html += '<h3>' + galaxieBookingPreviewText(type.category) + '</h3>'; }
						}
						html += '<div class="galaxieBookingPreviewType"><h4>' + galaxieBookingPreviewText(type.name) + '</h4>'
							+ '<div>' + galaxieBookingPreviewText(length + " \u00b7 " + price) + '</div>'
							+ (type.description ? '<p>' + galaxieBookingPreviewText(type.description).replace(/\n/g, "<br/>") + '</p>' : '')
							+ '<span class="galaxieBookingPreviewButton">Book</span></div>';
					});
					return html;
				}
				function galaxieShowBookingPreviews(editor) {
					$.each(editor.dom.select("div.galaxieBooking"), function(i, box) {
						if (editor.dom.select(".galaxieBookingPreview", box).length) { return; }
						var alias = box.getAttribute("data-booking") || "*";
						var show = function(types) {
							if (editor.dom.select(".galaxieBookingPreview", box).length) { return; }
							editor.dom.add(box, "div", { "class": "galaxieBookingPreview", "data-mce-bogus": "all", "contenteditable": "false" }, galaxieBookingPreviewHtml(types, alias));
						};
						if (galaxieBookingPreviewTypes[alias]) { show(galaxieBookingPreviewTypes[alias]); return; }
						$.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getBookingWidget", data: { alias: alias }, dataType: "json", cache: false })
							.done(function(response) {
								galaxieBookingPreviewTypes[alias] = response && response.success === true ? response.types : [];
								show(galaxieBookingPreviewTypes[alias]);
							});
					});
				}
				editor.on("init", function() {
					editor.dom.addStyle(
						".galaxieBooking { font-size: 0; border: 1px dashed #bbb; border-radius: 6px; padding: 10px 14px; margin: 1em 0; }" +
						".galaxieBooking:not(:has(.galaxieBookingPreview)) { font-size: inherit; }" +
						".galaxieBookingPreview { font-size: 1rem; cursor: default; }" +
						".galaxieBookingPreviewLabel { font-size: 0.8em; opacity: 0.65; margin-bottom: 0.5em; }" +
						".galaxieBookingPreview h3 { margin: 0.8em 0 0.3em 0; }" +
						".galaxieBookingPreviewType { margin: 0 0 1em 0; }" +
						".galaxieBookingPreviewType h4 { margin: 0 0 0.25em 0; }" +
						".galaxieBookingPreviewButton { display: inline-block; padding: 4px 14px; border-radius: 4px; background: #555; color: #fff; }"
					);
					galaxieShowBookingPreviews(editor);
				});
				<!--- After the post loads, and after Insert Booking adds one. --->
				editor.on("SetContent", function() { galaxieShowBookingPreviews(editor); });
				editor.ui.registry.addMenuItem('booking', {
					text: 'Booking',
					icon: 'booking',
					onAction: function () {
						createAdminInterfaceWindow(93);
					}
				});
			</cfif>				
			<cfif includeProduct>
				<!--- The shop (2026-10-21): places a product card in the post. Opens the Insert Product window (115), which inserts
				<div class="galaxieProduct" data-product="alias or *">[Product: Name]</div>; common/js/shop.js shows it there. --->
				editor.ui.registry.addIcon(
					'product',
					'<svg><span data-fa-symbol="product" class="fontAwesomeIcon fa-solid fa-cart-shopping">&nbsp;</span></svg>'
				);
				editor.ui.registry.addButton('product', {
					text: '<i class="fontAwesomeIcon fa-solid fa-cart-shopping"></i>',
					tooltip: 'Insert Product',
					onAction: function (_) {
						createAdminInterfaceWindow(115);
					}
				});
				editor.ui.registry.addMenuItem('product', {
					text: 'Product',
					icon: 'product',
					onAction: function () {
						createAdminInterfaceWindow(115);
					}
				});
				<!--- The real look of a product in the editor (2026-10-21), like a booking's: the card visitors see (picture, name, price,
				Add to cart), from the same call the site uses (getShopProducts). The preview is data-mce-bogus="all", so TinyMCE never
				saves it: the post keeps its small placeholder, which the site, feeds and emails use. --->
				var galaxieProductPreviewCache = {};
				function galaxieProductPreviewText(value) { return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html(); }
				function galaxieProductPreviewHtml(products, alias) {
					var html = '<div class="galaxieProductPreviewLabel">' + (alias === "*" ? "Every product" : "Product") + ': how visitors see it</div>';
					if (!products.length) { return html + '<p>Nothing to show: the product is hidden or no longer exists. Check it under Products.</p>'; }
					$.each(products, function(i, p) {
						html += '<div class="galaxieProductPreviewCard">'
							+ (p.imageUrl ? '<img src="' + galaxieProductPreviewText(p.imageUrl) + '" alt="">' : '')
							+ '<div><h4>' + galaxieProductPreviewText(p.name) + '</h4>'
							+ (p.description ? '<div>' + galaxieProductPreviewText(p.description) + '</div>' : '')
							+ '<div class="galaxieProductPreviewPrice">' + galaxieProductPreviewText(p.priceText) + '</div>'
							+ '<span class="galaxieProductPreviewButton">' + (p.soldOut ? 'Sold out' : 'Add to cart') + '</span></div></div>';
					});
					return html;
				}
				function galaxieShowProductPreviews(editor) {
					$.each(editor.dom.select("div.galaxieProduct"), function(i, box) {
						if (editor.dom.select(".galaxieProductPreview", box).length) { return; }
						var alias = box.getAttribute("data-product") || "*";
						var show = function(products) {
							if (editor.dom.select(".galaxieProductPreview", box).length) { return; }
							editor.dom.add(box, "div", { "class": "galaxieProductPreview", "data-mce-bogus": "all", "contenteditable": "false" }, galaxieProductPreviewHtml(products, alias));
						};
						if (galaxieProductPreviewCache[alias]) { show(galaxieProductPreviewCache[alias]); return; }
						$.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getShopProducts", data: { aliases: alias }, dataType: "json", cache: false })
							.done(function(response) {
								galaxieProductPreviewCache[alias] = response && response.success === true ? response.products : [];
								show(galaxieProductPreviewCache[alias]);
							});
					});
				}
				editor.on("init", function() {
					editor.dom.addStyle(
						".galaxieProduct { font-size: 0; border: 1px dashed #bbb; border-radius: 6px; padding: 10px 14px; margin: 1em 0; }" +
						".galaxieProduct:not(:has(.galaxieProductPreview)) { font-size: inherit; }" +
						".galaxieProductPreview { font-size: 1rem; cursor: default; }" +
						".galaxieProductPreviewLabel { font-size: 0.8em; opacity: 0.65; margin-bottom: 0.5em; }" +
						".galaxieProductPreviewCard { display: flex; gap: 12px; margin: 0 0 0.8em 0; }" +
						".galaxieProductPreviewCard img { width: 90px; height: 90px; object-fit: cover; border-radius: 4px; }" +
						".galaxieProductPreviewCard h4 { margin: 0 0 0.25em 0; }" +
						".galaxieProductPreviewPrice { margin: 0.3em 0; }" +
						".galaxieProductPreviewButton { display: inline-block; padding: 4px 14px; border-radius: 4px; background: #555; color: #fff; }"
					);
					galaxieShowProductPreviews(editor);
				});
				<!--- After the post loads, and after Insert Product adds one. --->
				editor.on("SetContent", function() { galaxieShowProductPreviews(editor); });
			</cfif>
			<cfif includeVideoUpload>
				<!--- Create the icon --->
				editor.ui.registry.addIcon(
					'videoUpload', 
					'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-file-video">&nbsp;</span></svg>'
				);

				<!--- Custom dialogs that are invoked via the toolbar Video upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('videoUpload', {
					text: '<i class="fontAwesomeIcon fas fa-file-video"></i>',
					tooltip: 'Upload Video',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new video upload window. The code for this window is the next switch block below. --->
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

				<!--- Create the icon --->
				editor.ui.registry.addIcon(
					'webVttUpload', 
					'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-closed-captioning">&nbsp;</span></svg>'
				);

				<!--- WebVTT file upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('webVttUpload', {
					text: '<i class="fontAwesomeIcon fas fa-closed-captioning"></i>',
					tooltip: 'Upload WebVTT file for video captioning',
					id: 'webVttUpload',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new video upload window. The code for this window is the next switch block below. --->
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

				<!--- Create the icon --->
				editor.ui.registry.addIcon(
					'videoCoverUpload', 
					'<svg><span data-fa-symbol="videoUpload" class="fontAwesomeIcon fas fa-file-image">&nbsp;</span></svg>'
				);

				<!--- WebVTT file upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('videoCoverUpload', {
					text: '<i class="fontAwesomeIcon fas fa-file-image"></i>',
					tooltip: 'Upload video image cover',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new image upload window. The code for this window is the next switch block below. --->
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
				<!--- Custom dialogs that are invoked via the toolbar File upload. This opens up an uppy dialog (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('fileUpload', {
					icon: "upload",
					tooltip: 'Upload File',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new file upload window. The code for this window is the next switch block below. --->
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
				<!--- Map Create the icon --->
				editor.ui.registry.addIcon(
					'map',
					'<svg><span data-fa-symbol="map" class="fontAwesomeIcon fas fa-globe">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('map', {
					text: '<i class="fontAwesomeIcon fas fa-globe"></i>',
					tooltip: 'Create a map',
					onAction: function (_) {
						$('#image').val('');
						<!--- See if a current map is selected. If it is, pass along the mapid in order to edit a current map --->
						var selectedContent = tinymce.activeEditor.selection.getNode();
						<!--- Get the map id. Note: tinymce appends 'mce-p-' to the data-map-id. --->
						mapId = $(selectedContent).attr("data-mce-p-data-id");
						<!--- Open up a new image upload window. The code for this window is the next switch block below. --->
						createAdminInterfaceWindow(19,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>,mapId);
					}
				});

				<!--- Add the menu item --->
				editor.ui.registry.addMenuItem('map', {
					icon: 'map',
					text: 'Map',
					onAction: function () {
						<!--- See if a current map is selected. If it is, pass along the mapid in order to edit a current map --->
						var selectedContent = tinymce.activeEditor.selection.getNode();
						<!--- Get the map id. Note: tinymce appends 'mce-p-' to the data-map-id. --->
						mapId = $(selectedContent).attr("data-mce-p-data-id");
						<!--- Open up a new image upload window. The code for this window is the next switch block below. --->
						createAdminInterfaceWindow(19,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>,mapId);
					}
				});

				<!--- Map routing Create the icon --->
				editor.ui.registry.addIcon(
					'mapRouting',
					'<svg><span data-fa-symbol="mapRouting" class="fontAwesomeIcon fas fa-location-arrow">&nbsp;</span></svg>'
				);

				<!--- Create the button (note: this also needs to be added to the toolBarString) --->
				editor.ui.registry.addButton('mapRouting', {
					text: '<i class="fontAwesomeIcon fas fa-location-arrow"></i>',
					tooltip: 'Map Directions between 2 or more points',
					onAction: function (_) {
						$('#image').val('');
						<!--- Open up a new map window. The code for this window is the next switch block below. Note: we are also sending the selectorId to determine what interface we are on --->
						createAdminInterfaceWindow(20,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>);
					}
				});

				<!--- Add the menu item --->
				editor.ui.registry.addMenuItem('mapRouting', {
					icon: 'mapRouting',
					text: 'Map Directions',
					onAction: function () {
						<!--- Note: we are also sending the selectorId to determine what interface we are on --->
						createAdminInterfaceWindow(20,<cfoutput>#URL.optArgs#,'#selectorId#'</cfoutput>);
					}
				});
			</cfif>

				try {
					<!--- Set an data-mediaId attribute. We will insert the value when the image was succesfully uploaded and the mediaId was returned from the server. We saved the mediaId into the imageId hidden input field when the server returned data. Here, we are taking that value and inserting the mediaId. --->
					e.element.setAttribute("data-mediaid", $("#<cfoutput>#imageMediaIdField#</cfoutput>").val()); 
					<!--- Wrap the image with the class that we want --->
					if (!$('.<cfoutput>#imageClass#</cfoutput>').length){
						$(e.element).wrap("<div class='<cfoutput>#imageClass#</cfoutput>'></div>");
					}
					<!--- Important note: in order to be able to do other intented actions, such as editting an image, we must put a return here. --->
					return true;
				} catch {
					return true;
				}	
			},
			<!--- Force tinymce to use the image path that I return it insted of changing the image url --->
			relative_urls: false,
			remove_script_host: false,
			convert_urls: true,
			<!--- What is the URL on the server side that will save this image? This URL will return a json string indicating the full path of the image. --->
			<!--- images_upload_url does not set a header on mobile devices. This causes an 'tinymce image upload failed due to a xhr transport error. Code 0' error when using an iPhone. When using mobile, we need to use a custom function that is used with the images_upload_handler argument instead. --->
			<!--- images_upload_url: 'https://gregorysblog.org/common/cfc/ProxyController.cfc?method=uploadImage', --->
			images_upload_handler: imageUploadHandler,
			<!--- Custom function that is called when we embed videos using the media plugin. We need to use this for enclosures in order to save the URL to the database. --->
			media_url_resolver: function (data, resolve/*, reject*/) { 
				<!--- Do not try to inspect the events here, there are thousands of them and you're going to crash the browser. --->

				<!--- Upload post related media --->
				jQuery.ajax({
					type: 'post', 
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveExternalMediaEnclosure&template=tinyMce',
					data: { // arguments
						csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
						<!--- Pass the mediaId saved in the mediaId hidden form if it is available --->
						mediaId: $("#<cfoutput>#imageMediaIdField#</cfoutput>").val(),
						externalUrl: data.url,
						<!--- Many interfaces don't have the post ID in the URL --->
						postId: <cfif structKeyExists(URL,"optArgs") and len(URL.optArgs)><cfoutput>#URL.optArgs#</cfoutput><cfelse>''</cfif>,
						mediaType: 'video',
						<!--- Get the videoid and provider using the get-video-id javascript library. This script should be included on the UI that calls this template --->
						providerVideoId: getVideoId(data.url).id,
						videoProvider: getVideoId(data.url).service,
						selectorId: '<cfoutput>#selectorId#</cfoutput>'
					},
					dataType: "json",
					<!--- success: saveWebVttResponse, // calls the result function. --->
					error: function(ErrorMsg) {
						console.log('Error' + ErrorMsg);
					}
				<!--- Extract any errors. This is a new jQuery promise based function as of jQuery 1.8. --->
				}).fail(function (jqXHR, textStatus, error) {

					<!--- The full response is: jqXHR.responseText, but we just want to extract the error. --->
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveExternalMediaEnclosure function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning. You can also specify height.
						).done(function () {
						<!--- Do nothing --->
					});		
				});
			<cfif selectorId eq 'enclosureEditor'>	
				<!--- Refresh the enclosure media preview- pass in the postId --->
				reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>);
				<!--- Remove previous enclosure editor content --->
				tinymce.activeEditor.setContent('');
			</cfif>
				<!--- For the external video preview, let tinymce resolve the URL natively (this is a tinymce function). When we display the video from the database plyr will take over (Note: this does not remove prior content) --->
				resolve({ html: '' });
			},
			<!--- Turn off the 'powered by Tiny' advertisement at the bottom of the editor --->
			branding: false
		});
						
		<!--- Print the current menu (useful to get the current menu items for a given editor): console.log(tinyMCE.activeEditor.ui.registry.getAll().menuItems); --->
		
		function imageUploadHandler(blobInfo, success, failure) {
			var xhr, formData;

			xhr = new XMLHttpRequest();
			xhr.withCredentials = true;
			xhr.open('POST', "<cfoutput>#imageHandlerUrl#</cfoutput>");
			<!--- xhr.setRequestHeader('Content-Type', 'multipart/form-data;'); // manually set header --->

			<!--- Set a timeout for Safari on mobile --->
			xhr.timeout = 50000; // time in milliseconds (50 seconds)
			<!--- Onload event --->
			xhr.onload = function() {
				var json;

				if (xhr.status != 200) {
					failure("HTTP Error: " + xhr.status);
					return;
				}

				<!--- Extract the data from the json array. There should be the location and the new media id. Note: we don't need to loop thorugh anything as there is only one record in the response array. --->
				var json = JSON.parse(xhr.responseText);
				var location = json.location; // or json["location"]
				var mediaId = json.mediaId; // or json["mediaId"]
				var mediaActions = json.mediaActions; // This is only present with image enclosures at this time
				
				<!--- Remove and save the media id into the imageMediaId hidden form field. We need to retain the mediaId in order to append it to the image to associate the image to the record of the database. We can't perform any further action on the new source code here as the image has not yet been placed into the editor and is not available in the DOM. Remove the prior mediaId --->
				$("#<cfoutput>#imageMediaIdField#</cfoutput>").val('');
				<!--- And save it... --->
				$("#<cfoutput>#imageMediaIdField#</cfoutput>").val(mediaId);
							
			<cfif selectorId neq 'imageUploadEditor'>
				<!--- Raise a dialog indicating the actions taken --->
				var mediaActionHtmlList = "The images have been optimized for social media sharing and the following images have been created:<br/><ul>";
				<!--- Loop through the comma separated list and get each action --->
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
				
				<!--- Note: we can't reset the content of the editor here as it would remove the current image when editing is taking place. Call the tinymce success function and pass along the location to populate the editor. This is a native tinymce function. --->
				success(location);
				
				<cfif selectorId eq 'enclosureEditor'>
				try {
					<!--- When the enclosureEditor is being used, update the enclosure thumbnail image. --->
					if (location.includes(".png") || location.includes(".gif") || location.includes(".jpg") || location.includes(".webp")){
						var thumbnailImage = document.getElementById("thumbnailImage");
						thumbnailImage.src = location;
					}
				} catch(e) {
					<!--- Do nothing --->
				}
				</cfif>
			};

			xhr.onabort = function (e) {
				<!--- XMLHttpRequest aborted. --->
				alert('Process aborted');
			};

			xhr.onerror = function (e) {
				<!--- XMLHttpRequest errored. --->
				alert('Error: ' + xhr.status);
			};

			xhr.ontimeout = function (e) {
				<!--- XMLHttpRequest timed out. --->
				tinymce.activeEditor.windowManager.close();
			};

			formData = new FormData();
			<!--- The file is the editor field --->
			formData.append('file', blobInfo.blob(), blobInfo.filename());
			<!--- The enclosure editor's quality slider (imageQualitySlider) isn't present on every screen this
			handler serves, so check before reading it - uploadImage() falls back to Blog Options' own default
			quality when this isn't sent at all. Restored 2026-09-27: this dropped out when the Uppy pipeline
			(paused - see enclosureImageEditor.cfm) took over reading the slider for its own upload path instead. --->
			if ($("#imageQualitySlider").data("kendoSlider")) {
				formData.append('quality', $("#imageQualitySlider").data("kendoSlider").value());
			}

			xhr.send(formData);
		}//function imageUploadHandler(blobInfo, success, failure) {
		
		<!--- Displays the editors. Used for debugging --->
		function displayEditorNames(){
			if (!tinyMCE.editors.length) {
				alert('none');
			}
			for (i=0; i < tinyMCE.editors.length; i++){
				var content = tinyMCE.editors[i].getContent();
				alert('Editor-Id(' + tinyMCE.editors[i].id + '):' + content);
			}
		}
		
		<!--- Another way of setting content- but it also does not solve the problems that I am having as the editors are not defined: for(i=0; i < tinymce.editors.length; i++){ alert('inserting content into ' + tinymce.editors[i]) tinymce.editors[i].setContent('content'); } --->
	
	</script>
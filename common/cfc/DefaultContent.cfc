<cfcomponent displayName="DefaultContent" output="false" hint="Sets the default website content for preview when designing themes"> 
	
	<cffunction name="getDefaultContentPreview" access="remote" output="false"
			hint="Gets the default content when manually designing content templates using the administrator. This is not used in the default Galaxie Blog code, but used to generate the manual content suggested when using the content preview window.">
		<cfargument name="getTheme" required="yes" default="" hint="Pass in the getTheme HQL query object. This should be available when invoking this function">		
		<cfargument name="contentTemplate" required="yes" default="" hint="Pass in the template that you want to preview">
		<cfargument name="isMobileDevice" required="no" default="false" hint="Pass in whether to display the code for mobile devices">
			
		<!---<cfdump var="#getTheme#">--->
			
		<!--- Get the Kendo Theme --->
		<cfset kendoTheme = getTheme[1]["KendoTheme"]>
		<cfset modernTheme = getTheme[1]["ModernThemeStyle"]>
		<cfset darkTheme = getTheme[1]["DarkTheme"]>
			
		<!--- Set the button styles. These are used on many of the interfaces --->
		<cfif kendoTheme contains 'material'>
			<cfif isMobileDevice>
				<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
			<cfelse>	
				<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
			</cfif>
		<cfelse><!---<cfif kendoTheme contains 'material'>--->
			<cfif isMobileDevice>
				<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
			<cfelse>	
				<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
			</cfif>
		</cfif><!---<cfif kendoTheme contains 'material'>--->
					
		<!--- The icon buttons are smaller as there is no text, just an icon such as a facebook link --->
		<cfif kendoTheme contains 'material'>
			<cfif isMobileDevice>
				<cfset kendoIconButtonStyle = "width:45px; font-size:0.55em;">
			<cfelse>	
				<cfset kendoIconButtonStyle = "width:45px; font-size:0.70em;">
			</cfif>
		<cfelse><!---<cfif kendoTheme contains 'material'>--->
			<cfif isMobileDevice>
				<cfset kendoIconButtonStyle = "width:45px; font-size:0.75em;">
			<cfelse>	
				<cfset kendoIconButtonStyle = "width:55px; font-size:0.875em;">
			</cfif>
		</cfif><!---<cfif kendoTheme contains 'material'>--->
			
		<!--- Note: some of the code is being stripped by tinyMce and the code below may be a little bit different than the code in production --->
		<cfif findNoCase('customHeaderHtml', arguments.contentTemplate)>
			
			<cfif len(getTheme[1]["CustomHeaderHtml"])>
				<cfset customHeaderHtml = getTheme[1]["CustomHeaderHtml"]>
			<cfelse>
				<cfset customHeaderHtml = ''/>
			</cfif>
			<cfsavecontent variable="contentPreview"><cfoutput>#customHeaderHtml#</cfoutput></cfsavecontent>
			
		<cfelseif findNoCase('favIconHtml', arguments.contentTemplate)>	
			
			<cfif len(getTheme[1]["FavIconHtml"])>
				<cfset favIconHtml = getTheme[1]["FavIconHtml"]>
			<cfelse>
				<cfset favIconHtml = ""/>
			</cfif>
			
			<cfsavecontent variable="contentPreview"><cfoutput>#favIconHtml#</cfoutput></cfsavecontent>
		
		<cfelseif findNoCase('compositeHeader', arguments.contentTemplate)>
		
			<!--- Global theme properties --->
			<cfset kendoTheme = getTheme[1]["KendoTheme"]>
			<cfset selectedTheme = getTheme[1]["SelectedTheme"]>
			<!--- Menu theme properties --->
			<cfset topMenuAlign = getTheme[1]["TopMenuAlign"]>
			<!--- Generic Logo Properties.--->
			<!--- Both desktop and mobile logos. The mobile logo should be smaller than the desktop obviously. --->
			<cfset logoImageMobile = application.baseUrl & getTheme[1]["LogoImageMobile"]>
			<cfset logoMobileWidth = getTheme[1]["LogoMobileWidth"]>
			<cfset logoImage = application.baseUrl & getTheme[1]["LogoImage"]>

			<!--- Padding. The most important setting here is logoPaddingLeft which gives space between the logo and the blog text and menu. I have designed the logo image with padding on the left to take care of this without applying this setting. Padding right and bottom can be used to fine tune the placement of the logo but I am not using them currently in my theme designs. --->
			<cfset logoPaddingTop = getTheme[1]["LogoPaddingTop"]>
			<cfset logoPaddingRight = getTheme[1]["LogoPaddingRight"]>
			<cfset logoPaddingLeft = getTheme[1]["LogoPaddingLeft"]>
			<cfset logoPaddingBottom = getTheme[1]["LogoPaddingBottom"]>
			<!--- Logo image check (there may be one common logo for all things). --->
			<cfif isMobileDevice>
				<cfset logoSourcePath = "#logoImageMobile#">
			<cfelse>
				<cfset logoSourcePath = "#logoImage#">
			</cfif>
			<!--- The divider between the header and body --->
			<cfset headerBodyDividerImage = application.baseUrl & getTheme[1]["HeaderBodyDividerImage"]>

			<!--- The following code is identitical to the topMenuHtml.cfm template --->
			<cfset menuDivName = "topMenuPreview">
				
			<cfsavecontent variable="contentPreview">
				<header>
				<div id="fixedNavHeader">
					<cfsilent><!--- 
					Needed arguments: 
					pageId: using the pageId found in the root index.cfm template
					menuDivName: either topMenu or fixedNavMenu
					isMobileDevice (true/false). This is typically session.isMobile, but on the preview it is a variable in order to determine what to display.
					This menu is used on two different div's, and each div has a different menu script for mobile and desktop. The topMenu is invoked when the page initially loads and is at the top of the page underneath the title, and the fixedNavMenu is fixed to the very top of the page when the user scrolls down the page. The menu's should be identical but there are two different scripts.
					We need to set a numeric value to determine what div is calling the toggleSideBarPanel javascript menu as our "javascript:toggleSideBarPanel('divName'); statement is failing with a single qouted string. Send 1 for topManu, and 2 for the fixedNavMenu.
					--->

					<!--- Get the parent categories --->
					<cfset parentCategories = application.blog.getCategories(parentCategory=1)>
					<!--- Get the themes. This is a HQL array --->
					<cfset themeNames = application.blog.getThemeNames()>

					<!--- We are not going to cache this template. There would be no gain due to the number of conditional blocks requred.--->

					<!--- Optional header composite zone --->
					</cfsilent>
				</div>
				<!-- Include the display -->
				<table id="headerContainer" cellpadding="0" cellspacing="0" align="center" class="flexHeader headerBackground">
				  <tr>
					<td>
					<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
					<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>">
						<!-- If you want the blog title lower, increase the tr height below and decrease the tr height in the *next* row to keep everything aligned. -->
						<tr height="50px;" valign="bottom">
							<!-- Give sufficient room for a logo. This row will bleed into the next row (rowspan="2") -->
							<td id="logo" name="logo"  valign="middle" rowspan="2">
								<!--- elimnate hardcoded width below. change logo to around 80 to 120px. maybe make new row.--->
								<cfoutput><cfif application.parentSiteLink neq ''><a href="#application.parentSiteLink#" aria-label="#application.parentSiteName#"></cfif><img src="#logoSourcePath#" style="padding-left: #logoPaddingLeft#px;" align="left" valign="center" alt="Header Logo" /><cfif application.parentSiteLink neq ''></a></cfif></cfoutput>
							</td>
							<td id="blogNameContainer">
								<!-- The blog name may not always be displayed. The blog name maybe in the logo for example. -->
								<cfif getTheme[1]["DisplayBlogName"]><cfoutput>#encodeForHTML(application.BlogDbObj.getBlogTitle())#</cfoutput></cfif>
							</td>
						</tr>
						<tr>
						  <td id="topMenuContainer" height="55px"><!-- Holds the menu. -->
							<cfsilent>
							<!---//************************************************************************************************
										Top menu javascript (controls the menu at the top of the page)
							//*************************************************************************************************--->
							</cfsilent>
							<!---<cfset divName = "topMenu"> This is set twice--->
							<cfinclude template="#application.baseUrl#/includes/templates/content/header/topMenu.cfm">
						 </td>
					  </tr>
					</table>
					</td>
					<td>
					</td>
				  </tr>
				  <tr>
					<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
				  </tr>
				</table>
			</cfsavecontent>
					
		<cfelseif findNoCase('navigationMenu', arguments.contentTemplate)>
				
			<cfparam name="menuDivName" default="">
			<cfparam name="layerNumber" default="">

			<!--- Get the parent categories --->
			<cfset parentCategories = application.blog.getCategories(parentCategory=1)>
			<!--- Get the themes. This is a HQL array --->
			<cfset themeNames = application.blog.getThemeNames()>
			
			<cfsavecontent variable="contentPreview">

				<!--- Include the content template for the navigation script --->
				<ul id="menuDivName" class="topMenu">
					<li class="toggleSidebarPanelButton">
						<a href="javascript:toggleSideBarPanel(layerNumber)" aria-label="Menu"><span class="fa fa-bars"></span></a>
					</li>
					<li>
						Menu
						<ul>
							<!--- Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text. --->
							<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToTop();"><span class="fa fa-arrow-circle-up"></span> Top</li></cfif>
							<li><a href="<cfoutput>#application.siteUrl#</cfoutput>"><cfoutput>#encodeForHTML(application.BlogDbObj.getBlogTitle())#</cfoutput></a></li>
						<cfif len(application.parentSiteName)>
							<li><a href="<cfoutput>#application.parentSiteLink#</cfoutput>"><cfoutput>#application.parentSiteName#</cfoutput></a></li>
						</cfif>
							<li><a href="javascript:createAddCommentSubscribeWindow('', 'contact', <cfoutput>#isMobileDevice#</cfoutput>);">Contact</a></li>
							<!--- or <li><a href="http://www.gregoryalexander.com/blog/?contact">Contact</a></li>--->
							<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToBottom();"><span class="fa fa-arrow-circle-down"></span> Bottom</li></cfif>
						</ul>
					</li>
					<li>
						Categories
						<ul>
						<cfloop from="1" to="#arrayLen(parentCategories)#" index="i">
							<cfsilent>
							<cftry>
								<!--- Extract the data --->
								<cfset parentCategoryId = parentCategories[i]["CategoryId"]>
								<cfset parentCategory = parentCategories[i]["Category"]>
								<cfset parentCategoryLink = application.blog.makeCategoryLink(parentCategoryId)>
								<cfset parentCategoryPostCount = parentCategories[i]["PostCount"]>
								<cfcatch type="any">
									<cfset parentCategoryId = "">
									<cfset parentCategory = "">
									<cfset parentCategoryLink = "">
								</cfcatch>
							</cftry>
							</cfsilent>
							<cfif isNumeric(parentCategoryPostCount) and parentCategoryPostCount gt 0><li><cfoutput><a href="#parentCategoryLink#">#parentCategory#</a></cfoutput></li></cfif>
						</cfloop>
						</ul>
					</li>
					<li>
						About
						<ul>
							<li><a href="javascript:createAboutWindow(1);">About this Blog</a></li>
							<li><a href="javascript:createAboutWindow(2);">Biography</a></li>
							<li><a href="javascript:createAboutWindow(3);">Download</a></li>
						</ul>
					</li>
					<!--- Don't include the themes on mobile devices --->
					<cfif !URL.otherArgs1>
					<li>
						Themes
						<ul>
							<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><li><a href="#application.baseUrl#?theme=#themeNames[i]['ThemeAlias']#">#themeNames[i]['ThemeName']#</a></li></cfoutput></cfloop>
						</ul>
					</li>
					</cfif>
					<li class="siteSearchButton">
						<cfsilent>
						<!--- Set the font size of the search and menu icons. This logic sets the icons to be (2 for desktop, 0 for mobile) tenths of a percentage less than the font size of the menu font's above. --->
						<cfif kendoTheme eq 'office365'>
							<cfif isMobileDevice>
								<cfset searchAndMenuFontSize = ".75em">
							<cfelse>
								<cfset searchAndMenuFontSize = ".8em">
							</cfif>
						<cfelse>
							<cfif isMobileDevice>
								<cfset searchAndMenuFontSize = "1em">
							<cfelse>
								<cfset searchAndMenuFontSize = ".8em">
							</cfif>
						</cfif>
						</cfsilent>
						<a href="javascript:createSearchWindow();" aria-label="Search"><span class="fa fa-search" style="font-size:<cfoutput>#searchAndMenuFontSize#</cfoutput>"></span></a>
					</li>
				</ul>

			</cfsavecontent>
									
		<cfelseif findNoCase('bioWindow', arguments.contentTemplate)>
			
			<!-- FontAwesome 6.1 -->
			<script>
				$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', 'https://use.fontawesome.com/releases/v6.1.0/css/all.css') );
			</script>
			
			<!--- Get the author from the user table --->
			<cfset authorData = application.blog.getUser(userId=session.userId, includeSecurityCredentials=false)>
			<cfsavecontent variable="contentPreview">
				
				<table align="center" class="k-content" width="100%" cellpadding="5" cellspacing="5" border="0">
					<tr>
						<td width="150">
							<img src="<cfoutput>#authorData[1]['ProfilePicture']#</cfoutput>" title="<cfoutput>#authorData[1]['FullName']#</cfoutput> Profile" alt="<cfoutput>#authorData[1]['FullName']#</cfoutput> Profile" border="0" class="avatar avatar-64 photo" height="135" width="135" align="left" style="padding: 10px">
						</td>
						<td>
							<div class="author-bio k-content flexItem">
								<h3 class="topContent"><cfoutput>#authorData[1]['FullName']#</cfoutput></h3>
							</div>
							<div class="author-bio k-content flexItem">
							<cfif structKeyExists(authorData[1], "FacebookUrl") and len(authorData[1]['FacebookUrl'])>
								<a href="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" class="k-content"><button id="facebookUrl" aria-label="facebook" class="k-button" style="#kendoIconButtonStyle#">
									&nbsp;<i class="fa-brands fa-facebook"></i>&nbsp;
								</button></a>
							</cfif><cfif structKeyExists(authorData[1], "LinkedInUrl") and len(authorData[1]['LinkedInUrl'])>
								<a href="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" class="k-content"><button id="linkedInUrl" aria-label="linkedIn" class="k-button" style="#kendoIconButtonStyle#">
									&nbsp;<i class="fa-brands fa-linkedin"></i>&nbsp;
								</button></a>
							</cfif><cfif structKeyExists(authorData[1], "InstagramUrl") and len(authorData[1]['InstagramUrl'])>
								<a href="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="instagramUrl" aria-label="instagram" class="k-button" style="#kendoIconButtonStyle#">
									&nbsp;<i class="fa-brands fa-instagram"></i>&nbsp;
								</button></a>
							</cfif><cfif structKeyExists(authorData[1], "TwitterUrl") and len(authorData[1]['InstagramUrl'])>
								<a href="<cfoutput>#authorData[1]['TwitterUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="twitterUrl" aria-label="twitter" class="k-button" style="#kendoIconButtonStyle#">
									&nbsp;<i class="fa-brands fa-twitter"></i>&nbsp;
								</button></a>
							</cfif><cfif structKeyExists(authorData[1], "DisplayEmailOnBio") and authorData[1]["DisplayEmailOnBio"]>
								<a href="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" aria-label="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" class="k-content"><button id="email" aria-label="email" class="k-button" style="#kendoIconButtonStyle#">
									&nbsp;<i class="fa-solid fa-envelope"></i>&nbsp;
								</button></a>
							</cfif>
							</div>
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<p>I have over 23 years of web development experience. After serving in the Navy- I went to college in the mid-90s and obtained several degrees in computer graphics and multimedia authoring. My timing was terrific; as soon as I had graduated, the web exploded onto the scene.</p>

							<p>I started developing with ColdFusion 2.5, which was the original ‘middle-ware’ tool to drive database-driven websites. Later, I also learned classic ASP. Soon, I became the lead web developer at Boeing’s Everett site and helped to build the largest intranet site in the world at the time.</p>

							<p>I moved on to the University of Washington Genome Center, where I worked in Bioinformatics and built collaborative web applications for the Human Genome Project. After completing the Human Genome Project in the mid-2000s, I started developing critical web applications for Harborview Medical Center.</p>

							<p>At Harborview, I developed and maintained a web application used in every hospital ICU for multiple states to deliver critical care patients to the nearest hospital en route. If I had made a bug, someone could have very well died. I am happy to say I never made a bug on that production site there!</p>

							<p>Currently, I am working at the University of Washington Medical developing web applications used at various hospitals. I am working on developing this application for the open-source community in my off time.</p>

							<p>My passions include photography, cooking, building and engineering mountain trail systems (I started building trail systems as a kid), long road trips, and hiking!</p>
							
						</td>
					</tr>
				</table>
				<br/>
				
			</cfsavecontent>
			
		<cfelseif findNoCase('downloadWindow', arguments.contentTemplate)>
			
			<cfsavecontent variable="contentPreview">
				
				<div class="k-content">
					<p><b>License</b></p>
					<p>Galaxie Blog, and its associated software, is governed by the <a href="https://www.apache.org/licenses/LICENSE-2.0.html">Apache 2.0 license</a>. 
					Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.</p>

					<p><b>Credits</b></p>
					<p>This blog would not have been possible without <a href="http://www.coldfusionjedi.com">Raymond Camden</a>. Raymond developed <a href="http://www.blogcfc.com/views/main/docs/index.htm">BlogCfc</a>, on which this platform was originally based. Raymond is a ColdFusion enthusiast who authored thousands of ColdFusion related posts on the internet. Like every senior ColdFusion web developer; I have found his posts invaluable and have based many of my own ColdFusion libraries based upon his approach.</p>

					<p><strong>Getting the software</strong></p>
					<ol>
					<li>Galaxie Blog can be downloaded from the <a title="Galaxie Blog Git Hub Repository" href="https://github.com/gregoryalexander77/Galaxie-Blog" target="_blank" rel="noopener">Galaxie Blog Git Hub Repository</a>.</li>
					</ol>

					<button type="button" class="k-button k-primary" style="#kendoButtonStyle#">
						<i class="fab fa-github" style="color:whitesmoke"></i>&nbsp;&nbsp;<a href="https://github.com/gregoryalexander77/gregorysBlog" style="color:whitesmoke">Github Project</a>
					</button>

					<p><b>Installation</b></p>
					<li>You must have a ColdFusion installed on a server.
					<ul>
					<li>Your web server must have ColdFusion installed. Galaxie Blog has been tested on ColdFusion 2016, 2018, 2021 and 2023 (2023.0.07.330663).</li>
					<li>Theoretically, the blog may support any ColdFusion edition starting from ColdFusion 9, however, your mileage may vary.</li>
					<li>We have successfully tested against Apache, TomCat and IIS.</li>
					<li>We have not yet tested the blog on Lucee, an open-source version of Adobe ColdFusion. We intend on supporting Lucee in the future.</li>
					<li>There are many ISPs which offer ColdFusion servers for as low as 12 dollars a month. I use Media3.net, and they have been terrific. Search the web for ColdFusion hosting to find out more.</li>
					</ul>
					</li>
					<li>Once downloaded, upload the entire contents into your desired location on a web server
					<ul>
					<li>You can install the contents in the root, or in folder in the root directory of your server.</li>
					<li>We have tested the blog in the root, and in 'blog' and 'galaxie' folders.</li>
					</ul>
					</li>
					<li>You must have a database that is accessible to the webserver. The blog was <strong><em>should</em></strong> support the following databases, however, we have only tested the blog using SQL Server and various flavors of MySql:
					<ul>
					<li>Microsoft SQL Server</li>
					<li>DB2</li>
					<li>DB2AS400</li>
					<li>DB2OS390</li>
					<li>Derby</li>
					<li>Informix</li>
					<li>MySQL</li>
					<li>MySQLwithInnoDB</li>
					<li>MySQLwithMyISAM</li>
					<li>Oracle8i</li>
					<li>Oracle9i</li>
					<li>Oracle10g</li>
					<li>PostgreSQL</li>
					<li>Sybase</li>
					<li>SybaseAnywhere</li>
					</ul>
					</li>
					<li>Create the database to install Galaxie Blog in.
					<ul>
					<li>You may install Galaxie Blog using your current database, however, you need to make sure that there are no table name conflicts. We will document the database schema in later blog posts.</li>
					<li>We have tested Galaxie Blog using our original BlogCFC database with no conflicts.</li>
					</ul>
					</li>
					<li>Create a ColdFusion DSN for the database that you intend to install Galaxie Blog in.</li>
					</ol>
					<p><strong>Enable Woff and Woff2 Font Support on the Webserver<br></strong>Galaxie Blog uses web fonts for typography and needs web font mime types set up on the webserver. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. If the server does not support these mime types certain textual elements will not be displayed.&nbsp;</p>
					<ol>
					<li>.woff (use font/woff as the mime type).</li>
					<li>.woff2 (use font/woff2 as the mime type).</li>
					</ol>
					<p><strong>Installing the software</strong></p>
					<ol>
					<li>Migrate to the URL of your uploaded blog and the blog should automatically open the installer.
					<ul>
					<li>For example, if you uploaded the files in the root directory go to <a href="http://yourdomain.com/">http://yourdomain.com/</a>.</li>
					<li>If you uploaded to a blog directory in your root, go to <a href="http://yourdomain.com/blog/,">http://yourdomain.com/blog/,</a> etc.</li>
					</ul>
					</li>
					<li>The installer will guide you and ask you to enter information, such as your URL, blog name, and other information.&nbsp;</li>
					<li>The installer is a 7 step process. Each screen has may provide information and ask you to hit the next button or have multiple questions. It should not take more than 5 minutes to fill out.</li>

					<li>Be sure to write down your chosen user name and password. You will need to retain this information. Galaxie Blog does not retain passwords- the passwords are hashed using the strongest publicly available encryption process and they cannot be recovered.</li>
					<li>Once you are done, the installer will automatically create the database and import the needed data. In the final step, it may take a while for the software to be installed. If there is a time-out error, refresh the browser and the installation should continue.</li>
					<li>Once installed, you should see your new blog with a 'No Entries' message on the front page. You will not see any blog posts until you make them using the administrative site, see below.</li>
					</ol>

					<p>If you use this blog, I hope that you will give me credit and link back to <a href="http://www.gregoryalexander.com">www.gregoryalexander.com</a>, preferably by leaving this content found under 'about' - 'download' link intact in the menu. I also ask that you inform me if you find bugs, or have any suggestions.</p>

					<p>Copyright 2024 Gregory Alexander</p>

					<p>Version <cfoutput>#application.blog.getVersion()#</cfoutput> April 12th 2024.</p>
				</div>
			</cfsavecontent>
						  
		<cfelseif findNoCase('aboutWindow', arguments.contentTemplate)>	
			
			<cfsavecontent variable="contentPreview">
				
				<div class="k-content">
					<img src="<cfoutput><cfif URL.otherArgs1 eq 1>#application.baseUrl#/images/logo/gregorysBlogMobile.png<cfelse>#application.baseUrl#/images/logo/gregorysBlogLogo.gif</cfif></cfoutput>" id="about" align="left" alt="Gregory Alexander" style="margin: 15px;"/>

					<p style="display: none;">About this blog.</p>

					<p>Question for the seasoned developer- when was the last time that you actually bought a computer programming book? If you’re like me, it has been a long time ago when we had different stacks of different books filled with sticky notes laying next to us. Instead, I rely upon the web, and blogs like this to solve my programming needs. I often joke that my actual job is using search engines as a living. Often, meeting a goal depends on using the right search phrases to find an answer to the current challenge that I am facing. Developing this blog is one way that I can try to give back to this community.</p>

					<p><b>Galaxie Blog</b> is intended to be the most beautiful and functional open sourced ColdFusion based blog in the world. While I can’t go toe to toe with Wordpress functionality, I believe that Gregory’s Blog competes with Wordpress in core functionality, especially with its abundant theme related features. This blog was built from the ground up to be eminently themeable. Galaxie Blog is a responsive web application, and should be fully functional and work on any modern device: desktop: tablet: and mobile. With a limited amount of time and knowledge, a user can change the background and logo images, set the various container widths, opacities, and even skin and share their own personal themes. I have also developed scores of pre-defined themes.</p>

					<p><b>Gregory’s Blog</b> is a HTML5 interface, has built in social sharing, theme-based code formatters, a web based installer, enclosure support, supports inline .CSS, scripts and HTML, engaging media and animation capabilities using <b><a href="https://greensock.com/">GreenSock</a></b>, an HTML 5 based media player, captcha, comment moderation, search capabilities, RSS feeds and CFBlogger integration, textblock support, and has a plug-in architecture where you can isolate and potentially share your own custom code. Additionally, this blog uses the exact same database and ColdFusion server side logic as another older popular ColdFusion blog engine, blogCfc, so if you are familiar with ColdFusion, or have used BlogCfc, you should be able to convert your current blog and get this up and running quite easily.</p>

					<p>To keep this project moving forward, I hope to elicit your help. I hope to continue developing this blog with rich editor support and hopefully add some features for photographers. If you have a suggestion, or have a bug to report; please don’t hesitate to contact me. Your input and suggestions are welcomed. Finally, if you blog and program in ColdFusion, I would encourage you to consider sharing your own ColdFusion based blogging solution. I designed this blog to support rudimentary plug-in functionality so that others can share their own code.</p>

					<p>The blogging content that I will contribute mainly will deal with the support of Gregory’s Blog, and hopefully provide helpful articles about how to incorporate Telerik’s Kendo UI with ColdFusion. I would like to believe that I am an expert at both technologies and hope to share some of my insight. Also, this blog is intended to be downloaded so that others can learn by examining my code. I also hope to publish a few random non tech articles from time to time, share a recipe or two, and to share my adventures from a recent hiking trip.</p>

					<p>Thanks!</p> 

					<p>Gregory Alexander</p> 

					<p><a href="http://gregoryalexander.com/blog/">http://gregoryalexander.com/blog/</a></p> 
					
				</div>
			</cfsavecontent>
			
		<cfelseif findNoCase('downloadPod', arguments.contentTemplate)>	
			
			<cfsavecontent variable="contentPreview">
				<div class="widget k-content flexItem">
					<span class="innerContentContainer">
						<h3 class="topContent"><i class="fas fa-file-download"></i> Download Galaxie Blog</h3>
						<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
						  <tr class="k-content">
							<td align="left"><button type="button" class="k-button k-primary" style="#kendoButtonStyle#" onClick="createAboutWindow(3);"> Download </button></td>
						  </tr>
						</table>
						<br/>
					</span>
				</div>
			</cfsavecontent>
			
		<cfelseif findNoCase('subscribePod', arguments.contentTemplate)>
			
			<cfsavecontent variable="contentPreview">
				
				<div class="widget k-content flexItem"> <span class="innerContentContainer">
				  <h3 class="topContent"><i class="fas fa-envelope-open-text"></i> Subscribe</h3>
				  <div class="calendar">  
					Enter your email address to subscribe to this blog.
					<form id="subscribeViaDivForm" name="subscribeViaDivForm" action="#chr(35)#" method="post" data-role="validator">
					  <input type="email" id="subscribeViaDiv" name="subscribeViaDiv" value="" class="k-textbox" aria-label="Enter your email address" required validationMessage="Email is required" data-email-msg="Email is not valid" />
					  <br/>
					  <input type="button" id="subscribeViaDivSubmit" name="subscribeViaDivSubmit" value="Subscribe" class="k-button k-primary" style="#kendoButtonStyle#">
					</form>
				  </div>
				  <br/>
				  </span> 
				</div>

			</cfsavecontent>
			
		<cfelseif findNoCase('cfblogsFeedPod', arguments.contentTemplate)>	
			
			<cfsavecontent variable="contentPreview">
				<div class="innerContentContainer k-content">
					<h3 class="topContent"><i class="fas fa-rss-square"></i> CfBlogs.org Feed</h3>
					<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
					<tr class="k-content" height="35px;"> 
						<!--Create the nice borders after the first row.-->
						<td valign="top"><!--Display the content.--> 
						Ben Nadel<br/>
						<a href="https://www.bennadel.com/blog/4744-unreasonable-hospitality-by-will-guidara.htm" style="color:whitesmoke">Unreasonable Hospitality By Will Guidara</a><br /></td>
					  </tr>
					<tr class="k-alt" height="35px;"> 
						<!--Create the nice borders after the first row.-->
						<td align="left" valign="top" class="border"><!--Display the content.--> 
						ColdFusion<br/>
						<a href="https://coldfusion.adobe.com/2024/12/released-coldfusion-2023-and-2021-december-23th-2024-security-updates/" style="color:whitesmoke">RELEASED- ColdFusion 2023 and 2021 December 23rd, 2024 Security Updates</a><br /></td>
					  </tr>
					<tr class="k-content" height="35px;"> 
						<!--Create the nice borders after the first row.-->
						<td align="left" valign="top" class="border"><!--Display the content.--> 
						ColdFusion<br/>
						<a href="https://coldfusion.adobe.com/2024/12/released-coldfusion-2023-and-2021-december-23rd-2024-security-updates/" style="color:whitesmoke">RELEASED- ColdFusion 2023 and 2021 December 23rd, 2024 Security Updates</a><br /></td>
					  </tr>
					<tr class="k-alt" height="35px;"> 
						<!--Create the nice borders after the first row.-->
						<td align="left" valign="top" class="border"><!--Display the content.--> 
						Gregory's Blog<br/>
						<a href="https://www.gregoryalexander.com/blog/2024/12/22/things-that-i-wish-i-had-known-before-setting-up-a-smart-home--a-smart-home-primer" style="color:whitesmoke">Things that I Wish I Had Known Before Setting Up a Smart Home - A Smart Home Primer</a><br /></td>
					  </tr>
					<tr class="k-content" height="35px;"> 
						<!--Create the nice borders after the first row.-->
						<td align="left" valign="top" class="border"><!--Display the content.--> 
						FusionReactor<br/>
						<a href="https://fusion-reactor.com/blog/fusionreactor-dominates-g2s-winter-2025-awards-with-multiple-leadership-recognitions/" style="color:whitesmoke">FusionReactor Dominates G2’s Winter 2025 Awards with Multiple Leadership Recognitions</a><br /></td>
					  </tr>
				  </table><br/>
				</div>
			</cfsavecontent>
			
		<cfelseif findNoCase('recentPostsPod', arguments.contentTemplate)>	
			
			<!--- Get the new recent posts --->
			<cfset recentPosts = application.blog.getRecentPosts()>
			
			<cfsavecontent variable="contentPreview">
			
				<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
					<cfif not arrayLen(recentPosts)>
						<tr>
							<td class="k-content">
							<cfoutput>There are no recent posts.</cfoutput>
							</td>
						</tr>
					</cfif>
				<!--- Set a loop counter to mimic ColdFusion's currentRow --->
				<cfparam name="recentPostLoopCount" default="1">
				<!--- Loop through the array --->
				<cfloop from="1" to="#arrayLen(recentPosts)#" index="i">
					<cfsilent>
					<!--- Set the values. --->
					<cfset recentPostUuid = recentPosts[i]["PostUuid"]>
					<cfset recentPostId = recentPosts[i]["PostId"]>
					<cfset recentPostTitle = recentPosts[i]["Title"]>
					<cfif application.serverRewriteRuleInPlace>
						<cfset entryLink = replaceNoCase(application.blog.makeLink(recentPostId), '/index.cfm', '')>
					<cfelse>
						<cfset entryLink = application.blog.makeLink(recentPostId)>
					</cfif>
					</cfsilent>
					<cfoutput>
					<tr class="#iif(recentPostLoopCount MOD 2,DE('k-content'),DE('k-alt'))#">
						<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif recentPostLoopCount eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
						<a href="#entryLink#" aria-label="#recentPostTitle#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#recentPostTitle#</a>
						</td>
					</tr>
					</cfoutput>
					<cfset recentPostLoopCount = recentPostLoopCount + 1>
				</cfloop>
				</table>
			</cfsavecontent>
						
		<cfelseif findNoCase('recentCommentsPod', arguments.contentTemplate)>	
			
			<cfset numComments = 5><!--- How many comments do you want to retrived to be displayed on the sidebar? Default value is 5. --->
		
			<!--- Comment Settings. --->
			<!--- How long do you want the comment to be? --->
			<cfset lenComment = "200">
			<cfif not application.includeDisqus>
				<!--- We will use the revised commenting interface that was built into Galaxie Blog --->
				<cfset getRecentComments = application.blog.getRecentComments(numComments)>
			</cfif><!---<cfif application.includeDisqus>--->

			<!--- Set the name of the element that will contain the recent disqus comments. --->
			<cfset recentCommentsElementId="recentCommentsDiv">
				
			<!--- Set the padding for the avatar. Mobile is smaller than desktop. --->
			<cfif isMobileDevice>
				<cfset avatarPadding = "3px 3px 3px 3px">
			<cfelse>
				<cfset avatarPadding = "6px 6px 6px 6px">
			</cfif>
						
			<cfsavecontent variable="contentPreview">
						
					<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="0" cellspacing="0">
				<cfif not application.includeDisqus>
					<cfif not arrayLen(getRecentComments)>
						<tr>
							<td class="k-content">
							<cfoutput>There are no recent comments.</cfoutput>
							</td>
						</tr>
					</cfif><!---<cfif not getComments.recordCount>--->
					<!--- Set a loop counter to mimic ColdFusion's currentRow --->
					<cfparam name="recentCommentLoopCount" default="1">
					<!--- Loop through the array --->
					<cfloop from="1" to="#arrayLen(getRecentComments)#" index="i">
						<cfsilent>
							<!--- Set the values. --->
							<cfset commentId =  getRecentComments[i]["CommentId"]>
							<cfset commentUuid =  getRecentComments[i]["CommentUuid"]>
							<cfset comment =  getRecentComments[i]["Comment"]>
							<cfset commentPostId = getRecentComments[i]["PostId"]>
							<cfset PostDatePosted = getRecentComments[i]["PostDatePosted"]>
							<cfset commentPostUuiId = getRecentComments[i]["PostUuid"]>
							<cfset commentPostAlias = getRecentComments[i]["PostAlias"]>
							<cfset commentPostTitle = getRecentComments[i]["PostTitle"]>
							<cfset commenterFullName = getRecentComments[i]["CommenterFullName"]>
							<cfset commenterEmail = getRecentComments[i]["CommenterEmail"]>
							<cfset commentDatePosted = getRecentComments[i]["DatePosted"]>

							<!--- Set the anchor link that will be wrapped around the title. There is extra logic required here as we need to grab this from various functions. --->

							<!--- Set the link --->
							<cfset commentLink = application.blog.makeCommentLink(commentPostId, PostDatePosted, commentPostAlias, commentId)>

							<!--- Shorten and format the comment.--->
							<cfset formattedComment = comment>
							<cfif len(formattedComment) gt len(lenComment)>
								<cfset formattedComment = left(formattedComment, lenComment)>
							</cfif>
							<cfset formattedComment = application.Udf.replaceLinks(formattedComment,25)>
							<cfif len(comment) gt lenComment>
								<cfset formattedComment = formattedComment & "...">
							</cfif>

						</cfsilent>
					<cfoutput>
					<tr class="#iif(recentCommentLoopCount MOD 2,DE('k-content'),DE('k-alt'))#" height="50px;">
						<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif recentCommentLoopCount eq 1>
							<td valign="top">
						<cfelse>
							<td align="left" valign="top" class="border">
						</cfif>
							<!--- Create the comment link
							See notes above the showComment function on index.cfm template for more information.  --->
						<cftry>
							<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" title="#commenterFullName#'s Gravatar" alt="#commenterFullName#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
							<cfcatch type="any">
							</cfcatch>
						</cftry>
							<a href="#commentLink#" aria-label="#commentLink#" style="display: block; padding-top: 10px; padding-bottom: 5px;<cfif darkTheme> color:whitesmoke</cfif>">#commentPostTitle#:</a>
							<span style="display: block; padding-bottom: 10px; color:<cfif darkTheme>whitesmoke<cfelse>black</cfif>">#formattedComment#</span>
						</td>
					</tr>
					</cfoutput>
					<cfset recentCommentLoopCount = recentCommentLoopCount + 1>
					</cfloop>

			<cfelse><!---<cfif not application.includeDisqus>--->

				<!--- There are two ways to display the disqus recent comments: with an API key using the Disqus API, and without an API key using a recent comments widget. The method you take is up to you. ---> 
				<cfif application.disqusApiKey neq "">
						<tr>
							<td>
								<!--- Comments will be displayed here. --->
								<div id="<cfoutput>#recentCommentsElementId#</cfoutput>"></div>
							</td>
						</tr>
				<cfelse><!---<cfif application.disqusApiKey neq "">--->
					<tr class="k-content" height="75px;">
						<td align="left" valign="top" id="removeUlPadding">
							<!--- We are using the recent comments widget. --->
							<script type="text/javascript" src="https://<cfoutput>#application.disqusBlogIdentifier#</cfoutput>.disqus.com/recent_comments_widget.js?num_items=<cfoutput>#numComments#</cfoutput>&hide_avatars=0&avatar_size=40&excerpt_length=100"></script>
						</td>
					</tr>
				</cfif><!---<cfif application.disqusApiKey neq "">--->
			</cfif><!---<cfif not application.includeDisqus>--->				
				</table>
				<br/>
			</cfsavecontent>
								
		<cfelseif findNoCase('categoriesPod', arguments.contentTemplate)>	
						
			<cfsavecontent variable="contentPreview">
				
				<cfset categories = application.blog.getCategories(parentCategory=1)>
	
				<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
				<cfif not arrayLen(categories)>
					<tr><td>There are no Category Archives.</td></tr>
				</cfif>
				<cfloop from="1" to="#arrayLen(categories)#" index="i">
					<cfsilent>
						<cftry>
							<!--- Extract the values from the category array --->
							<cfset categoryId = categories[i]["CategoryId"]>
							<cfset categoryUuid = categories[i]["CategoryUuid"]>
							<cfset category = categories[i]["Category"]>
							<cfset categoryPostCount = categories[i]["PostCount"]>
							<cfset categoryLink = #application.blog.makeCategoryLink(categoryId)#>
							<cfparam name="categoryRowCount" default="1">
							<cfcatch type="any">
								<cfset error = 'Error trying to render Archive Pod'>
							</cfcatch>
						</cftry>
					</cfsilent>
					<cfoutput>
				<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>
					<tr class="#iif(categoryRowCount MOD 2,DE('k-content'),DE('k-alt'))#">
						<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif i eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
						<a href="#categoryLink#" title="#category# RSS" <cfif darkTheme>style="color:whitesmoke"</cfif>>#category# (#categoryPostCount#)</a> [<a href="#application.baseUrl#/rss.cfm?mode=full&amp;mode2=cat&amp;catid=#categoryId#" rel="noindex,nofollow" <cfif darkTheme>style="color:whitesmoke"</cfif>>RSS</a>]
						</td>
					</tr>
					<!--- Increment our counter --->
					<cfset categoryRowCount = categoryRowCount + 1>
				</cfif><!---<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>--->
					</cfoutput>
				</cfloop>
				</table>
				<br/>
				
			</cfsavecontent>
					
		<cfelseif findNoCase('monthlyArchivesPod', arguments.contentTemplate)>
			
			<!--- Is there a URL rewrite rule in place? If so, we need to eliminate the 'index.cfm' string from all of our links. A rewrite rule on the server allows the blog owners to to obsfucate the 'index.cfm' string from the URL. This setting is in the application.cfc template. --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset thisUrl = replaceNoCase(application.baseUrl, '/index.cfm', '')>
			<cfelse>
				<cfset thisUrl = application.baseUrl>
			</cfif>
						
			<cfsavecontent variable="contentPreview">					
					
				<!--- get the last 5 years by default. If you want all months/years, remove the param --->
				<cfset getMonthlyArchives = application.blog.getArchives(archiveYears=5)>

				<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
				<cfif not arrayLen(getMonthlyArchives)>
					<tr><td>There are no Monthly Archives.</td></tr>
				</cfif>
				<!--- Loop through the month archives ORM object. --->
				<cfloop from="1" to="#arrayLen(getMonthlyArchives)#" index="i">
					<cfsilent>
					<!--- Extract the values from the array. --->
					<cfset previousMonths = getMonthlyArchives[i]["PreviousMonths"]>
					<cfset previousYears = getMonthlyArchives[i]["PreviousYears"]>
					<cfset entryCount = getMonthlyArchives[i]["EntryCount"]>
					</cfsilent>
					<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#">
						<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif i eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
						<cfoutput>
						<a href="#thisUrl#?mode=month&amp;month=#previousMonths#&amp;year=#previousYears#" aria-label="#monthAsString(previousMonths)# #previousYears# (#entryCount#)" <cfif darkTheme>style="color:whitesmoke"</cfif>>#monthAsString(previousMonths)# #previousYears# (#entryCount#)</a>
						</cfoutput>
						</td>
					</tr>	
				</cfloop>
				</table>
				<br/>
			
			</cfsavecontent>
			
		<cfelseif findNoCase('compositeFooter', arguments.contentTemplate)>	
			
			<cfset footerImage = getTheme[1]["FooterImage"]>
			
			<!--- Note: spans and footer tags are stripped by tinymce and are not included in the preview --->
			<cfsavecontent variable="contentPreview">
			
				<img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo" style="display: block; margin-left: auto; margin-right: auto;" />

				<h2 style="font-size:14pt; display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h2>
				<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

				<h2 style="font-size:14pt">Images and Photography:</h2>
				<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>

				<h2 style="font-size:14pt">Credits:</h2>
				<p>
					Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. 
				</p>
				<h2 style="font-size:14pt">Version:</h2>
				<p>
					Galaxie Blog Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput>
				</p>

			</cfsavecontent>
				
		<cfelseif findNoCase('customFooterHtml', arguments.contentTemplate)>
			
			<cfset tailEndScripts = getTheme[1]["TailEndScripts"]>
			<cfsavecontent variable="contentPreview">
				<cfoutput>
				#tailEndScripts#
				</cfoutput>
			</cfsavecontent>
							
		</cfif><!---<cfelseif findNoCase('compositeFooter', arguments.contentTemplate)>	--->
				
		<cfreturn contentPreview>
				
	</cffunction>
	customHeaderHtml
</cfcomponent>
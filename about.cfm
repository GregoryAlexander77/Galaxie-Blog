<cfsilent>	
<!--- Get the current theme --->
<cfset selectedThemeAlias = trim(application.blog.getSelectedThemeAlias())>
<!--- Get the Theme data for this theme. --->
<cfset getTheme = application.blog.getTheme(themeAlias=selectedThemeAlias)>	
<!--- Set the Kendo theme --->
<cfset kendoTheme = getTheme[1]["KendoTheme"]>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = getTheme[1]["DarkTheme"]>
</cfsilent>
<style>
	#about {
		/* Subtle drop shadow on the header banner that stretches across the page. */
		box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);	
	}
</style>
<cfif URL.aboutWhat eq 1>
	<img src="<cfoutput><cfif session.isMobile>#application.baseUrl#/images/logo/gregorysBlogMobile.png<cfelse>#application.baseUrl#/images/logo/gregorysBlogLogo.gif</cfif></cfoutput>" id="about" align="left" alt="Gregory Alexander" style="margin: 15px;"/>

	<p style="display: none;">About this blog.</p>

	<p>Question for the seasoned developer- when was the last time that you actually bought a computer programming book? If you’re like me, it has been a long time ago when we had different stacks of different books filled with sticky notes laying next to us. Instead, I rely upon the web, and blogs like this to solve my programming needs. I often joke that my actual job is using search engines as a living. Often, meeting a goal depends on using the right search phrases to find an answer to the current challenge that I am facing. Developing this blog is one way that I can try to give back to this community.</p>

	<p><b>Gregory’s Blog</b> is intended to be the most beautiful and functional open sourced ColdFusion based blog in the world. While I can’t go toe to toe with Wordpress functionality, I believe that Gregory’s Blog competes with Wordpress in core functionality, especially with its abundant theme related features. This blog was built from the ground up to be eminently themeable. Galaxie Blog is a responsive web application, and should be fully functional and work on any modern device: desktop: tablet: and mobile. With a limited amount of time and knowledge, a user can change the background and logo images, set the various container widths, opacities, and even skin and share their own personal themes. I have also developed a dozen or so professionally designed pre-defined themes.</p>

	<p><b>Gregory’s Blog</b> is a HTML5 interface, has built in social sharing, theme-based code formatters, a web based installer, enclosure support, supports inline .CSS, scripts and HTML, engaging media and animation capabilities using <b><a href="https://greensock.com/">GreenSock</a></b>, an HTML 5 based media player, captcha, comment moderation, search capabilities, RSS feeds and CFBlogger integration, textblock support, and has a plug-in architecture where you can isolate and potentially share your own custom code. Additionally, this blog uses the exact same database and ColdFusion server side logic as another older popular ColdFusion blog engine, blogCfc, so if you are familiar with ColdFusion, or have used BlogCfc, you should be able to convert your current blog and get this up and running quite easily.</p>

	<p>To keep this project moving forward, I hope to elicit your help. I hope to continue developing this blog with rich editor support and hopefully add some features for photographers. If you have a suggestion, or have a bug to report; please don’t hesitate to contact me. Your input and suggestions are welcomed. Finally, if you blog and program in ColdFusion, I would encourage you to consider sharing your own ColdFusion based blogging solution. I designed this blog to support rudimentary plug-in functionality so that others can share their own code.</p>

	<p>The blogging content that I will contribute mainly will deal with the support of Gregory’s Blog, and hopefully provide helpful articles about how to incorporate Telerik’s Kendo UI with ColdFusion. I would like to believe that I am an expert at both technologies and hope to share some of my insight. Also, this blog is intended to be downloaded so that others can learn by examining my code. I also hope to publish a few random non tech articles from time to time, share a recipe or two, and to share my adventures from a recent hiking trip.</p>

	<p>Thanks!</p> 

	<p>Gregory Alexander</p> 

	<p><a href="http://gregoryalexander.com/blog/">http://gregoryalexander.com/blog/</a></p> 
	
<cfelseif URL.aboutWhat eq 2>
	
	<img src="<cfoutput>#application.baseUrl#</cfoutput>/images/photo/gregory<cfif session.isMobile>Mobile</cfif>.jpg" id="about" align="left" alt="Gregory Alexander" style="margin: 15px;"/>
	<p style="display: none;">About Gregory Alexander.</p>
	<p>I have over 23 years of web development experience. After serving in the Navy- I went to college in the mid 90’s and obtained several degrees in computer graphics and multimedia authoring. My timing was terrific, as soon as a had graduated, the web exploded onto the scene. </p>
	<p>I started developing with ColdFusion 2.5, which was the original ‘middle-ware’ tool to drive database driven websites. Later, I also learned classic ASP. Soon, I became the lead web developer at Boeing’s Everett site, and helped to build the largest intranet site in the world at the time. </p>
	<p>I moved on to the University of Washington Genome Center, where I worked in Bioinformatics and built collaborative web applications for the Human Genome Project. After the Human Genome Project was completed in the mid 2000’s, I started developing critical web applications for Harborview Medical Center.</p>
	At Harborview, I developed and maintained a web application that was used in every hospital ICU for multiple states, and was used to deliver critical care patients to the nearest hospital while enroute. If I had made a bug, someone could have very well died. I am happy to say that I had never made a bug in that production site there!</p>
	<p>Currently, I am working at the University of Washington Medical developing web applications that are used at various hospitals, and in my off time, I am working on developing this application for the open source community.</p>
	<p>My personal passions include photography, cooking, building and engineering moutain trail systems (I started building trail systems as a kid), long road trips, and of course hiking!</p>

<cfelseif URL.aboutWhat eq 3>
	
	<cfsilent>
	<cfif kendoTheme contains 'material'>
		<cfif session.isMobile>
			<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
		<cfelse>	
			<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
		</cfif>
	<cfelse><!---<cfif kendoTheme contains 'material'>--->
		<cfif session.isMobile>
			<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
		<cfelse>	
			<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
		</cfif>
	</cfif><!---<cfif kendoTheme contains 'material'>--->
	</cfsilent>

	<p><b>License</b></p>
	<p>Galaxie Blog, and its associated software, is governed by the <a href="https://www.apache.org/licenses/LICENSE-2.0.html">Apache 2.0 license</a>. 
	Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.</p>

	<p><b>Credits</b></p>
	<p>This blog would not have been possible without <a href="http://www.coldfusionjedi.com">Raymond Camden</a>. Raymond developed <a href="http://www.blogcfc.com/views/main/docs/index.htm">BlogCfc</a>, on which this platform was originally based. Raymond is a ColdFusion enthusiast who authored thousands of ColdFusion related posts on the internet. Like every senior ColdFusion web developer; I have found his posts invaluable and have based many of my own ColdFusion libraries based upon his approach.</p>

	<p><b>Installation</b></p>
	<p>The installation package is found either on <a href="https://github.com/GregoryAlexander77/gregorysBlog/archive/master.zip">Galaxie Blog</a>, or on <a href="https://github.com/GregoryAlexander77/gregorysBlog">Github</a>. After downloading and extracting the installation package, you will see the Apache 2.0 license and two folders, blog and install. You can rename the blog folder to anything that you would like, or you can copy the contents of the folder and remove the blog folder. You don't need to keep the same structure. Galaxie Blog will adjust the paths as necessary when running the web based installer. Upload all of these files to your web server. Of course, your web server must be running ColdFusion. I have tested the software on both ColdFusion 2016 and 2018 and the software should work on all recent ColdFusion servers*. You will also need to have a database. It is recommended that you use Microsoft SQL Server, or MySql, but this blog should also work with Oracle and Microsoft Access. </p>

	<p>Once the files have been uploaded to your own web server, you need to navigate to the installer. Unless you have renamed or removed the blog folder, the default path would be '/blog/installer/'. The installer should walk you through the installation process. After the installation process, you will need to fine tune the settings using the blog's administrative interface. The default administrative interface is found under /blog/admin/' There are articles on this web site that explains the settings in detail. If you have a problem, please email me, or make a comment on this website, and I will try to help you.</p>

	<p>If you use this blog, I hope that you will give me credit and link back to <a href="http://www.gregoryalexander.com">www.gregoryalexander.com</a>, preferably by leaving this content found under 'about' - 'download' link intact in the menu. I also ask that you inform me if you find bugs, or have any suggestions.</p>

	<p>Copyright 2019 Gregory Alexander</p>

	<button type="button" class="k-button k-primary" style="#kendoButtonStyle#">
		<i class="fas fa-file-download" style="color:whitesmoke"></i>&nbsp;&nbsp;<a href="https://github.com/GregoryAlexander77/gregorysBlog/archive/master.zip" style="color:whitesmoke">Download ZIP</a>
	</button>

	<button type="button" class="k-button k-primary" style="#kendoButtonStyle#">
		<i class="fab fa-github" style="color:whitesmoke"></i>&nbsp;&nbsp;<a href="https://github.com/GregoryAlexander77/gregorysBlog" style="color:whitesmoke">Github Project</a>
	</button>

	<p>* I suggest that you run this using ColdFusion 2016 if you want to use this blog's captcha features. The captcha library that Peter J. Farrel developed uses the com.sun.image.codec.jpeg.JPEGCodec library, which is depracated in ColdFusion 2018. I intend to rewrite the underlying logic to handle captcha differently in a future release. </p>

	<p>Version <cfoutput>#application.blog.getVersion()#</cfoutput> January 16th 2022.</p>
		
</cfif>





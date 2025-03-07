<cfsilent>
	<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "downloadWindow">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getPageContent function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->

</cfsilent>
				
<cfif displayContentOutputData>
	<!--- Include the content template for the navigation script --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>

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
</cfif>
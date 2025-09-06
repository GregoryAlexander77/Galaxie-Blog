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

	<h2>License</h2>
	<p>Galaxie Blog, and its associated software, is governed by the <a href="https://www.apache.org/licenses/LICENSE-2.0.html">Apache 2.0 license</a>. 
	Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.</p>
			
	<h2>Getting the software</h2>
	<ol>
		<li>Galaxie Blog can be downloaded from the <a title="Galaxie Blog Git Hub Repository" href="https://github.com/gregoryalexander77/Galaxie-Blog" target="_blank" rel="noopener">Galaxie Blog Git Hub Repository</a>.</li>
	</ol>
		
	<button type="button" class="k-button k-primary" style="#kendoButtonStyle#">
		<i class="fab fa-github" style="color:whitesmoke"></i>&nbsp;&nbsp;<a href="https://github.com/gregoryalexander77/gregorysBlog" style="color:whitesmoke">Github Project</a>
	</button>

	<h2>Prerequisites</h2>
	<ol>
		<li>You must have ColdFusion or Lucee installed on the web server.
			<ul>
				<li>&nbsp;<strong>Lucee</strong>
					<ul>
						<li>Galaxie Blog has been tested using Lucee 6.031 through <span>Lucee 6.2.0.321. Due to ORM issues, Galaxie Blog does not work with versions below 6.0.</span></li>
						<li><span>You must have the following packages installed: <a href="https://www.ortussolutions.com/products/orm-extension">Ortus ORM Extension</a> 6.0+, Image Extension 2.0+, EHCache 2.0+, Mail, and the extensions for the database of your choice.&nbsp;</span></li>
					</ul>
				</li>
				<li><strong>ColdFusion</strong>
					<ul>
						<li>Galaxie Blog has been tested on ColdFusion 2016, 2018, 2021, and 2023 (2023.0.07.330663).</li>
						<li>The blog may theoretically support any ColdFusion edition starting from ColdFusion 9; however, your mileage may vary.</li>
						<li>The following packages must be installed: Cacheing, Feed, Image, Mail, ODBC, ORM, and the extensions for the database of your choice.</li>
					</ul>
				</li>
				<li>We have successfully tested using Apache, TomCat, and IIS. We also have successfully tested both Lucee and Adobe ColdFusion with CommandBox.<br><br></li>
			</ul>
		</li>
		<li>Hosting: many ISPs offer ColdFusion and Lucee Hosting. I use <a href="https://www.media3.net">Media3.net</a> for Adobe ColdFusion and <a href="https://viviotech.net/">VivioTech</a> with Lucee, which are terrific! Search the web for ColdFusion or Lucee hosting to find out more.<br><br></li>
		<li>Once downloaded, upload the content to your desired location on a web server. If you are uploading the blog folder, change the folder name as desired.<br>
			<ul>
				<li>You can install the contents in the root or a folder in your server's root directory.</li>
				<li>You can use the root or a subfolder. I have tested the blog in the root ('/'), '/blog', and '/galaxie' folders.<br><br></li>
			</ul>
		</li>
		<li><span>You must have a database that is accessible to the web server. The blog </span><strong><em>should</em></strong><span> support one of the following databases:</span><br><br>
			<ul>
				<li>Microsoft SQL Server</li>
				<li>DB2</li>
				<li>DB2AS400</li>
				<li>DB2OS390</li>
				<li>Derby</li>
				<li>Informix</li>
				<li>MariaDB</li>
				<li>MySQL</li>
				<li>MySQLwithInnoDB</li>
				<li>MySQLwithMyISAM</li>
				<li>Oracle8i</li>
				<li>Oracle9i</li>
				<li>Oracle10g</li>
				<li>PostgreSQL</li>
				<li>Sybase</li>
				<li>SybaseAnywhere<br><br></li>
			</ul>
		</li>
		<li>Create the database.<br><br>
			<ul>
				<li>You may install Galaxie Blog using your current database. However, you must ensure that there are no table name conflicts.&nbsp;</li>
				<li>We have tested Galaxie Blog using our original BlogCFC database with no conflicts.<br><br></li>
			</ul>
		</li>
		<li>Create the Blogs ColdFusion DSN.
			<ol>
				<li>If you use a DSN other than GalaxieDb with <strong>Lucee</strong>, you must modify the DSN string in the root Application.cfc. Search for &lt;cfset this.datasource = "GalaxieDb"&gt; and modify the DSN.</li>
				<li>As a precaution, set the maximum connections setting to&nbsp; a value that is less than the database max connections if you're using&nbsp; <strong>Lucee </strong>and one of the flavors of MySql</li>
			</ol>
		</li>
	</ol>
	<hr>
	<h2 id="mcetoc_1htggj0er4"><a id="woff"></a>Enable Woff and Woff2 Font Support on the Webserver</h2>
	<p>Galaxie Blog uses web fonts for typography and needs web font mime types set up on the web server. Most modern web servers already support these web font mime types, but you may need to set the following mime types need to be set up on some servers. Certain textual elements will not be displayed if the server does not support these mime types.&nbsp;</p>
	<ol>
		<li>.woff (use font/woff as the mime type).</li>
		<li>.woff2 (use font/woff2 as the mime type).</li>
	</ol>
	<hr>
	<h2 id="mcetoc_1htggj0er5"><strong><a id="install"></a></strong>Installing the Software</h2>
	<p>Galaxie Blog is simple to install and uses a built-in multi-step installer. However, a few manual steps are required after uploading the software to your web server.</p>
	<ol>
		<li>Migrate to the URL of your uploaded blog, and the blog should automatically open the installer.
			<ul>
				<li>For example, if you uploaded the files to the root directory, go to <a href="http://yourdomain.com/">http://yourdomain.com/</a>.</li>
				<li>If you uploaded to a blog directory in your root, go to <a href="http://yourdomain.com/blog/,">http://yourdomain.com/blog/,</a> etc.</li>
			</ul>
		</li>
		<li>The installer will guide you and ask you to enter your URL, blog name, and other information.&nbsp;</li>
		<li>The installer is a seven-step process. Each screen may provide information and ask you to hit the next button or have multiple questions. It should not take more than five minutes to complete.</li>
		<li>Be sure to write down your chosen username and password. You will need to retain this information. Galaxie Blog does not keep passwords—they are hashed using the strongest publicly available encryption process and cannot be recovered.</li>
		<li>Once you are done, the installer will automatically create the database and import the needed data. The final step may take a while for the software to install. If you receive a time-out error, refresh the browser, and the installation should continue.</li>
		<li>Once installed, your new blog should have a 'No Entries' message on the front page. However, you will not see any blog posts until you create them using the administrative site; see below.</li>
	</ol>
	<p>If you have any issues, don't hesitate to <a href="https://www.gregoryalexander.com/blog/">contact </a>me.</p>

	<p>Copyright 2025 Gregory Alexander</p>

	<p>Version <cfoutput>#application.blog.getVersion()#</cfoutput> March 15th 2025.</p>
</cfif>
	<table>
		<tr>
			<td valign="top"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/import.jpg"></td>
			<td>
				<p>This template should be able to import and transform your BlogCFC or Galaxie Blog data into Galaxie Blog 3.0. However, you will need to perform several simple steps in order to transfer the original data to Galaxie Blog.</p>
				<p>Locate the <cfoutput>#application.baseUrl#</cfoutput>/common/data/generateBlogCfcDateFiles.cfm template in this installation and upload this ColdFusion template to a server that has access to your original BlogCFC or Galaxie Blog database. You will need to manually modify the following cfsetsettings at the very top of the template to communicate to your orginal database: </p>
				<ol>
					<li>Set the destination path on the original database server where you want the WDDX files to be generated to.</li>
					<li>Set the ColdFusion DSN to point to your original database</li>
					<li>If you're uploading images located in the 'enclosures' folder, set the oldEnclosurePath to point to original file location where the enclosure folder used to be. This template will change the original enlosure path and automatically set the new enclosure path for this Blog installation. If you are not uploading post enclosure images this step is not necessary.</li>
					<li>Run the template that you modified on the server that has access to the original BlogCFC/Galaxie database. The code should generate new WDDX files. This code is not using ORM, however, the queries are simple SELECT * queries that should be able to run on most modern databases.</li>
					<li>The generateBlogCfcDateFiles.cfm template has been tested against all of the Galaxie Blog 1x versions and BlogCFC version 6. You may need to modify this template if you are running a version less than BlogCFC 6. To the best of my recollection, BlogCFC version 5.98 is missing a single database column and you will have to set the following column output to '' to bypass the error and properly generate the WDDX files ('' as MissingColunm).</li>
					<li>After running this template, the code should generate the following files in the directory that you specified in step 1 above.</li>
					<ol>
						<li>getBlogCfcCategories.txt</li>
						<li>getBlogCfcPostCategories.txt</li>
						<li>getBlogCfcPostComments.txt</li>
						<li>getBlogCfcRelatedPosts.txt</li>
						<li>getBlogCfcSubscribers.txt</li>
					</ol>
					<li>Copy all of these files and upload them to this installation in the <cfoutput>#application.baseUrl#</cfoutput>/common/data/files/blogCfcImport directory.</li>
					<li>If you have prior enclosure images, upload all of you original images to the <cfoutput>#application.baseUrl#</cfoutput>/enclosures/ folder.</li>
					<li>Open the <cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm template and enter the current blogs DSN near the top of the page. We are checking the security credentials before running this, however, this extra step reduces the chance that this template may be run inadvertently.</li>
					<li>Once your done uploading the WDDX files (and potentially the enclosures) along with entering the DSN, click on the <b>Submit</b> button below to start the database import process.</li>
				</ol>
			</td>
		</tr>
		<tr>
			<td colspan="2">
				<p>This import template has been successfully tested importing the data from Gregory's Blog at www.gregoryalexander.com. Gregory's Blog has around 150 posts and each post has an enclosure image. If you have more than 150 posts and recieve a query time-out error, you may want to modify this template and change how many records are run at a single given time. Alternatively, you can adjust the number of records in the WDDX files by changing the SQL in the generateBlogCfcDateFiles.cfm template.</p>

				<p> You can also specify what tables to import the data from by setting the tablesToPopulate argument at the top of this file. This template resides at <cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm.</p>
				<p><b>You can run this template as many times as you wish</b>. This template will determine whether the record already exists and will update the record (if it exists) or insert the new record. <b>You will not have any duplicate data</b> if you run this template more than one time.</p>

				<p>Other than the user information and blog settings, this template should handle all of the original data and successfully convert the data to be used by Galaxie Blog 3. However, the content between &lt;code&gt; tags may be formatted funny. This is due to having some difficulties to  reformat the content between to code blocks to work with Prism. However, all of the code blocks should be moved over, but you may have to modify the extra tabs and lines of empty code using the post editor.</p>

				<p>You can also use this method to import data from other Blog Software as long as you are able to transform the data into your original BlogCFC database. I may add new import scripts in the future to handle other blog software.</p>

				<p>Happy Blogging!</p>
			</td>
		</tr>
	</table>
		<p><a href="<cfoutput>#application.baseUrl#</cfoutput>/common/data/importBlogCfc.cfm" target="_blank" rel="noopener noreferrer"><button class="k-button k-primary">Proceed</button></a></p>
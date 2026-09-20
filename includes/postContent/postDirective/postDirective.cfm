<br/>
<div class="entryImage"><img class="fade lazied shown" data-src="/blog/enclosures/xmlPostDirective.jpg" alt="" data-lazied="IMG" src="/blog/enclosures/xmlPostDirective.jpg"></div>

<h4>Background</h4>

<p>For those who don't know, Galaxie Blog was built on top of BlogCfc, one of the most popular ColdFusion Blog engines around. However, BlogCfc was originally built  in the early 2000's.</p>

<p>Raymond Camden, the author of BlogCfc, used .ini files to store a lot of variable settings. It was a decent approach as the blog software in those days was much simpler. It is easier to store dynamic information in the .ini files rather than the database as BlogCfc supported SQL Server, MySql, Oracle and Access. 

<p>I also put quite a bit of information into the .ini files. In fact, I have nearly 500 different variables stuffed into the .ini files as putting it into a database was cumbersome as a lot of extra code and testing was required to support all of the databases.</p>

<p>However, using the .ini files to store a large amount of data is quite inefficient and slow.</p>

<p>After releasing version 1.15, I put a freeze on using any new settings into the .ini files. It was just too inefficient. It is my plan to wait until I get ColdFusion ORM up and running, and until then, I am either hardcoding some of the new variable information, and expanded on the existing BlogCfc XML Post Directives that I put in a Blog post.</p>

<h4>What is a Galaxie Blog XML Post Directive?</h4>

<p>BlogCfc used what I call a XML Post Directive to deliver certain functionality to a given <b>blog post</b>, such as wrapping a code block with <b>&lt;code></b> tags to present code. BlogCfc also used the &lt;more/> tag to condense a post on the main site that aborted the page at a certain position and created a button that navigates the reader to the full post.</p>

<p>Since Galaxie Blog 1.15, I used a handful of additional XML Post Directives to embed optional meta tag information, such as embedding video, and to bypass ColdFusions' Global Script Protection that is used by my hosting provider. Once I integrate ORM, I'll eventually use an interface and code editor to do this without the XML Post Directives, but in the meantime I am using this approach.

<p>Note: all of these directives are optional and only needed for certain occasions, such as including a video, to present video or code, and to bypass ColdFusions' Global Script Protection that is used by various ColdFusion hosting providers.</p>

<h4>Original BlogCfc XML Post Directives</h4>

<ul>
	<li>Use &lt;code> tags to format programming code:
		<ol>
			<li>Create the initial <b>&lt;code></b> tag.</li>
			<li>Insert the actual code</li>
			<li>Terminate your code block with &lt;/code></li>
		</ol>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/12/13/How-to-make-a-round-Kendo-UI-button">How to make a round Kendo UI button</a></li>
	</ul>
</ul>

<ul>
	<li>Use a single <b>&lt;more/></b> tag to condense the blog body when you're looking at <b>all</b> of the blog posts:
		<ul>
			<li>Place a &lt;more/> tag where you want the body to terminate</li>
		</ul>
		<ul>
	</ul>
		<li>Real world example: Scoll down to <a href="https://gregoryalexander.com/blog/index.cfm?&startRow=50&page=6">Kendo Server Side Validation</a></li>
	</li>
</ul>

<h4>SEO XML Post Directives</h4>

<ul>
	<li>Set the meta title for the individual blog post:
		<ul>
			<li>Enter the title after <b>titleMetaTag:</b> string:</li>
			<li>
			&lt;titleMetaTag:Galaxie Blog Post Directives>
			</li>
			<li>
			Terminate the tag with a closing &lt;/titleMetaTag>
			</li>
		</ul>
	</li>
</ul>


<ul>
	<li>Set the description for the individual blog post. This also sets the description when sharing the post on social media sites (i.e. the open graph and twitter meta tags):
		<ul>
			<li>Enter the description after <b>descMetaTag:</b> string:</li>
			<li>
			&lt;descMetaTag:How to use post directives in Galaxie Blog>
			</li>
			<li>
			Terminate the tag with a closing &lt;/descMetaTag>
			</li>
		</ul>
	</li>
</ul>

<h4>Image XML Post Directives</h4>

<ul>
	<li>Set the image URL for Facebook (i.e. sets the value for the og:image):
		<ul>
			<li>Note: if you upload an enclosure when making a post, <a href="https://gregoryalexander.com/blog/2019/11/1/How-to-make-the-perfect-social-media-sharing-image--part-4-Image-Examples">Facebook and Twitter images</a> will be automatically created for you.</li>
			<li>Enter the URL after <b>facebookImageUrlMetaData:</b> string:</li>
			<li>
			&lt;facebookImageUrlMetaData:/enclosures/facebook/aspectRatio.jpg>
			</li>
			<li>
			Terminate the tag with a closing &lt;/facebookImageUrlMetaData>
			</li>
		</ul>
	</li>
</ul>

<ul>
	<li>Set the image URL for Twitter (i.e. sets the value for the twitter:image):
		<ul>
			<li>Note: if you upload an enclosure when making a post, <a href="https://gregoryalexander.com/blog/2019/11/1/How-to-make-the-perfect-social-media-sharing-image--part-4-Image-Examples">Facebook and Twitter images</a> will be automatically created for you.</li>
			<li>Enter the URL after <b>twitterImageUrlMetaData:</b> string:</li>
			<li>
			&lt;twitterImageUrlMetaData:/enclosures/facebook/aspectRatio.jpg>
			</li>
			<li>
			Terminate the tag with a closing &lt;/twitterImageUrlMetaData>
			</li>
		</ul>
	</li>
</ul>

<h4>Video XML Post Directives</h4>

<ul>
	<li>Set the <b>video type</b>. When the proper video type is encountered, the media player will attempt to play the video:
		<ul>
			<li>The videoType can be: .mp3, .mp4, .ogg .ogv or .webm</li>
			<li>Specify the video type after <b>videoType:</b> string:</li>
			<li>
			&lt;videoType:.mp4>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoType>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set a cover image on top of the video if is not playing (optional):
		<ul>
			<li>Specify the URL to the cover image after <b>videoPosterImageUrl:</b> string:</li>
			<li>
			&lt;videoPosterImageUrl:https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-HD.jpg>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoPosterImageUrl>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the URL to the <b>small source (576p)</b> of a video (<b>optional</b>):
		<ul>
			<li>It's possible to have a small, medium and a large video source. The code will determine which video source to play depending upon the end users device type (i.e. desktop or mobile). The large video source should be in 576p format. </li>
			<li>Specify the URL to the medium sized video after <b>smallVideoSourceUrl:</b> string:</li>
			<li>
			&lt;smallVideoSourceUrl:https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-576p.mp4>
			</li>
			<li>
			Terminate the tag with a closing &lt;/smallVideoSourceUrl>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the URL to the <b>medium source (720p)</b> of a video (<b>optional</b>):
		<ul>
			<li>It's possible to have a small, medium and a large video source. The code will determine which video source to play depending upon the end users device type (i.e. desktop or mobile). The large video source should be in 720p format. </li>
			<li>Specify the URL to the medium sized video after <b>mediumVideoSourceUrl:</b> string:</li>
			<li>
			&lt;mediumVideoSourceUrl:https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-720p.mp4>
			</li>
			<li>
			Terminate the tag with a closing &lt;/mediumVideoSourceUrl>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the URL to the <b>large source (1080p)</b> of a video (<b>optional</b>):
		<ul>
			<li>It's possible to have a small, medium and a large video source. The code will determine which video source to play depending upon the end users device type (i.e. desktop or mobile). The large video source should be in 1080p format. </li>
			<li>Specify the URL to the medium sized video after <b>largeVideoSourceUrl:</b> string:</li>
			<li>
			&lt;largeVideoSourceUrl:https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-1080p.mp4>
			</li>
			<li>
			Terminate the tag with a closing &lt;/largeVideoSourceUrl>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the URL to the video <b>captions</b> file (<b>optional</b>):
		<ul>
			<li>Specify the URL to video captions VTT file after the <b>videoCaptionsUrl:</b> string:</li>
			<li>
			&lt;videoCaptionsUrl:https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-HD.en.vtt>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoCaptionsUrl>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the <b>cross origin</b> setting (<b>optional</b>):
		<ul>
			<li>This is an optional setting that only should be set when the video source is outside of your domain. Set to true only when the video is hosted from another source.</li>
			<li>Specify the URL to video captions VTT file after the <b>videoCrossOrigin:</b> string:</li>
			<li>
			&lt;videoCrossOrigin:true>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoCrossOrigin>
			</li>
		</ul>
	</li>
	<ul>
		<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/11/18/Sharing-Videos-to-Facebook-and-Twitter">Sharing-Videos-to-Facebook-and-Twitter</a></li>
	</ul>
</ul>

<ul>
	<li>Set the video <b>width</b> meta data (<b>optional</b>):
		<ul>
			<li>This is an optional setting that sets the width in the meta tags. It does not impact the presentation of the video and is only used by Facebook and Twitter.</li>
			<li>Specify the width in pixels after the <b>videoWidthMetaData:</b> string:</li>
			<li>
			&lt;videoWidthMetaData:1920>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoWidthMetaData>
			</li>
		</ul>
	</li>
</ul>

<ul>
	<li>Set the video <b>height</b> meta data (<b>optional</b>):
		<ul>
			<li>This is an optional setting that sets the height in the meta tags. It does not impact the presentation of the video and is only used by Facebook and Twitter.</li>
			<li>Specify the width in pixels after the <b>videoHeightMetaData:</b> string:</li>
			<li>
			&lt;videoHeightMetaData:1080>
			</li>
			<li>
			Terminate the tag with a closing &lt;/videoHeightMetaData>
			</li>
		</ul>
	</li>
</ul>

<h4>XML Post Directive for <b>YouTube</b></h4>

<ul>
	<li>Set the URL to a <b>YouTube Video</b>:
		<ul>
			<li>Specify the YouTube full URL after the <b>youTubeUrl:</b> string:</li>
			<li>
			&lt;youTubeUrl:https://www.youtube.com/watch?v=liJqpsjai9I&feature=youtu.be>
			</li>
			<li>
			Terminate the tag with a closing &lt;/youTubeUrl>
			</li>
			<ul>
				<li>Real world example: <a href="https://gregoryalexander.com/blog/2019/12/15/Embedding-a-video-from-YouTube-in-Galaxie-Blog">Embedding a video from YouTube in Galaxie Blog</a></li>
			</ul>
		</ul>
	</li>
</ul>

<h4>XML Post Directive for <b>Vimeo</b></h4>

<ul>
	<li>Set the ID to play a video from <b>Vimeo</b>:
		<ul>
			<li>Specify the Vimeo ID after the <b>vimeoVideoId:</b> string:</li>
			<li>
			&lt;vimeoVideoId:343068761></vimeoVideoId>
			</li>
			<li>
			Terminate the tag with a closing &lt;/vimeoVideoId>
			</li>
			<ul>
				<li>Real world example: <a href="hhttps://gregoryalexander.com/blog/2019/12/15/Embedding-a-Video-from-Vimeo-in-Galaxie-Blog">Embedding a Video from Vimeo in Galaxie Blog</a></li>
			</ul>
		</ul>
	</li>
</ul>

<h4>XML Post Directives to bypass ColdFusions' <b>Global Script Protection</b></h4>

<ul>
	<li>Use a <b>cfinclude:</b>
		<ul>
			<li>Enter the path to the template that you want to include after the <b>&lt;cfincludeTemplate:</b> string:</li>
			<li>&lt;cfincludeTemplate:/blog/includes/postContent/parallax/parallaxScript.cfm>&lt;/cfincludeTemplate&gt;</li>
		</ul>
	</li>
</ul>

<ul>
	<li>Include a <b>javascript</b> inside of a post</li>
		<ol>
			<li>Use the initial attachScript, and place the optional script type, if necessary, after <b>attachScript</b> string within a blog post like so:</li>
			&lt;attachScript>
			<li>Copy and paste the actual javascript</li>
			<li>alert("Hello World");</li>
			<li>And terminate the script with &lt;/attachScript>:</li>
			&lt;/attachScript>
		</ol>
	</li>
</ul>
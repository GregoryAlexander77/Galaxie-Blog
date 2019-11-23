<!doctype html>
<head>
	<!-- Plyr (our HTML5 media player) -->
	<script src="/blog/common/libs/plyr/plyr.js"></script>
	<!-- Defer the plyr css. -->
	<link rel="stylesheet" href="/blog/common/libs/plyr/plyr.css" />
</head>
<!--- This must be set to full screen. --->
<cfparam name="URL.videoUrl" default="https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-1080p.mp4">
<cfparam name="URL.poster" default="https://gregoryalexander.com/blog/enclosures/twitter/blueMoonTrailer.jpg">
<cfparam name="URL.crossOrigin" default="false">
	
<style>
.mediaPlayer video {
	width: 100% !important
}
</style>

<div class="mediaPlayer">
	<video
		controls
		<cfif URL.crossOrigin eq true>crossorigin</cfif>
		playsinline
		poster="<cfoutput>#URL.poster#</cfoutput>"
		id="player1">
		<!-- Video files -->
		<!-- 1280x720 --->
		<source
				src="<cfoutput>#URL.videoUrl#?id=#createUuid()#</cfoutput>"
			type="video/mp4"
			size="720"
		/>

	</video>
</div>

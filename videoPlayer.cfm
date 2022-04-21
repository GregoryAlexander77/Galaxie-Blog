<!doctype html>
<cfsilent>
<!---There can be multiple arguments to get the file. We can get the full path from the URL, or extract it from the database using the MediaId like we do when we are using the tinymce editor in the administrative site. --->
	
<!--- If the mediaId is in the URL, get the file path from the database --->
<cfparam name="URL.mediaId" default="">
<!--- We can pass in the full video file in the videoUrl --->
<cfparam name="URL.videoUrl" default="">
<!--- The poster  covers the video may be passed as well. --->
<cfparam name="URL.posterUrl" default="">
<!--- The WebVTT file allows captions --->
<cfparam name="URL.videoCaptionsUrl" default="">
<!--- Our default cross origin value should be set to false --->
<cfparam name="URL.crossOrigin" default="false">
<!--- Set the default provider arg (local, vimeo or youtube) --->
<cfparam name="provider" default="">
<cfparam name="youTubeId" default="">
<cfparam name="vimeoId" default="">

	
<!--- Note: the incoming URL from youTube or vimeo is something like so: 'https://gregorysblog.org/videoPlayer.cfm?videoUrl=https://www.youtube.com/watch?v=fhtw7Dpntb4&posterUrl=&videoCaptionsUrl='
We need to inspect the URL to determine the provider, ie youtube, vimeo or a local video file and adjust the code as necessary. --->
	
<!--- If the mediaId exists, get the URL to the video from the database --->
<cfif URL.mediaId neq "">
	<cfset videoUrl = application.blog.getMediaUrlByMediaId(URL.mediaId)>
	<cfset provider = "local">
<cfelse>
	<!--- Determine the provider (YouTube or Vimeo) --->
	<cfif URL.videoUrl contains 'youtube' or URL.videoUrl contains '/youtu.be'>
		<cfset provider = "youtube">
	<cfelseif URL.videoUrl contains 'vimeo'>
		<cfset provider = "vimeo">
	<cfelse>
		<cfset provider = "other">
	</cfif>
</cfif>
<!--- Get the current blog theme --->
<cfset kendoTheme = application.blog.getSelectedKendoTheme()>
</cfsilent><head>
	<!-- Plyr (our HTML5 media player) -->
	<cfoutput><script src="#application.baseUrl#/common/libs/plyr/plyr.js"></script>
	<!-- Defer the plyr css. -->
	<link rel="stylesheet" href="#application.baseUrl#/common/libs/plyr/themeCss/#kendoTheme#.css" /></cfoutput>
</head>		
<!---<cfoutput>#provider# #providerVideoId#</cfoutput>--->
	
<!-- This must be set to 100% -->	
<style>
.mediaPlayer video {
	width: 100% !important
}
</style>

<div class="mediaPlayer">
	<cfif URL.provider eq 'youTube'>
		<script type="#scriptTypeString#">
			const mediaplayerOptions = {
			  // Autoplay when in post mode. Don't autoplay in blog mode.
			  autoplay: <cfif getPageMode() eq 'post'>true<cfelse>false</cfif>,
			  playsinline: true,
			  clickToPlay: false,
			  controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
			  debug: true,
			  loop: { active: true }
			}

			const mediaplayer = new Plyr('#chr(35)#mediaplayer', mediaplayerOptions);
		</script>
		<div class="k-content wide">
			<br/>
			<div id="mediaplayer" data-plyr-embed-id="#providerVideoId#" data-plyr-provider="youtube" class="mediaPlayer lazy"></div>
		</div>
	<cfelseif URL.provider eq 'vimeo'>
		<script type="#scriptTypeString#">
			const mediaplayerOptions = {
			  // Autoplay when in post mode. Don't autoplay in blog mode.
			  autoplay: <cfif getPageMode() eq 'post'>true<cfelse>false</cfif>,
			  playsinline: true,
			  clickToPlay: false,
			   controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
			  debug: true,
			  loop: { active: true }
			}

			const mediaplayer = new Plyr('#chr(35)#mediaplayer', mediaplayerOptions);
		</script>
		<div class="k-content wide">
			<br/>
			<div id="mediaplayer" data-plyr-provider="vimeo" data-plyr-embed-id="#providerVideoId#" class="mediaPlayer lazy"></div>
		</div>
	<cfelse>
		<video
			controls
			<cfif URL.crossOrigin eq true>crossorigin</cfif>
			playsinline
			<cfif posterUrl neq "">poster="<cfoutput>#URL.posterUrl#</cfoutput></cfif>"
			id="player">
			<!-- Video files -->
			<!-- 1280x720 --->
			<source
				src="<cfoutput>#videoUrl#?id=#createUuid()#</cfoutput>"
				type="video/mp4"
				size="720"
			/>
		<cfif videoCaptionsUrl neq "">
			<!-- Caption files -->
			<track
				kind="captions"
				label="English"
				srclang="en"
				src="<cfoutput>#videoCaptionsUrl#</cfoutput>"
				default
			/>
		</cfif>

		</video>
	</cfif>
</div>

<!--- The Image Quality slider and its size estimate, at the top of an Upload Image window (11-05, owner: the slider looked
out of place in the Hero and Cover windows, so it moved to where the picture is chosen). Included by
enclosureUppyUploadWindow.cfm (window 74), heroCoverImageUppyUploadWindow.cfm (window 81), videoCoverUppyUploadWindow.cfm (window 75), imageUploadUppyUploadWindow.cfm (window 76, theme and profile pictures) and, for several pictures at once,
uppyGalleryAndCarousel.cfm (galleries and carousels, which fills in its own estimate). Each window passes its own
sliderId, so it never reads another open window's slider. The estimate is filled in by createStandaloneUppyUploadWindow()
(blogJsContent.cfm) once a picture is picked; pass the same ids to it as qualitySliderSelector and qualityEstimateSelector. --->
<cfparam name="sliderId" default="uploadQualitySlider">
<cfparam name="estimateHint" default="Pick a picture to see about how big it will be.">
<cfset defaultImageQuality = application.BlogOptionDbObj.getDefaultImageQuality()>
<cfoutput>
<style>
	<!--- Same "smaller file <-> sharper image" cue as the Blog Options default slider: red fading to green. --->
	###sliderId# .k-slider-track {
		background: linear-gradient(to right, ##d9534f, ##f0ad4e, ##5cb85c) !important;
		height: 6px;
	}
</style>
<div style="padding: 12px 12px 0 12px;">
	<label for="#sliderId#" style="margin-right: 12px;">Image Quality</label>
	<div id="#sliderId#" style="width: 260px; max-width: 100%;"></div>
	<span class="k-form-hint" style="display: block;">Left = smaller file, right = sharper image.</span>
	<span class="k-form-hint" id="#sliderId#Estimate" style="display: block;">#estimateHint#</span>
</div>
<script>
	$("###sliderId#").kendoSlider({
		min: 0.1,
		max: 1.0,
		value: #defaultImageQuality#,
		smallStep: 0.05,
		largeStep: 0.1,
		tickPlacement: "none",
		showButtons: false,
		tooltip: { format: "{0:p0}" }
	});
</script>
</cfoutput>

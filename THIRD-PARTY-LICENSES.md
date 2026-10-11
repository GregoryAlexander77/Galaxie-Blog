# Third-Party Licenses

Galaxie Blog is released under the Apache License 2.0 (see `LICENSE-2.0.txt`). It also includes the third-party libraries listed below, each under its own license. Those licenses apply to the bundled copies of the libraries, not to the rest of Galaxie Blog.

This file is a summary, not legal advice. The license text that ships with each library controls.

## Libraries that restrict commercial use

None. FancyBox 2, which previously restricted commercial use, has been replaced with GLightbox (see below).

## Libraries and their licenses

| Library | Used for | License | Notes |
|---|---|---|---|
| Kendo UI Core (`common/libs/kendoCore`) | Widgets, grids, windows | Free, open-source Kendo UI bundle | The commercial Kendo UI product is not included. |
| GLightbox 3.3.1 (`common/libs/glightbox`) | Enlarged view for galleries and images | MIT | License file included in the folder. |
| TinyMCE 5.5.1 (`common/libs/tinymce`) | Post editor | LGPL 2.1 | Galaxie Blog's changes are listed in `common/libs/tinymce/GALAXIE-PATCHES.txt`. |
| GreenSock TweenMax and ScrollToPlugin (`common/libs/greenSock`) | Animation | GreenSock "standard no charge" license | Club plugins, which are sold separately, are not used. |
| Swiper (`common/libs/swiper`) | Carousels | MIT | |
| Plyr (`common/libs/plyr`) | Video player | MIT | |
| three.js (`common/libs/three`) | Animated backgrounds | MIT | |
| Vanta.js (`common/libs/vanta`) | Animated backgrounds | MIT | |
| Uppy (`common/libs/uppy`) | Image and video uploads | MIT | |
| Day.js (`common/libs/dayjs`) | Dates | MIT | |
| Grapick (`common/libs/grapick`) | Gradient editor | MIT | |
| Pickr (`common/libs/pickr`) | Color picker | MIT | |
| jsGrid (`common/libs/jsGrid`) | Grids | MIT | |
| ScrollMagic (`common/libs/scrollMagic`) | Scroll effects | MIT | License file included in the folder. |
| Prism (`common/libs/prism`) | Code highlighting | MIT (code); CC0 or MIT (themes) | License files included in the folder. |
| CodeMirror 5 (`common/libs/codemirror5`) | Code editing | MIT | License file included in the folder. |
| get-video-id (`common/libs/get-video-id`) | Video links | MIT | License file included in the folder. |
| like-dislike (`common/libs/likeDislike`) | Reaction buttons | MIT | License file included in the folder. |
| p5.js (`common/libs/p5`) | Included library | LGPL 2.1 | |

## Services

| Service | Used for | Terms |
|---|---|---|
| Azure Maps | Maps and routes | Microsoft's terms apply. Each site supplies its own key, and usage is billed to that account. |

## Notes for maintainers

- Several libraries do not include a license file in this repository. Their licenses above are taken from each project's public license. Add the license file to each library's folder before release.
- Keep this file in step with the "Software and Licenses" page in the Galaxie Blog docs.

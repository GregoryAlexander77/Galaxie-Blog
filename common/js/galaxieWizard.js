/*
	Galaxie Wizard (5.0, 2026-10-20): a step-by-step form like Kendo UI's Wizard - numbered steps along the top, Previous / Next /
	Done buttons - for pages that run on the free Kendo UI Core, which has no Wizard (it's in Kendo UI Professional only, which
	Galaxie can't ship). Used by the Site Wizard (admin/setup.cfm) and the installer (installer/initial/index.cfm). It takes the same
	options and events the Kendo Wizard did there, so either page reads the same:

		var wizard = $("#wizard").galaxieWizard({
			steps: [{ title: "Your site", content: "<div>...</div>", buttons: ["previous", "next"] }, ...],   // "done" on the last
			stepper: { linear: false },        // false: any step number can be clicked; true: only steps already reached
			select: function (e) { ... },      // before a move the user asked for: e.step.options.index, e.preventDefault()
			activate: function (e) { ... },    // after a step is shown: e.step.options.index
			done: function (e) { ... }         // the Done button: e.preventDefault()
		}).data("galaxieWizard");
		wizard.select(2);                      // shows a step (no select event, as with Kendo); activate still runs
		wizard.activeStep().options.index;

	Looks: Kendo's own button classes (k-button, k-primary) and the theme's colors where it can, so it sits with the other Kendo
	widgets on the page.
*/
(function ($) {
	var STYLE_ID = "galaxieWizardStyles";
	var CSS = [
		".gw{display:flex;flex-direction:column;min-height:0}",
		".gw-stepper{display:flex;list-style:none;margin:0;padding:14px 4px 8px;counter-reset:gw}",
		".gw-step{flex:1 1 0;min-width:0;position:relative;text-align:center}",
		".gw-step:before{content:'';position:absolute;top:16px;left:-50%;width:100%;height:2px;background:#d8dde3;z-index:0}",
		".gw-step:first-child:before{display:none}",
		".gw-step.gw-reached:before{background:var(--gw-accent,#007bff)}",
		".gw-step button{position:relative;z-index:1;border:0;background:none;padding:0;font:inherit;color:inherit;cursor:pointer;display:inline-flex;flex-direction:column;align-items:center;gap:6px;max-width:100%}",
		".gw-step button:disabled{cursor:default}",
		".gw-num{width:32px;height:32px;border-radius:50%;border:2px solid #c3c9d0;background:#fff;color:#5d6670;display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:bold;transition:background .15s,border-color .15s}",
		".gw-step.gw-reached .gw-num{border-color:var(--gw-accent,#007bff);color:var(--gw-accent,#007bff)}",
		".gw-step.gw-current .gw-num{background:var(--gw-accent,#007bff);border-color:var(--gw-accent,#007bff);color:#fff}",
		".gw-step button:not(:disabled):hover .gw-num{box-shadow:0 0 0 4px rgba(0,123,255,.18)}",
		".gw-label{font-size:13px;color:#5d6670;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:100%}",
		".gw-step.gw-current .gw-label{color:inherit;font-weight:bold}",
		".gw-content{flex:1 1 auto;min-height:0;overflow:auto}",
		".gw-panel{display:none}.gw-panel.gw-shown{display:block}",
		".gw-buttons{display:flex;gap:8px;align-items:center;justify-content:space-between;padding:12px 4px 0;border-top:1px solid #d8dde3;margin-top:8px}",
		".gw-buttons .gw-right{display:flex;gap:8px;margin-left:auto}",
		".gw-pager{font-size:13px;color:#5d6670}",
		"@media (max-width:600px){.gw-label{display:none}.gw-step.gw-current .gw-label{display:block;position:absolute;top:40px;left:50%;transform:translateX(-50%)}.gw-stepper{padding-bottom:28px}}"
	].join("");

	function addStyles() {
		if (document.getElementById(STYLE_ID)) { return; }
		var style = document.createElement("style");
		style.id = STYLE_ID;
		style.textContent = CSS;
		document.head.appendChild(style);
	}

	function Wizard(element, options) {
		var self = this;
		this.element = $(element);
		this.options = $.extend({ steps: [], stepper: { linear: false } }, options);
		this.current = 0;
		this.reached = 0;
		addStyles();
		this.element.addClass("gw").empty();
		this.stepper = $('<ol class="gw-stepper" role="list"></ol>').appendTo(this.element);
		this.content = $('<div class="gw-content"></div>').appendTo(this.element);
		this.buttons = $('<div class="gw-buttons"></div>').appendTo(this.element);
		this.panels = [];
		$.each(this.options.steps, function (i, step) {
			var item = $('<li class="gw-step"></li>').appendTo(self.stepper);
			var button = $('<button type="button"></button>').attr("aria-label", "Step " + (i + 1) + ": " + step.title)
				.append($('<span class="gw-num"></span>').text(i + 1), $('<span class="gw-label"></span>').text(step.title))
				.on("click", function () { self.go(i); });
			item.append(button);
			var panel = $('<div class="gw-panel" role="group"></div>').attr("aria-label", step.title).append(step.content || "").appendTo(self.content);
			self.panels.push(panel);
		});
		this.show(0);
	}

	Wizard.prototype.stepInfo = function (index) { return { options: { index: index, title: (this.options.steps[index] || {}).title } }; };
	Wizard.prototype.activeStep = function () { return this.stepInfo(this.current); };

	// A move the user asked for (a step number, Previous or Next): the select event can stop it.
	Wizard.prototype.go = function (index) {
		if (index === this.current || index < 0 || index >= this.panels.length) { return; }
		if (this.options.stepper && this.options.stepper.linear && index > this.reached) { return; }
		var stopped = false;
		if (typeof this.options.select === "function") {
			this.options.select.call(this, { sender: this, step: this.stepInfo(index), preventDefault: function () { stopped = true; } });
		}
		if (!stopped) { this.show(index); }
	};

	// Shows a step without asking (as Kendo's select() does); activate still runs.
	Wizard.prototype.select = function (index) {
		if (index < 0 || index >= this.panels.length) { return; }
		this.show(index);
	};

	Wizard.prototype.show = function (index) {
		var self = this, step = this.options.steps[index] || {};
		this.current = index;
		this.reached = Math.max(this.reached, index);
		$.each(this.panels, function (i, panel) { panel.toggleClass("gw-shown", i === index); });
		this.stepper.children().each(function (i) {
			$(this).toggleClass("gw-current", i === index).toggleClass("gw-reached", i <= self.reached);
			$(this).find("button").prop("disabled", i === index || (self.options.stepper && self.options.stepper.linear && i > self.reached))
				.attr("aria-current", i === index ? "step" : null);
		});
		// The buttons for this step.
		this.buttons.empty();
		var names = step.buttons || ["previous", "next"];
		if (names.indexOf("previous") >= 0) {
			this.buttons.append($('<button type="button" class="k-button">Previous</button>').on("click", function () { self.go(self.current - 1); }));
		}
		this.buttons.append($('<span class="gw-pager"></span>').text("Step " + (index + 1) + " of " + this.panels.length));
		var right = $('<span class="gw-right"></span>').appendTo(this.buttons);
		$.each(names, function (i, b) {
			var name = typeof b === "string" ? b : b.name, text = typeof b === "string" ? null : b.text;
			if (name === "next") {
				right.append($('<button type="button" class="k-button k-primary"></button>').text(text || "Next").on("click", function () { self.go(self.current + 1); }));
			} else if (name === "done") {
				right.append($('<button type="button" class="k-button k-primary"></button>').text(text || "Done").on("click", function () {
					var stopped = false;
					if (typeof self.options.done === "function") { self.options.done.call(self, { sender: self, preventDefault: function () { stopped = true; } }); }
				}));
			}
		});
		this.content.scrollTop(0);
		if (typeof this.options.activate === "function") { this.options.activate.call(this, { sender: this, step: this.stepInfo(index) }); }
	};

	$.fn.galaxieWizard = function (options) {
		return this.each(function () {
			if (!$(this).data("galaxieWizard")) { $(this).data("galaxieWizard", new Wizard(this, options)); }
		});
	};
})(jQuery);

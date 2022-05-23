// 复制于 Documenter.jl(MIT) ，有删改
requirejs.config({
	paths: {
		'headroom': 'https://cdnjs.cloudflare.com/ajax/libs/headroom/0.10.3/headroom.min',
		'jqueryui': 'https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min',
		'jquery': 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.4.1/jquery.min',
		'headroom-jquery': 'https://cdnjs.cloudflare.com/ajax/libs/headroom/0.10.3/jQuery.headroom.min',
	},
	shim: {
		"headroom-jquery": {
			"deps": [
				"jquery",
				"headroom"
			]
		},
	}
});
require(['jquery', 'headroom', 'headroom-jquery'], function ($, Headroom) {

	// Manages the top navigation bar (hides it when the user starts scrolling down on the
	// mobile).
	window.Headroom = Headroom; // work around buggy module loading?
	$(document).ready(function () {
		$('#documenter .docs-navbar').headroom({
			"tolerance": { "up": 10, "down": 10 },
		});
	})

})
require(['jquery'], function ($) {

	// Modal settings dialog
	$(document).ready(function () {
		var settings = $('#documenter-settings');
		$('#documenter-settings-button').click(function () {
			settings.toggleClass('is-active');
		});
		// Close the dialog if X is clicked
		$('#documenter-settings button.delete').click(function () {
			settings.removeClass('is-active');
		});
		// Close dialog if ESC is pressed
		$(document).keyup(function (e) {
			if (e.keyCode == 27) settings.removeClass('is-active');
		});
	});

})
require(['jquery'], function ($) {

	// Manages the showing and hiding of the sidebar.
	$(document).ready(function () {
		var sidebar = $("#documenter > .docs-sidebar");
		var sidebar_button = $("#documenter-sidebar-button")
		sidebar_button.click(function (ev) {
			ev.preventDefault();
			sidebar.toggleClass('visible');
			if (sidebar.hasClass('visible')) {
				// Makes sure that the current menu item is visible in the sidebar.
				$("#documenter .docs-menu a.is-active").focus();
			}
		});
		$("#documenter > .docs-main").bind('click', function (ev) {
			if ($(ev.target).is(sidebar_button)) {
				return;
			}
			if (sidebar.hasClass('visible')) {
				sidebar.removeClass('visible');
			}
		});
	})

	// Resizes the package name / sitename in the sidebar if it is too wide.
	// Inspired by: https://github.com/davatron5000/FitText.js
	$(document).ready(function () {
		e = $("#documenter .docs-autofit");
		function resize() {
			var L = parseInt(e.css('max-width'), 10);
			var L0 = e.width();
			if (L0 > L) {
				var h0 = parseInt(e.css('font-size'), 10);
				e.css('font-size', L * h0 / L0);
				// TODO: make sure it survives resizes?
			}
		}
		// call once and then register events
		resize();
		$(window).resize(resize);
		$(window).on('orientationchange', resize);
	});

	// Scroll the navigation bar to the currently selected menu item
	$(document).ready(function () {
		var sidebar = $("#documenter .docs-menu").get(0);
		var active = $("#documenter .docs-menu .is-active").get(0);
		if (typeof active !== 'undefined') {
			sidebar.scrollTop = active.offsetTop - sidebar.offsetTop - 15;
		}
	})
})
require(['jquery'],function($){
	var tURL=$("#tURL")[0].content
	var pi=$("#documenter-themepicker")
	pi.bind('change',function(){
		// 更改主题
		var theme=pi[0].value
		$("#theme-href")[0].href=tURL+"css/"+theme+".css"
		localStorage.setItem("theme",theme)
	})
	$(document).ready(function(){
		// 初始化主题
		var theme=localStorage.getItem("theme")
		if(theme==undefined)theme="light"
		$("#theme-href")[0].href=tURL+"css/"+theme+".css"
		for(tag of pi[0]){
			if(tag.value==theme){
				tag.selected=true
				break
			}
		}
		
	})
	$(".docs-menu").ready(function(){
		// 侧边栏
		const _menu=menu.replaceAll("$",tURL)
		$(".docs-menu")[0].innerHTML=_menu
	})
})

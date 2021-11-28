// Change tab
$(document).on('click', '#profile-material-tabs ul li', function() {
	console.log("MATERIAL");
	$('#profile-material-tabs ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-tab-content").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

});

// Hide and show table of tabs
$(document).on('click', '#profile-hide-tabs ul li', function() {
	console.log("IDEAL");
	$("#wall-bit").toggleClass('vanish');
	$("#profile-tabs-content").toggleClass('vanish');
	$(this).find('a span i').toggleClass('fa-caret-up fa-caret-down');
});
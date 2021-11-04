$(document).on('click', '#profile-material-tabs ul li', function() {
	console.log("MATERIAL");
	$('#profile-material-tabs ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-tab-content").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

});

$(document).on('click', '#profile-hide-tabs ul li', function() {
	console.log("IDEAL");
	$("#profile-tabs-content").toggleClass('vanish');
	$(this).find('a span i').toggleClass('fa-caret-up fa-caret-down');
});
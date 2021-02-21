$(document).on('click', 'ul li', function() {
	$('ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-associate").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

})
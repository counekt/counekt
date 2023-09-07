// Change tab
$(document).on('click', '#structure-tabs ul li', function() {
	console.log("STRUCTURE");
	if ($(this).hasClass('is-active')) {
		$('#structure-tabs ul li').removeClass('is-active');
	}

	else {
	$('#structure-tabs ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".structure-tab-content").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');
	}
});
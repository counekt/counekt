// Change tab
$(document).on('click', '#profile-material-tabs ul li', function() {
	console.log("MATERIAL");
	if ($(this).hasClass('is-active')) {
		$('#profile-material-tabs ul li').removeClass('is-active');
		hideTabs();
	}

	else {
	showTabs();
	$('#profile-material-tabs ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-tab-content").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');
	}
});

// Hide and show table of tabs
$(document).on('click', '#profile-hide-tabs ul li', function() {
	console.log("IDEAL");
	$('#profile-material-tabs ul li').removeClass('is-active');
	$("#wall-bit").toggleClass('vanish');
	$("#profile-tabs-content").toggleClass('vanish');
	$(this).find('a span i').toggleClass('fa-caret-up fa-caret-down');
});

function hideTabs() {
	$('#profile-hide-tabs ul li').find('a span i').addClass('fa-caret-down').removeClass('fa-caret-up');
	$("#wall-bit").removeClass('vanish');
	$("#profile-tabs-content").addClass('vanish');
	
}

function showTabs() {
	$('#profile-hide-tabs ul li').find('a span i').addClass('fa-caret-up').removeClass('fa-caret-down');
	$("#profile-tabs-content").removeClass('vanish');
	$("#wall-bit").addClass('vanish');
}
$(document).on('click','#more-button', function(event) {
	event.stopPropagation();
if ($(this).data('status') === 'closed') {
	openMore();
}
else if ($(this).data('status') === 'open') {
	closeMore();
}
});

function closeMore() {
	$('#more-button').data('status','closed');
	$('#more-button').removeClass($('#more-button').data('open')).addClass($('#more-button').data('closed'));
	$('#more').addClass('invisible');
	$('#more').hide();

}

function openMore () {
	$('#more-button').data('status','open');
	$('#more-button').removeClass($('#more-button').data('closed')).addClass($('#more-button').data('open'));
	$('#more').show();
	$('#more').removeClass('invisible');
}

$('#more').hide();

$(window).click(function() {
//Hide the menus if visible
closeMore();
});

$(document).on('click','#wallet-button', function(event) {
	event.stopPropagation();
if ($(this).data('status') === 'closed') {
	openWalletDetails();
}
else if ($(this).data('status') === 'open') {
	closeWalletDetails();
}
});

function closeWalletDetails() {
	$('#wallet-button').data('status','closed');
	$('#wallet-button').removeClass($('#wallet-button').data('open')).addClass($('#wallet-button').data('closed'));
	$('#wallet-details').addClass('invisible');
	$('#wallet-details').hide();

}

function openWalletDetails () {
	$('#wallet-button').data('status','open');
	$('#wallet-button').removeClass($('#wallet-details').data('closed')).addClass($('#wallet-button').data('open'));
	$('#wallet-details').show();
	$('#wallet-details').removeClass('invisible');
}

$('#wallet-details').hide();

$(window).click(function() {
//Hide the menus if visible
closeWalletDetails();
});

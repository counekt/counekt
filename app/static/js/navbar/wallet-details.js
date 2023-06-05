$(document).on('click','#wallet-button', function(event) {
	event.stopPropagation();
if ($(this).data('status') === 'closed') {
	openWalletDetails();
}
else if ($(this).data('status') === 'open') {
	closeWalletDetails();
}
});

$('#wallet-details').hide();


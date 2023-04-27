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

$(window).click(function(event) {
//Hide the menus if visible
var $target = $(event.target);
 if(!$target.closest('#wallet-details').length) {
closeWalletDetails();
}});


$(document).on('click','#connect-wallet-button', function() {
	checkIfInstalled();
	connectMetaMaskWallet();
});

function checkIfInstalled() {
	if (typeof window.ethereum == 'undefined') {
		flash("Wallet Provider isn't installed!");
	}
	else {
		flash("Good to go!");
	}

}

async function connectMetaMaskWallet() {
	try {
		const accounts = await window.ethereum.request({ method:'eth_requestAccounts'});
	}
	catch(e) {
		flash(e.message);
		return;
	};
	if (!accounts) {return;}
	window.walletAddress = accounts[0];
	flash(window.walletAddress);
}
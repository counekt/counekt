$(document).on('click','#wallet-button', function(event) {
	event.stopPropagation();
if ($(this).data('status') === 'closed') {
	openWalletDetails();
}
else if ($(this).data('status') === 'open') {
	closeWalletDetails();
}
});

var web3Provider = undefined;

function closeWalletDetails() {
	$('#wallet-button').data('status','closed');
	$('#wallet-button').removeClass($('#wallet-button').data('open')).addClass($('#wallet-button').data('closed'));
	$('#wallet-details').addClass('invisible');
	$('#wallet-details').hide();

}

function openWalletDetails () {
	checkIfConnected(false);
	checkWalletBalance();
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
	checkIfConnected();
	checkWalletBalance();
});

function checkIfInstalled() {
	if (!walletIsInstalled()) {
		flash("Wallet Provider isn't installed!");
       	window.open("https://metamask.io/download/", "_blank");
	}
	else {
		flash("Good to go!");
	}

}

async function checkIfConnected(quickfix=true) {
	const isConnected = await walletIsConnected();
	if (!isConnected) {
		if (quickfix) {connectMetaMaskWallet();}
	}
	else {
		$("#connect-wallet-button").addClass("is-info").addClass("is-light");
		$("#connect-wallet-button span.text").text("Connected");
		if (quickfix) {flash("Your wallet is already connected!");}
	}

}

async function connectMetaMaskWallet() {
	
	const accounts = await window.ethereum.request({ method:'eth_requestAccounts'})
	.catch((e) => {
		flash(e.message);
		return;
	});
	if (!accounts) {return;}
	window.walletAddress = accounts[0];
	checkIfConnected(false);
	flash(window.walletAddress);
}

function walletIsInstalled() {
	if (typeof window.ethereum == 'undefined') {
		return false;
	}
	return true;
}

function getWeb3Provider() {
	if (!web3Provider) {
		web3Provider = new Web3(window.ethereum);
	}
	return web3Provider;
}

async function getWalletBalance() {
	const web3 = getWeb3Provider();
	const accounts = await web3.eth.getAccounts().catch((e) => flash(e.message));
	const address = accounts[0];
	// Get the balance of the connected wallet
  	const balanceWei = await web3.eth.getBalance(address);
  	console.log(balanceWei);
  	return balanceWei;
}	

async function checkWalletBalance() {
	const web3 = getWeb3Provider();
	const balanceWei = await getWalletBalance();
	const balanceEther = web3.utils.fromWei(balanceWei.toString(), 'ether');
	$('#eth-balance').text(balanceEther);
}

async function walletIsConnected() {
	const web3 = getWeb3Provider();
	const accounts = await web3.eth.getAccounts().catch((e) => flash(e.message));
	if (accounts.length === 0) {
		return false;
	}
	return true;
}


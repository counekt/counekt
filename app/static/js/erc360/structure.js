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

$(document).on('click', '#deposit-button', function() {

	openDepositWindow();

});


async function openDepositWindow() {
	// Replace 'recipientAddress' with the Ethereum address you want to send funds to
	const recipientAddress = $("#erc360-address").text();

	// Specify the minimal transaction details without the 'value' field
	const transactionDetails = {
	  to: recipientAddress,
	  data: '0x', // Empty data field
	};

	const web3 = getWeb3Provider();
	const accounts = await web3.eth.getAccounts().catch((e) => console.log(e.message));

	let send = web3.eth.sendTransaction({from:accounts[0],to:recipientAddress, value:web3.utils.toWei("0.1", "ether")}).catch((error) => {
      console.error(error);
    });
}
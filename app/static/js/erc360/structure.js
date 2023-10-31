
$(document).on('keypress','#deposit-amount-input, #transfer-amount-input',function(event) {
    var key = event.keyCode || event.charCode;
    if (key < 48 || key > 57) {
      if (key == 44 || key == 46) {
      	const string = $(this).val()
      	if (string.includes(',') || string.includes('.')) {
      		return false;
      	}
      	return true;
      }
      if (key == 13) {
        $(this).blur();
      }
      return false;
    }

  });

function formatAmountInput(string) {
	if (string.startsWith(',') || string.startsWith('.')) {
	  string = '0' + string;
	}

  return string.replace(/^0+/,'0').replace(/^0(?=[1-9])/,'');
}



function formatTransferAmountInput() {
	$this = $('#transfer-amount-input');
	var amount = getTransferValue();
	const max_amount = parseFloat($this.attr('max'));
	if (amount>max_amount) {
			amount = max_amount;
		  $this.val(amount);
	}
	const amount_in_decimals = amount * 10**parseInt($this.data('decimals'));
	console.log(amount_in_decimals,amount);
	$('#transfer-amount-progress-bar').val(amount_in_decimals);
   $('#transfer-amount-span').text(amount);
}

$(document).on('blur input','#deposit-amount-input',function(event) {
	$(this).val(formatAmountInput($(this).val()));
	checkDepositable();
 });

$(document).on('blur input','#transfer-amount-input',function(event) {
	$(this).val(formatAmountInput($(this).val()));
	formatTransferAmountInput();
	checkTransferable();
 });

$(document).on('click', '#deposit', function() {
	openDepositWindow();
});

function getDepositValue() {
	return parseFloat($('#deposit-amount-input').val().replace(',','.'));
}

function getTransferValue() {
	return parseFloat($('#transfer-amount-input').val().replace(',','.'));
}

function checkDepositAmount() {
	if (getDepositValue()>0) {
      	$('#deposit-amount-input').addClass('is-success').removeClass('is-danger');
      	return true;
	}
	else {
	$('#deposit-amount-input').addClass('is-danger').removeClass('is-success');
	return false;
	}
}

function checkTransferAmount() {
	if (getTransferValue()>0) {
      	$('#transfer-amount-input').addClass('is-success').removeClass('is-danger');
      	return true;
	}
	else {
	$('#transfer-amount-input').addClass('is-danger').removeClass('is-success');
	return false;
	}
}

function checkDepositable() {
  var amountCheck = checkDepositAmount();
  if (amountCheck) {
    $("#deposit").prop('disabled',false);
  } else {$("#deposit").prop('disabled',true);}
}

function checkTransferable() {
  var amountCheck = checkTransferAmount();
  if (amountCheck) {
    $("#transfer").prop('disabled',false);
  } else {$("#transfer").prop('disabled',true);}
}


async function openDepositWindow() {
	// Replace 'recipientAddress' with the Ethereum address you want to send funds to
	if (!makeSureWalletConnected()) {return;}

	const recipientAddress = $("#erc360-address").text();
	const web3 = getWeb3Provider();
	const network = await web3.eth.net.getNetworkType();
	console.log(network == "main");
	const accounts = await web3.eth.getAccounts().catch((e) => console.log(e.message));

	let send = web3.eth.sendTransaction({from:accounts[0],to:recipientAddress, value:web3.utils.toWei(getDepositValue().toString(), "ether")}).catch((error) => {
      console.error(error);
    });
}

function update_structure(address) {
        console.log("updating...");
        $("#reload-structure").prop('disabled', true);$("#reload-structure").addClass('is-loading');
        $.post("/€"+address+"/update/structure/",function(response) {
                $.get("/€"+address+"/get/structure/", function(structure, status) {
                        $("#structure-modal").replaceWith(structure);
                        $("#reload-structure").removeClass('is-loading').prop('disabled', false);
                        console.log("success!");
        });
        });
        
}

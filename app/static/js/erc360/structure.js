
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
	const max_amount_str = $this.attr('max');
	const max_amount = parseFloat(max_amount_str);
	const min_amount_str = $this.attr('min');
	const min_amount = parseFloat(min_amount_str);

	if (amount>max_amount) {
			amount = max_amount;
		  $this.val(max_amount_str);
	} else if (amount<min_amount && amount != 0) {
		amount = min_amount;
		$this.val(min_amount_str);
	}
	const amount_in_decimals = amount * 10**parseInt($this.data('decimals'));
	console.log(amount_in_decimals,amount);
	$('#transfer-amount-progress-bar').val(amount_in_decimals);
   $('#transfer-amount-span').text(amount);
}

$(document).on('blur input','#deposit-amount-input',function(event) {
	checkDepositable();
 });

$(document).on('blur input','#transfer-amount-input',function(event) {
	checkTransferAmount(true);
	checkTransferable();
 });

$(document).on('blur input','#transfer-recipient-input',function(event) {
    checkTransferRecipient(true);
    checkTransferable();
 });

$(document).on('click', '#deposit', function() {
	openDepositWindow();
});

function getDepositValue() {
	return parseFloat($('#deposit-amount-input').val().replace(',','.')) || 0;
}

function getTransferValue() {
	return parseFloat($('#transfer-amount-input').val().replace(',','.')) || 0;
}

function getTransferRecipient() {
  return $('#transfer-recipient-input').val();
}


function checkDepositAmount() {
	const $this = $('#deposit-amount-input');
	$this.val(formatAmountInput($this.val()));
	if (getDepositValue()>0) {
      	$this.addClass('is-success').removeClass('is-danger');
      	return true;
	}
	else {
	$this.addClass('is-danger').removeClass('is-success');
	return false;
	}
}

function checkTransferAmount() {
	const $this = $('#transfer-amount-input');
	$this.val(formatAmountInput($this.val()));
	formatTransferAmountInput();
	if (getTransferValue()>0) {
      	$this.addClass('is-success').removeClass('is-danger');
      	return true;
	}
	else {
	$this.addClass('is-danger').removeClass('is-success');
	return false;
	}
}

async function checkTransferRecipient(feedback=false) {
	$this = $('#transfer-recipient-input')
  var text = getTransferRecipient();
  console.log("XXX");
  console.log(text);
  var isAddress = await getWeb3Provider().utils.isAddress(text);
  console.log(isAddress);
  if (!feedback) {return isAddress;}
  console.log(isAddress);
  if (isAddress) {
    $this.addClass('is-success').removeClass('is-danger');
    return true;
  } else {
    displayInvalidTransferRecipient();
    return false;
  }
}

function displayInvalidTransferRecipient() {
  message("Invalid address", ['recipient'], true);
  $('#transfer-recipient-input').addClass('is-danger').removeClass('is-success');
}


function checkDepositable() {
  const amountCheck = checkDepositAmount();
  if (amountCheck) {
    $("#deposit").prop('disabled',false);
  } else {$("#deposit").prop('disabled',true);}
}

function checkTransferable() {
  const amountCheck = checkTransferAmount();
  const recipientCheck = checkTransferRecipient();
  if (amountCheck && recipientCheck) {
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

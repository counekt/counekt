function checkMintable() {
  var amountCheck = checkAmount();
  var recipientCheck = checkRecipient()
  if (amountCheck && recipientCheck) {
    $("#mint").prop('disabled',false);
  } else {$("#mint").prop('disabled',true);}
}

function checkAmount(feedback=false) {
  
  string_amount = getAmount();
  var isValid = string_amount != 0;
  if (!feedback) {return isValid;}
  const original_amount = parseInt($('#mint-amount-span').data('original-amount'));
  console.log(original_amount);
  if ((parseInt(string_amount)+original_amount)>2**256-1) {string_amount = (BigInt("115792089237316195423570985008687907853269984665640564039457584007913129639935")-BigInt(original_amount)).toString();}
  const amount = Math.min(parseInt(string_amount),2**256-1-original_amount);
  const new_amount = original_amount+amount;
  console.log(new_amount);
  if (new_amount == 0) {var progress_bar_val = 0;}
  else {var progress_bar_val = Math.log2(new_amount);}
    $('#mint-amount-input').val(string_amount);
    $('#mint-amount-progress-bar').val(progress_bar_val);
    $('#mint-amount-span').html(new_amount.toPrettyExponential());
    if (isValid) {
      $('#mint-amount-input').addClass('is-success').removeClass('is-danger');
      return true;
    } else {
      displayInvalidAmount();
      return false;
      }
}

function checkRecipient(feedback=false) {
  console.log("recipient");
  var text = getRecipient();
  var isAddress = getWeb3Provider().utils.isAddress(text);
  if (!feedback) {return isAddress;}
  console.log(isAddress);
  if (isAddress) {
    $('#mint-recipient-input').addClass('is-success').removeClass('is-danger');
    return true;
  } else {
    displayInvalidRecipient();
    return false;
  }
}

function getRecipient() {
  return $('#mint-recipient-input').val();
}

function getAmount() {
  return formatNonZeroAmountInput($('#mint-amount-input').val()) || '0';
}

function displayInvalidAmount() {
  $('#mint-amount-input').addClass('is-danger').removeClass('is-success');
}

function displayInvalidRecipient() {
  message("Invalid address", ['recipient'], true);
  $('#mint-recipient-input').addClass('is-danger').removeClass('is-success');
}


$(document).on('keypress','#mint-recipient-input',function(event) {
    var key = event.keyCode || event.charCode;
      if (key == 13) {
        $(this).blur();
        return false;
      }

  });

$(document).on('blur input','#mint-recipient-input',function(event) {
    checkRecipient(true);
    checkMintable();
 });

$(document).on('blur input','#mint-amount-input',function(event) {
  checkAmount(true);
  checkMintable();
});

$(document).on('keypress','#mint-amount-input',function(event) {
    var key = event.keyCode || event.charCode;
    if (key < 48 || key > 57) {
      if (key == 13) {
        $(this).blur();
      }
      return false;
    }

  });



Number.prototype.toPrettyExponential = function() {
  if(this.valueOf()<10000) {
    return this.valueOf()
  }
   var split = (this.toExponential() + '').split("e");
   var mantissa = parseFloat(split[0]);
   var exponent = parseInt(split[1]);
   return Math.floor(mantissa*100)/100+" x 10"+"<sup>"+exponent+"</sup>";
};

function formatNonZeroAmountInput(string) {
  const pattern = /^0+/;
  return string.replace(pattern,'');
}

$(document).on('click', '#mint', function() {
  console.log("CLICK");
  $(this).prop('disabled', true).addClass('is-loading');

   var abi = $.getJSON("/erc360corporatizable/abi/", function(abi) {
        uploadMint(abi);
     });
});



async function uploadMint(abi) {
    const tx = await mintERC360(abi,address,getRecipient(),getAmount());

    if (tx) {

    console.log("continuing...");
    var formData = new FormData();
    formData.append('tx', tx);
    $.post({
      type: "POST",
      url: "/erc360/"+address+"/mint/",
      data: formData,
      processData: false,
      contentType: false,
      async success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") { 
            update_ownership(address);
            changeToOwnership();
        }
        else{stopButtonLoading();message(status, response["box_id"], true);}
        
      }});
  }
}

async function mintERC360(tokenABI,tokenAddress,account,amount) {
  console.log(tokenABI);
  console.log(tokenAddress);
  console.log(account);
  console.log(amount);
  // Address of the original erc360 contract
  const web3 = getWeb3Provider();

    try {

    console.log("contract code");
    const accounts = await web3.eth.getAccounts().catch((e) => console.log(e.message));
    if (!makeSureWalletConnected()) {return;}
    console.log(accounts);
    console.log("get accounts");
    const ERC360 = new web3.eth.Contract(tokenABI,tokenAddress);
    console.log("parse contract");
    console.log(accounts[0]);
    const mint = ERC360.methods.mint(account,amount);
    console.log("basic mint");

    const parameters = {
      from: accounts[0]
    };

    var tx;
    const mintTransaction = await mint.send(parameters, (err, transactionHash) => {
      tx = transactionHash;
    console.log(err);
    console.log('Transaction Hash :', transactionHash);
}).on('confirmation', () => {return true});


    console.log('Tokens minted:', mintTransaction);
    return tx;
  } catch (error) {
    console.error('Error Minting Tokens:', error);
  }

}
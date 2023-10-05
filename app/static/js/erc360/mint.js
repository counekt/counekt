//web3.utils.isAddress(address)

$(document).on('keypress','#mint-recipient-input',function(event) {
    var key = event.keyCode || event.charCode;
      if (key == 13) {
        $(this).blur();
        return false;
      }

  });

$(document).on('focusout','#mint-recipient-input',function(event) {
    if (true) {message("Invalid address", ['recipient'], true)}
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

$(document).on('focusout','#mint-amount-input',function(event) {

  var string_amount = formatAmountInput($('#mint-amount-input').val()) || '0';
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

function formatAmountInput(string) {
  const pattern = /^0+/;
  return string.replace(pattern,'');
}

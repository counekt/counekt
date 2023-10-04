
$(document).on('keypress','#mint-amount-input',function(event) {
    var key = event.keyCode || event.charCode;
    if (key < 48 || key > 57) {
      return false;

    }
  });

$(document).on('focusout','#mint-amount-input',function(event) {

  var string_amount = formatAmountInput($('#mint-amount-input').val()) || '0';
  if (parseInt(string_amount)>2**256-1) {string_amount = "115792089237316195423570985008687907853269984665640564039457584007913129639935";}
  const original_amount = parseInt($('#mint-amount-span').data('original-amount'));
  const amount = Math.min(parseInt(string_amount),2**256-1-original_amount);
  const new_amount = original_amount+amount;
  console.log(new_amount);
  if (new_amount == 0) {var progress_bar_val = 0;}
  else {var progress_bar_val = Math.log2(new_amount);}
    $('#mint-amount-input').val(string_amount);
    $('#mint-amount-progress-bar').val(progress_bar_val);
    $('#mint-amount-span').text(new_amount);

  
});

function formatAmountInput(string) {
  const pattern = /^0+/;
  return string.replace(pattern,'');
}


console.log("YE");
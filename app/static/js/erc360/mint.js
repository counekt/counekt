
$(document).on('keypress','#mint-amount-input',function(event) {
    var key = event.keyCode || event.charCode;
    if (key < 48 || key > 57) {
      return false;

    }
  });

$(document).on('focusout','#mint-amount-input',function(event) {
  var amount = parseInt($('#mint-amount-input').val());
  if (amount) {
    $('#mint-amount-input').val(amount);
    $('#mint-amount-progress-bar').val(Math.log2(amount)||0);
    $('#mint-amount-span').text(amount);
  }

  
});

console.log("YE");
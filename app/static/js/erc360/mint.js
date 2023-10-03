
$(document).on('keypress','#mint-amount-input',function(event) {
    var key = event.keyCode || event.charCode;
    if (key < 48 || key > 57) {
      return false;

    }
  });

$(document).on('focusout','#mint-amount-input',function(event) {
  var amount = $('#mint-amount-input').val();
  if (amount) {$('#mint-amount-input').val(parseInt(amount));}
  
});

console.log("YE");
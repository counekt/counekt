function update_structure(address) {
        console.log("updating...");
        $("#reload-structure").prop('disabled', true);$("#reload-structure").addClass('is-loading');
        $.post("/€"+address+"/update/structure/",function(response) {
                // update structure tab
                $.get("/€"+address+"/get/structure/", function(structure, status) {
                        STRUCTURE_HTML = structure;
                        $("#structure-modal").replaceWith(structure);
                        $("#reload-structure").removeClass('is-loading').prop('disabled', false);
                        console.log("success!");
                  });
                // update transfer tab (so it registers new max amount of eth to be transferred)
                $.get("/€"+address+"/get/structure/bank/transfer/", function(transfer, status) {
                        TRANSFER_HTML = transfer;
                        $("#transfer-modal").replaceWith(transfer);
                        console.log("TRANSFER IS CONVERTED");
                });
        });
}

$(document).on('keypress','.amount-input',function(event) {
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
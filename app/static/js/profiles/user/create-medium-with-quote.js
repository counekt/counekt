
function submitQuoteCreate(onlySave=false) {
	post("/create/medium/", function(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
      		flash('#ffff','#3abb8','Quote Reply sent', delay=1500);

      		setTimeout(function() {
      			document.location.href = "/@"+response["author"]["username"]+"/medium/"+response["id"]+"/";
      		},1500);
        }

        else {
        	flash('#ffff','#f14668',status, delay=1500);
        }

      }, {action: onlySave ? 'save' : 'submit', title:$("#title-create").val(),text:$("#text-create").val(), target_id:$(".modal-card-body").find('.medium').data('id'), type:'quote'});
}

$(document).on('click', "#submit-quote-button", submitQuoteCreate);

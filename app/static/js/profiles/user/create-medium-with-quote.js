
function submitQuoteCreate(onlySave=false) {
    console.log("DADADWD");
    var target_id = $(".modal-card-body").find('.medium').data('id');
    console.log(target_id);
    var $medium = $(".wall").find(`.medium:not(.quote)[data-id='${target_id}']`);
    console.log()
    var $medium_quote = $medium.find('.medium-quote');
    var $counter = $medium_quote.find('.number-info').find('span');

	post("/create/medium/", function(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
            $counter.text(parseInt($counter.text())+1);
      		flash('Quote Reply sent');

      		$('.wall').prepend(response["html"]);
            changeToProfile();
        }
        
        else {
        	flash(status,'#ffff','#f14668',delay=1500);
        }

      }, {action: onlySave ? 'save' : 'submit', title:$("#title-create").val(),text:$("#text-create").val(), target_id:target_id, type:'quote'});
}

$(document).on('click', "#submit-quote-button", submitQuoteCreate);

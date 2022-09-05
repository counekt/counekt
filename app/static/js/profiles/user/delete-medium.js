function submitDeleteMedium() {
    console.log("delete");
    var target_id = $("#modal-box").find('#delete-medium-button').data('id');
    var $medium = $(".wall").find(`.medium:not(.quote)[data-id='${target_id}']`);
    $medium.remove();
    var quotes_of_medium = $(".wall").find(`.quote[data-id='${target_id}']`);
    console.log(quotes_of_medium);
    quotes_of_medium.replaceWith(unavailableQuote());
    changeToProfile();
	post("/delete/medium/", function(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
      		flash('Your medium was deleted');
      		
        }
        
        else {
        	flash(status);
        }

      }, {target_id:target_id});
}

$(document).on('click', "#delete-medium-button", submitDeleteMedium);
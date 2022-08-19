
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
      		flash('#ffff','#3abb8','Quote Reply sent', delay=1500);

      		$('.wall').prepend(mediumWithQuote(mediumQuote(response["quote"]["id"],response["quote"]["title"],response["quote"]["content"],response["quote"]["creation_datetime"],
                response["quote"]["author"]["dname"],response["quote"]["author"]["username"],
                response["quote"]["author"]["href"],response["quote"]["author"]["profile_photo_src"]),
                response["id"],response["title"],response["content"],response["creation_datetime"],
                response["author"]["dname"],response["author"]["username"],
                response["author"]["href"],response["author"]["profile_photo_src"]));
            changeToProfile();
        }
        
        else {
        	flash('#ffff','#f14668',status, delay=1500);
        }

      }, {action: onlySave ? 'save' : 'submit', title:$("#title-create").val(),text:$("#text-create").val(), target_id:target_id, type:'quote'});
}

$(document).on('click', "#submit-quote-button", submitQuoteCreate);

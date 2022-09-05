$(document).on('input', '#title-create', function(){
		console.log($("#title-create").val());
		if ($("#title-create").val().length === 0) {
		$(".submit-button").prop("disabled", true);
		if ($("#text-create").val().length === 0) {
			$("#save-draft-button").prop("disabled", true);
		}
		}
		else {
			$(".submit-button").prop("disabled", false);
			$("#save-draft-button").prop("disabled", false);
		}
});
	$(document).on('input', "#text-create", function(){ 
		if ($("#text-create").val().length === 0) {
			if ($("#title-create").val().length === 0) { 
				$(".submit-button").prop("disabled", true);
				$("#save-draft-button").prop("disabled", true);
			}
		}

		else {
				$("#save-draft-button").prop("disabled", false);
		}

	});

	$(document).on({
		mouseenter: function () {
        //stuff to do on mouse enter
        $(this).find($(this).attr('hidden-selector')).removeClass('invisible');
    },
    mouseleave: function () {
        $(this).find($(this).attr('hidden-selector')).addClass('invisible');
    }}, '.show-hidden-selector-on-hover');


 function submitCreate(onlySave=false) {
	post("/create/medium/", function(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
      		flash('Medium submitted');
      		console.log(response["author"]["profile_photo_src"]);
      		$('.wall').prepend(medium(
      			response["id"],response["title"],response["content"],response["creation_datetime"],
      			response["author"]["dname"],response["author"]["username"],
      			response["author"]["href"],response["author"]["profile_photo_src"]));
      		changeToProfile();
        }

        else {
        	flash(status,'#ffff','#f14668');
        }

      }, {action: onlySave ? 'save': 'submit' ,title:$("#title-create").val(),text:$("#text-create").val()});
}

$(document).on('click', "#submit-button", function() {
	  $("#submit-button").prop('disabled', true).addClass('is-loading');
});

$(document).on('click', "#submit-medium-button" , function() {
	submitCreate();
});
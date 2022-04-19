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
    }}, '.show-hidden-selector-on-hover')


 function submitCreate(onlySave=false) {
	post("/create/medium/", function(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
      		flash('#ffff','#3abb8','Medium submitted', delay=1500);

      		setTimeout(function() {
      			document.location.href = "/@"+response["author"]["username"]+"/medium/"+response["id"]+"/";
      		},1500);
        }

        else {
        	flash('#ffff','#f14668',status, delay=1500);
        }

      }, {action: onlySave ? 'save': 'submit' ,title:$("#title-create").val(),text:$("#text-create").val()});
}

$(document).on('click', "#submit-button", submitCreate);


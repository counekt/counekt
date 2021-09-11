$(document).on('input',"#title-input",function(){
	console.log("JNDJWENDWED");
		console.log($("#title-input").val());
		if ($("#title-input").val().length === 0) {
		$("#submit-button").prop("disabled", true);
		if ($("#content-input").val().length === 0) {
			$("#save-draft-button").prop("disabled", true);
		}
		}
		else {
			$("#submit-button").prop("disabled", false);
			$("#save-draft-button").prop("disabled", false);
		}
});
	$(document).on('input', "#content-input", function(){ 
		if ($("#content-input").val().length === 0) {
			if ($("#title-input").val().length === 0) { 
				$("#submit-button").prop("disabled", true);
				$("#save-draft-button").prop("disabled", true);
			}
		}

		else {
				$("#save-draft-button").prop("disabled", false);
		}

	});

 function submit() {
 	var formData = new FormData();
 	formData.append('wall',wall);
 	formData.append('title',$("#title-input").val());
 	formData.append('content',$("#content-input").val());
	$.post({
      type: "POST",
      url: "/submit/post/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
      	var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
        	var feedback_id = response["id"]; 
      		flash('#ffff','#3abb8','Your Post was sent', delay=1500);

      		setTimeout(function() {
      			document.location.href = "/feedback/"+feedback_id+"/";
      		},1500);
        }

        else {
        	flash('#ffff','#f14668',status, delay=1500);
        }

      }
  });
}

$(document).on('click', "#submit-button", submit);



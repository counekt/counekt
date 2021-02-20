function message(status, box_id, shake=false) {
  $("#feedback-"+box_id).stop(stopAll=true);
document.getElementById(box_id+"-anchor").scrollIntoView(false);

  if (shake) {
    $("#"+box_id).effect("shake", {direction: "right", times: 2, distance: 8}, 350);
  }
  $("#feedback-"+box_id).animate({ opacity: 1 })
  $('#feedback-'+box_id).text(status);
  $("#feedback-"+box_id).delay(2000).animate({ opacity: 0 })
}

function alertError(field_id) {
  $('#'+field_id).addClass('errorClass');
}

function stopErrorAlert(field_id) {
  $('#'+field_id).removeClass('errorClass');
}

$(document).on("click", "#save-button", function() {
   console.log("Applying edit");
   console.log($("#day").val());
   var skills = $(".skill-title").map(function() { return $(this).text();}).get();
   
   var formData = new FormData();
   formData.append('photo', $("#upload").prop('files')[0]);

   formData.append("name", $("#name-field").val());

   formData.append("bio", $("#bio-field").val());

   formData.append("visible", $("#visible").is(':checked') ? 1 : 0);
   console.log($("#visible").is(':checked'));
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);

   formData.append("lng", window.getLatLng().lng);
   }


   if ($("#month").val()) {
    formData.append("month", $("#month").val());
  }
   
   if ($("#day").val()) {
    formData.append("day", $("#day").val());
  }

  if ($("#year").val()) {
    formData.append("year", $("#year").val());
  }

   formData.append("gender", $("#gender").val());

   formData.append("skills", JSON.stringify(skills));

   if (! $("#location-field").hasClass('errorClass') && ! $("#map").hasClass('errorClass')) {

    $.post({
      type: "POST",
      url: "/settings/profile/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") { location.replace("/user/"+response["username"]+"/"); }
        else{message(status, response["box_id"], true);}
        
      }});
     }
     else {
       $(".errorClass").effect("shake", {direction: "right", times: 2, distance: 8}, 350);
       document.getElementById("#map").scrollIntoView(false);

     }
  });


$(document).on('change','#selected-skill',function(){
               if ($('#selected-skill').val() != 'Select skill') {
                $('#add-skill').prop("disabled", false);
               }       
             });



 $(document).on("click", "#add-a-skill", function() {
    $('#add-a-skill-wrap').remove();
    $('#skill-select-form').removeClass("vanish");
    if ($('#selected-skill').val() == 'Select skill') {
            $('#add-skill').prop("disabled", true);
    }
    $(".modal-card-body").animate({ scrollTop: $(".modal-card-body").prop("scrollHeight")}, 1000);     
  });

 $(document).on("click", "#add-skill", function() {
  $('#skill-select-form').addClass("vanish");
  $("#skills").append("<div class='skill'><button class='button is-info is-normal is-'><span class='skill-title'>"+$('#selected-skill').val()+"</span><span class='icon remove-skill'><a class='delete'></a></span></button></div>");
  $('#skills').append(`<div id="add-a-skill-wrap"><button id="add-a-skill" class="button is-info is-normal is-inverted">
      <span>Add skill</span>
      <span class="icon is-normal is-danger"><i class="fa fa-plus"></i>
      </span></button></div>
      </div>`);
  $('#selected-skill option:selected').remove();
  console.log($('#selected-skill').children().length)
  if ($('#selected-skill').children().length == 1) {
    $('#add-a-skill-wrap').remove();
  }
 });


 $(document).on("click", ".remove-skill", function() {
  $('#selected-skill').append('<option>'+$(this).prev('span').text()+'</option>')
  $(this).closest('div').remove();
  if (!$("#add-a-skill-wrap").length && $('#skill-select-form').hasClass('vanish')) {
  $('#skills').append(`<div id="add-a-skill-wrap"><button id="add-a-skill" class="button is-info is-normal is-inverted">
      <span>Add skill</span>
      <span class="icon is-normal is-danger"><i class="fa fa-plus"></i>
      </span></button></div>
      </div>`);
}

});


function loadFile(input) {
  if (event.target.files[0]) {
  $("#edit-profile-image-content").attr('src', URL.createObjectURL(event.target.files[0]));
}
  console.log("WOOOOOW");
};

$(document).on("click", "#edit-profile-upload", function() {
  $("#upload").click();
});

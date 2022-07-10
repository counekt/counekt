$(document).on("click", "#save-button", function() {
   console.log("Applying edit");
   $(this).prop('disabled', true);$(this).addClass('is-loading');
   console.log($("#day").val());
   var skills = $(".skill-title").map(function() { return $(this).text();}).get();
   
   var formData = new FormData();
   console.log($("#upload-image").prop('files')[0]);
   formData.append('photo', $("#upload-image").prop('files')[0]);

   formData.append("name", $("#name-field").val());

   formData.append("bio", $("#bio-field").val());

   formData.append("show-location", $("#show-location").is(':checked') ? 1 : 0);
   if ($("#show-location").is(':checked')) {
   formData.append("visible", $("#visible").is(':checked') ? 1 : 0);
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);
   formData.append("lng", window.getLatLng().lng);
   }

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
       document.getElementById("map").scrollIntoView(false);

     }
  });


$(document).on("click", "#edit-associate-image-upload", function() {
  $("#upload-image").click();
});

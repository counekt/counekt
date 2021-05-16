$(document).on("click", "#save-button", function() {
   
   //var skills = $(".skill-title").map(function() { return $(this).text();}).get();
   
   var formData = new FormData();
   formData.append('photo', $("#upload-image").prop('files').reverse()[0]);

   formData.append("name", $("#name-field").val());

   formData.append("description", $("#description-field").val());

   formData.append("show-location", $("#show-location").is(':checked') ? 1 : 0);
   if ($("#show-location").is(':checked')) {
   formData.append("visible", $("#visible").is(':checked') ? 1 : 0);
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);
   formData.append("lng", window.getLatLng().lng);
   }

  }

   //formData.append("skills", JSON.stringify(skills));

   if (! $("#location-field").hasClass('errorClass') && ! $("#map").hasClass('errorClass')) {

    $.post({
      type: "POST",
      url: "/€"+handle+"/edit/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        var handle = response["handle"];
        if (status === "success") { location.replace("/€"+handle+"/"); }
        else{message(status, response["box_id"], true);}
        
      }});
     }
     else {
       $(".errorClass").effect("shake", {direction: "right", times: 2, distance: 8}, 350);
       document.getElementById("#map").scrollIntoView(false);

     }
  });

$(document).on("click", "#edit-associate-image-upload", function() {
  $("#upload-image").click();
});
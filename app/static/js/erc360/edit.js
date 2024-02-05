$(document).on("click", '#save-button', function(e) {
   $(this).prop('disabled', true);$(this).addClass('is-loading');
   var photo = $("#upload-image").prop('files')[0];
   var photo_src = $("#edit-associate-image-content").attr('src');
   var description = $("#description-field").val();
   var show_location = $("#show-location").is(':checked') ? 1 : 0;
   var visible = $("#visible").is(':checked') ? 1 : 0;
   var location_address;

   var formData = new FormData();
   
   formData.append('photo', photo);
   
   formData.append("description", description);

   
   formData.append("show-location", show_location);
   if ($("#show-location").is(':checked')) {
   formData.append("visible", visible);
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);
   formData.append("lng", window.getLatLng().lng);
   }

  }

   if (! $("#location-field").hasClass('errorClass') && ! $("#map").hasClass('errorClass')) {

    $.post({
      type: "POST",
      url: "/€"+address+"/edit/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        location_address = response["address"];
        console.log(location_address);
        var status = response["status"];
        if (status === "success") { 
          console.log("FLASHING");
          $("#profile-description p").text(description);
          //$("#profile-address span:not(.icon)").text(location_address);
          $(".current-user-photo").attr('src',photo_src);
          stopButtonLoading();
          $("select").find("option:selected").attr('selected', 'selected');
          $("select").find("option:not(:selected)").removeAttr('selected');
          mapLatLng =  window.getLatLng();
          mapZoom = 12;
          $.get("/€"+address+"/get/edit/", function(edit, status) {
                        EDIT_HTML = edit;
          });
          changeToProfile();
          flash("Your changes were saved"); }
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

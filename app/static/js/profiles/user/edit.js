$(document).on("click", "#save-button", function() {
   console.log("Applying edit");
   $(this).prop('disabled', true);$(this).addClass('is-loading');
   console.log($("#day").val());
   var skills = JSON.stringify($(".skill-title").map(function() { return $(this).text();}).get());
   var photo = $("#upload-image").prop('files')[0];
   var photo_src = $("#edit-associate-image-content").attr('src');
   var name = $("#name-field").val();
   var bio = $("#bio-field").val();
   var show_location = $("#show-location").is(':checked') ? 1 : 0;
   var visible = $("#visible").is(':checked') ? 1 : 0;
   var month = $("#month").val();
   var day = $("#day").val();
   var year = $("#year").val();
   var address;
   var skill_bar;

   var formData = new FormData();
   
   formData.append('photo', photo);
   
   formData.append("name", name);

   formData.append("bio", bio);

   
   formData.append("show-location", show_location);
   if ($("#show-location").is(':checked')) {
   formData.append("visible", visible);
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);
   formData.append("lng", window.getLatLng().lng);
   }

  }

   if (month) {
    formData.append("month", month);
  }
   
   if (day) {
    formData.append("day", day);
  }

  if (year) {
    formData.append("year", year);
  }

   formData.append("gender", $("#gender").val());
   formData.append("skills", skills);

   if (! $("#location-field").hasClass('errorClass') && ! $("#map").hasClass('errorClass')) {

    $.post({
      type: "POST",
      url: "/settings/profile/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        address = response["address"];
        console.log(address);
        skill_bar = response["skill-bar"];
        var status = response["status"];
        if (status === "success") { 
          console.log("FLASHING");
          $("#profile-bio p").text(bio);
          $("#profile-birthdate span:not(.icon)").text(`${year}-${month}-${day}`);
          $("#profile-address span:not(.icon)").text(address);
          $(".current-user-name").text(name);
          $(".current-user-photo").attr('src',photo_src);
          $("#profile-skills-container").html(skill_bar);
          $("#save-button").prop('disabled', false);$("#save-button").removeClass('is-loading');
          $("select").find("option:selected").attr('selected', 'selected');
          $("select").find("option:not(:selected)").removeAttr('selected');
          edit_modal = $("#modal-box").clone();
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

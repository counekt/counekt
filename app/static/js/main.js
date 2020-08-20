function message(status, box_id, shake=false, delay=2000) {
  $("#feedback").stop(stopAll=true);

  if (shake) {
    $("#"+box_id).effect("shake", {direction: "right", times: 2, distance: 8}, 350);
  }
  $("#feedback").animate({ opacity: 1 })
  $("#feedback").text(status);
  $("#feedback").delay(delay).animate({ opacity: 0 })
}

function prepare_info_loading(delay=1000) {
  window.info_loading_id = setTimeout(function(){
    console.log("loading...");
    $('#info-loader').removeClass("hide");
  }, delay);
}

function clear_info_loading() {
  console.log("stop loading");
  clearTimeout(window.info_loading_id);
  $('#info-loader').addClass("hide");
}

function explore() {

  prepare_info_loading(1000);

  var formData = new FormData();

   formData.append("listing-id", $("#listing-id-field").val());

    $.post({
      type: "POST",
      url: "/main/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        if ($("#listing-id-field").val()) {
        swap_url("/"+$("#listing-id-field").val()+"/");
        }
        var response = JSON.parse(response);
        var status = response["status"]; 
        if (status === "Successfully explored") {
          var info = response["info"];
          console.log(info);
          $("#results-text").text(JSON.stringify(info));
          clear_info_loading();
        }
        else{
          message(status, "explore-fields", true);
          clear_info_loading();
        }
        
          

      }});
}

$(document).on("click", "#explore-button", function() {
	explore();
})
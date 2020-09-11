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

  if ($("#location-field").val()) {

  prepare_info_loading(1000);

  var formData = new FormData();

  formData.append("location", $("#location-field").val());
  
  if (0 <= $( "#radius-slider" ).slider("value") <= 999) {
    formData.append("radius", $( "#radius-slider" ).slider( "value" ));
  }

  if ($("#skill").val()){
    formData.append("skill", $("#skill").val());
  }

  if ($("#gender").val()) {
   formData.append("gender", $("#gender").val());
 }

  if ($( "#age-slider" ).slider( "values", 0 ) > 13) {
   formData.append("min_age", $( "#age-slider" ).slider( "values", 0 ));
 }
 if ($( "#age-slider" ).slider( "values", 1 ) < 100) {
   formData.append("max_age", $( "#age-slider" ).slider( "values", 1 ));
 }

    $.post({
      type: "POST",
      url: "/main/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        if ($("#location-field").val()) {
        swap_url(response["url"]);
        }
        var status = response["status"]; 
        if (status === "Successfully explored") {
          var info = response["info"];
          console.log(info);
          $("#results-text").text(JSON.stringify(info));
          clear_info_loading();
        }
        else{
          message(status, response["box_id"], true);
          clear_info_loading();
        }
        
          

      }});
}}

$(document).on("click", "#explore-button", function() {
 
	explore();

});

function open_options() {
  $('#explore-button').css('visibility','hidden');
  $('#options-wrap').css("display", "block");
  var button = $('#options-button');
  button.find('#down').css("display", "none");
  button.find('#up').css("display", "block");
}

function close_options() {
  $('#explore-button').css('visibility','visible');
  $('#options-wrap').css("display", "none");
  var button = $('#options-button');
  button.find('#up').css("display", "none");
  button.find('#down').css("display", "block");
    

}

function options_are_open() {
  return($('#options-wrap').css("display") === "block");
}

$(document).on("click", '#options-button', function(event) {
  event.stopPropagation();
  if (!options_are_open()) {
        open_options();
  }

  else {
    close_options();
  }
  
});

$(document).on("click", '#options-wrap', function (event) {
            event.stopPropagation();
        });

$(document).on("click", window, function() {
  close_options();

});
//$(document).on('mouseover', '#options-button', function() {
//var options = $(this).next('#options');
//if (options.css("display") === "none") {
//    $('#options').css("display", "none");
//    options.css("display", "block");
//}

//else {
//    options.css("display", "none");
//}

//});


 $(document).on('keydown', '.value', function(event) {
    var key = event.keyCode || event.charCode;
    // If not digits, numpad digits, backspace, arrows, tab and enter
    if (!(48 <= key <= 57 ||  96 <= key <= 105 || key == 8 || 37 <= key <= 40 || key == 9 || key == 13)) {
      
      // If decimal point, comma and period
    if (key == 110 || key == 188 || key == 190) {
      if (event.key === ";" || event.key === ":") {
        event.preventDefault();
      }
      var val = $(this).val();
      if (is_in(",", val) || is_in(".", val) || is_in("·", val)) {
         event.preventDefault();
      }

    }

    else {
      event.preventDefault();
    }}

  });



 function is_in(sub, str) {
   return(str.indexOf(sub) != -1);
 }

 function censor(value) {
   value = value.replace(",", ".");
   if (value === ".") {
     value = 0;
   }
   return(value);
 }

 function enter_value(val) {
    if (typeof val.data("handle") !== "undefined") {
    $('#'+val.data("slider")).slider('values', val.data("handle"), censor(val.val()));
  }

  else {
    $('#'+val.data("slider")).slider('value',  censor(val.val()));
  }

 }

 $('.value').change(function() {
   enter_value($(this));
 })
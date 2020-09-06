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



 $(function() {
    $( "#radius-slider" ).slider({
      range: "min",
      min: 0,
      max: 999,
      value: 5,
      slide: function( event, ui ) {
        $( "#radius-value" ).val( ui.value );
      }
    });
    $( "#radius-value" ).val($("#radius-slider" ).slider("value"));
  } );

 $(function() {
    $( "#age-slider" ).slider({
      range: true,
      min: 13,
      max: 100,
      values: [0,100],
      slide: function( event, ui ) {
        $( "#age-value0" ).val(ui.values[ 0 ]);
        $( "#age-value1" ).val(ui.values[ 1 ]);
      } 
    });
    $( "#age-value0" ).val( $( "#age-slider" ).slider( "values", 0));
    $( "#age-value1" ).val( $( "#age-slider" ).slider( "values", 1));
  } );

 $(document).on('keydown', '.value', function(event) {
    var key = event.keyCode || event.charCode;
    // Only digits, numpad digits, backspace, arrows
    if (!(key >= 48 && key <= 57 || key >= 96 && key <= 105 || key == 8 || key >= 37 && key <= 40)) {
      var val = $(this).val();
      // Decimal point, comma and period also allowed
      if (!(key == 110 || key == 188 || key == 190)) {
      event.preventDefault();
    }
    }
    else if (event.key === ";" || event.key === ":") {
      event.preventDefault();
    }
  });

 function is_in(str, sub) {
   return(str.indexOf(sub) != -1);
 }
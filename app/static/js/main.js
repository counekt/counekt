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

$(document).on('keydown', '#location-field', function() {

if ($(this).val()) {
  $("#search-span").css("cursor", "pointer");
}

else {
  $("#search-span").css("cursor", "default");
}

});


$(document).on('click', '#toggle-view-button', function() {

if ($(this).data('status') == 'showing') {
        $("#explore-box").animate({left: "-300px"});
        $(this).data('status', 'hiding');
        $("#toggle-icon").toggleClass("fas fa-caret-left fas fa-caret-right")

      }
else if ($(this).data('status') == 'hiding') {
  $("#explore-box").animate({left: "7px"});
     $(this).data('status', 'showing');
     $("#toggle-icon").toggleClass("fas fa-caret-right fas fa-caret-left")
  }

})

$('#location-field').keypress(function(event){
  if(event.keyCode == 13){
    $('#search-button').click();
  }
});
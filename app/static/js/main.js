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


function toggleView() {
  if ($("#toggle-view-button").data('status') == 'showing') {
      closeView();

      }
else if ($("#toggle-view-button").data('status') == 'hiding') {
   openView();

}

}

function closeView() {
        $("#explore-box").toggleClass("is-resting is-hiding");
        $("#toggle-view-button").data('status', 'hiding');
        $("#toggle-icon").toggleClass("fas fa-caret-left fas fa-caret-right");
}

function openView() {
     $("#explore-box").toggleClass("is-hiding is-resting");
     $("#toggle-view-button").data('status', 'showing');
     $("#toggle-icon").toggleClass("fas fa-caret-right fas fa-caret-left");
}

$(document).on('click', '#toggle-view-button', toggleView);

$('#location-field').keypress(function(event){
  if(event.keyCode == 13){
    $('#search-button').click();
  }
});

function explore(do_redirect=true) {
  if ($("#location-field").val()) {
  var searchObject = {rad:"", loc:"", ski:"", gen:"", min:"", max:""};
  var formData = new FormData();

  formData.append("location", $("#location-field").val());
  searchObject["loc"] = $("#location-field").val();

  if (0 <= $( "#radius-slider" ).slider("value") <= 999) {
    formData.append("radius", $( "#radius-slider" ).slider( "value" ));
    searchObject["rad"] = $( "#radius-slider" ).slider( "value" );
  }

  if ($("#skill").val()){
    formData.append("skill", $("#skill").val());
    searchObject["ski"] = $("#skill").val();

  }

  if ($("#gender").val()) {
   formData.append("gender", $("#gender").val());
  searchObject["gen"] = $("#gender").val();

 }

  if ($( "#age-slider" ).slider( "values", 0 ) > 13) {
   formData.append("min_age", $( "#age-slider" ).slider( "values", 0 ));
     searchObject["min"] = $( "#age-slider" ).slider( "values", 0 );

 }
 if ($( "#age-slider" ).slider( "values", 1 ) < 100) {
   formData.append("max_age", $( "#age-slider" ).slider( "values", 1 ));
    searchObject["max"] = $( "#age-slider" ).slider( "values", 1 );

 }

    $.post({
      type: "POST",
      url: "/main/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        
        var status = response["status"]; 
        if (status === "Successfully explored") {
          var loc = response["loc"];
          if (-180 > map.getCenter().lng || 180 < map.getCenter().lng) {
              map.setView([loc.lat, convertToNearest(map.getCenter().lng),map.getZoom()]);
          }
          if (do_redirect) {redirect(searchObject, "Explore", response["url"], function(){});} else { window.history.replaceState(searchObject,"Explore", response["url"]);}
          var info = response["info"];
          console.log(info);
          markers.clearLayers();
          info.forEach(function(marker) {
          L.marker([marker.lat,marker.lng], {icon: proIcon}).addTo(markers).bindPopup(`
      <div class="profile-image">
        <a href="user/`+marker.username+`">
        <img alt draggable="false" class="profile-image-content" src="`+marker.profile_photo+`">
        </a>
      </div><a class="title is-4 profile-name" href="user/`+marker.username+`" style="color:black"><b>`+marker.name+`</b></a>`);
          });
          if (do_redirect) {
          map.flyTo([loc.lat, loc.lng], loc.zoom);
          }
          else {
          map.panTo(new L.LatLng(loc.lat, loc.lng));
          map.setZoom(loc.zoom);
          }
          
          closeView();
          
        }
        
          

      }});
}}

function convertToNearest(lng) {
  if (lng < -180 || lng > 180) {
    return((lng%180)*(-1)**parseInt(Math.abs(lng)/180));
  }

  else {
    return(lng);
  }
}

function convertToView(lng, viewlng) {
  if (viewlng < -180 || viewlng > 180) {
  return(lng + 360 * (parseInt((viewlng)/180))-360);
}
  else {
    return(lng);
  }
}


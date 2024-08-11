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
  var searchObject = {rad:"", loc:"", ski:"", sex:"", min:"", max:""};
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

  if ($("#sex").val()) {
   formData.append("sex", $("#sex").val());
  searchObject["sex"] = $("#sex").val();

 }

  if ($( "#age-slider" ).slider( "values", 0 ) > 13) {
   formData.append("min_age", $( "#age-slider" ).slider( "values", 0 ));
     searchObject["min"] = $( "#age-slider" ).slider( "values", 0 );

 }
 if ($( "#age-slider" ).slider( "values", 1 ) < 100) {
   formData.append("max_age", $( "#age-slider" ).slider( "values", 1 ));
    searchObject["max"] = $( "#age-slider" ).slider( "values", 1 );

 }

    var includeERC360s = true;

    $.post({
      type: "POST",
      url: "/map/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
          $('#search-button').removeClass('is-loading');

        var response = JSON.parse(response);
        
        var status = response["status"]; 
        if (status === "Successfully explored") {
          var loc = response["loc"];
          if (-180 > map.getCenter().lng || 180 < map.getCenter().lng) {
              map.setView([loc.lat, convertToNearest(map.getCenter().lng),map.getZoom()]);
          }
          if (do_redirect) {redirect(searchObject, "Explore", response["url"], function(){});} else { window.history.replaceState(searchObject,"Explore", response["url"]);}
          var users_info = response["users_info"];
          console.log(users_info);
          markers.clearLayers();
          users_info.forEach(function(user) {
          L.marker([user.lat,user.lng], {icon: proIcon}).addTo(markers).bindPopup(`
      <div class="profile-image">
        <a href="user/`+user.username+`">
        <img alt draggable="false" class="profile-image-content" src="`+user.photo+`">
        </a>
      </div><a class="title is-4 profile-name" href="user/`+user.username+`" style="color:black"><b>`+user.name+`</b></a>`);
          });

          if (includeERC360s) {
            console.log(erc360s_info);
            var erc360s_info = response["erc360s_info"];
            erc360s_info.forEach(function(erc360) {
          L.marker([erc360.lat,erc360.lng], {icon: erc360Icon}).addTo(markers).bindPopup(`
      <div class="profile-image">
        <a href="erc360/`+erc360.address+`">
        <img alt draggable="false" class="profile-image-content" src="`+erc360.photo+`">
        </a>
      </div><a class="title is-4 profile-name" href="user/`+erc360.address+`" style="color:black"><b>`+erc360.name+` (`+erc360.symbol+`)`+`</b></a>`);
          });
          }

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


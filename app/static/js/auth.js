function message(status, box_ids, shake=false) {
  $(".feedback").stop(stopAll=true);
  box_ids.forEach( function (box_id, index) {
    if (shake) {
    $("#"+box_id+"-box").effect("shake", {direction: "right", times: 2, distance: 8}, 350);
  }
  $("#feedback-"+box_id).animate({ opacity: 1, queue: false })

  $("#feedback-"+box_id).text(status);
  $("#feedback-"+box_id).delay(2000).animate({ opacity: 0, queue: false });
});
}

window._step = 1;

function register() {
  var formData = new FormData();
  formData.append("step", window._step);

  if (window._step == 1) {
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
  }

  else if (window._step == 2) {
    formData.append("email", $("#email").val());
    formData.append("username", $("#username").val());

  }

  else if (window._step == 3 || window._step == "finally") {
   formData.append("password", $("#password").val());
   formData.append("repeat-password", $("#repeat-password").val());

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

     formData.append("email", $("#email").val());
    formData.append("username", $("#username").val());
 }

$.post({
      type: "POST",
      url: "/register/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        console.log(response);
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {

            if (window._step == 1) {
              window._step = "2";
              $(".step-1").css('display','none');
              $(".step-2").css('display','block');
                         }
            else if (window._step == 2) {
              window._step = "3";
              $(".step-2").css('display','none');
              $(".step-3").css('display','block');
            }

            else if (window._step == 3) {
              window._step = "finally";
              $(".step-3").css('display','none');
              $(".finally").css('display','block');
            }

            else if (window._step == "finally") {
              
            }
         }
        else{message(status, response["box_ids"], true);}

      }});
}

function login() {
  var formData = new FormData();
   formData.append("username", $("#username").val());
   formData.append("password", $("#password").val());
$.post({
      type: "POST",
      url: "/login/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {window.location.replace("/"); }
        else{message(status, response["box_ids"], true);}

      }});
}


$(document).on("click", "#register-button", function() {
    register();
});

$(document).on("click", "#login-button", function() {
    login();
});
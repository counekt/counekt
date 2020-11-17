function message(status, box_ids, shake=false) {
  $(".feedback").stop(stopAll=true);
  box_ids.forEach( function (box_id, index) {
    if (shake) {
    $("#"+box_id).effect("shake", {direction: "right", times: 2, distance: 8}, 350);
  }
  $("#feedback-"+box_id).animate({ opacity: 1, queue: false })

  $("#feedback-"+box_id).text(status);
  $("#feedback-"+box_id).delay(2000).animate({ opacity: 0, queue: false });
});
}

function register() {
  var formData = new FormData();
   formData.append("username", $("#username-field").val());
   formData.append("password", $("#password-field").val());
   formData.append("repeat-password", $("#repeat-password-field").val());
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
        if (status === "success") {window.location.replace("/settings/"); }
        else{message(status, response["box_ids"], true);}

      }});
}

function login() {
  var formData = new FormData();
   formData.append("username", $("#username-field").val());
   formData.append("password", $("#password-field").val());
$.post({
      type: "POST",
      url: "/login/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        console.log(response);
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {window.location.replace("/main/"); }
        else{message(status, response["box_ids"], true);}

      }});
}


$(document).on("click", "#register-button", function() {
    register();
});

$(document).on("click", "#login-button", function() {
    login();
});
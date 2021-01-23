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

window._step = "step-1";
window.resend_token = "";

function register() {
  var formData = new FormData();
  formData.append("step", window._step);

  if (window._step == "step-1") {
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

  else if (window._step == "step-2") {
    formData.append("email", $("#email").val());
    formData.append("username", $("#username").val());

  }

  else if (window._step == "step-3") {
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

 else if (window._step == "finally") {
      formData.append("resend_token", window.resend_token);
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

            if (window._step == "step-1") {
              change_step("step-3");
            }
            else if (window._step == "step-2") {
              change_step("step-3");
            }

            else if (window._step == "step-3" || window._step == "finally") {
              change_step("finally");
              window.resend_token = response["resend_token"];
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

$(document).on("click", "#back-button a", function() {
    go_back();
});

$(document).on("click", "#login-button", function() {
    login();
});

function go_back() {
  if (window._step == "step-2") {
      change_step("step-1");
  }
  else if (window._step == "step-3") {
    change_step("step-2");
  }

  else if (window._step == "finally") {
    change_step("step-3");
  }
}

function change_step(step) {
  if (step == "step-1" || step == "step-2" || step == "step-3" || step == "finally") {
    window._step = step;
    $(".step-1").css('display','none');
    $(".step-2").css('display','none');
    $(".step-3").css('display','none');
    $(".finally").css('display','none');
    $("#auth-nav").empty();
    if (step == "step-1") {
      $(".step-1").css('display','block');
      $("#auth-nav").append(`
        <div id="first-continue-button">
          <a id="register-button" class="form-button button is-link is-outlined">
            <span>Next</span>
            <span class="icon is-medium">
              <i class="fa fa-arrow-right"></i>
            </span>
          </a>
        </div>
    `);

    }
    else if (step == "step-2") {
      $(".step-2").css('display','block');
      $("#auth-nav").append(`
      <div id="back-button">
        <a class="form-button button is-link is-outlined">
          <span class="icon is-medium">
            <i class="fa fa-arrow-left"></i>
          </span>
        </a>
      </div>
      <div id="continue-button">
        <a id="register-button" class="form-button button is-link is-outlined">
          <span>Next</span>
        </a>
      </div>
    `);

    }
    else if (step == "step-3") {
      $(".step-3").css('display','block');
      $("#auth-nav").append(`
        <div id="back-button">
          <a class="form-button button is-link is-outlined">
            <span class="icon is-medium">
              <i class="fa fa-arrow-left"></i>
            </span>
          </a>
        </div>
        <div id="continue-button">
          <a id="register-button" class="form-button button is-link is-outlined">
            <span>Finish</span>
          </a>
        </div>
          `);
    }
    else if (step == "finally") {
      $(".finally").css('display','block');
      $("#auth-nav").append(`
        <div id="resend-button">
          <a id="register-button" class="form-button button is-link">
            <span>Resend</span>
            <span class="icon is-medium">
              <i class="fa fa-envelope"></i>
            </span>
          </a>
        </div>
        `);

    }
  }

}
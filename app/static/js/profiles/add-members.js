$(document).on("click", "#send-invites-button", function() {
   sendInvites();
  });

function sendProjectInvites() {
  var formData = new FormData();

   formData.append("members", JSON.stringify($("#add-member-tags-container").children().toArray().map( element => $(element).data('username'))));

    $.post({
      type: "POST",
      url: "/£"+handle+"/invite/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "Successfully saved") { location.replace("/£"+response["handle"]+"/"); }
        else{message(status, response["box_id"], true);}
        
      }});
}

function sendClubInvites() {
  var formData = new FormData();

   formData.append("members", JSON.stringify($("add-#member-tags-container").children().toArray().map( element => $(element).data('username'))));

    $.post({
      type: "POST",
      url: "/€"+handle+"/invite/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "Successfully saved") { location.replace("/€"+response["handle"]+"/"); }
        else{message(status, response["box_id"], true);}
        
      }});
}

function updatePlaceholder() {
  console.log($("#add-member-tags-container").children().length);
  if ($("#add-member-tags-container").children().length == 0) {
    $("#add-members-text-field").addClass('placeholder');
}
  else {
    $("#add-members-text-field").removeClass('placeholder');
  }
}

function get_allies_from_text() {
  var text = $("#add-members-text-field").text();
  var already_chosen = $("#add-member-tags-container").children().toArray().map( element => $(element).data('username'));
  if (text.length > 0) {
    var formData = new FormData();
    formData.append('text', text);
    formData.append('already_chosen', JSON.stringify(already_chosen));
    $.post({
      type: "POST",
      url: "/get/allies/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var allies = response["allies"];
        $('#select-connections').empty();
        allies.forEach( function (ally, index) {
         $("#select-connections").append('<div valign="top" class="row profile-bigBox" data-username="'+ally.username+'" data-name="'+ally.name+'"><div class="profile-column profile-leftBox" ><img class="image" src="' + ally.profile_pic + '"></div><div class="profile-column profile-rightBox"><h1><b>'+ ally.name +'</b></h1>');
        });
        if (!$('#select-connections').is(':empty')){
        $('#select-connections').removeClass("vanish");
        updateScroll();
      }
      else {
        $('#select-connections').addClass("vanish");
      }

      }
  });}
  else {
    $('#select-connections').addClass("vanish");
    $('#select-connections').empty();

  }
}

$("#add-members-text-field").on('input', function() {
    get_allies_from_text();
});

$(document).on("click", "#add-members-field", function() {
  $("#add-members-text-field").focus();
});


function add_member(name, username) {
  $("#add-members-text-field").focus();
  $("#add-members-text-field").text("");
  $("#add-member-tags-container").append('<div class="profile tag is-medium" data-username="'+username+'"><span>'+name+'</span><span class="icon remove-member"><a class="delete"></a></span></div>')
  updatePlaceholder();
  get_connections_from_text();
}

$(document).on("click", function(e) {
  if (!($(e.target)[0] === $("#add-members-field")[0] || $(e.target).parent()[0] === $("#members-field")[0])) {
  $('#select-connections').addClass("vanish");
  $('#select-connections').empty();
}
});

$(document).on("click", "#add-members-button", function() {
  get_connections_from_text();
});

$(document).on("click", ".profile-bigBox", function() {
  add_member(name=$(this).data('name'),username=$(this).data('username'));
});



$(document).on("click", ".remove-member", function() {
  $(this).closest('div').remove();
  updatePlaceholder();
});


$(document).on('keydown', '#add-members-text-field', function(event) {
    var key = event.keyCode || event.charCode;

    if (key == 8 && $("#add-members-text-field").text().length == 0){
        $("#add-member-tags-container").children().last().remove();
      }

    if (key == 13 || key == 9 || key == 10) {
      if (key == 10 || key == 13) {
        event.preventDefault();
      }
      if ($(".hovered").length == 1) {
      add_member(name=$(".hovered").data('name'),username=$(".hovered").data('username'));
    }
    }
  });


$(document).on('mouseover', '.profile-bigBox', function() {
  $(this).addClass('hovered');
});

$(document).on('mouseleave', '.profile-bigBox', function() {
  $(this).removeClass('hovered');
});
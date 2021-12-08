$(document).on('click', '#more-details-button', function() {
    if ($('#more-details-dropdown').hasClass('is-active')) {
      $('#more-details-dropdown').removeClass('is-active');
    }
    else {
      $('#more-details-dropdown').addClass('is-active');
    }
  });

$(document).click(function(event) { 
  var $target = $(event.target);
  if(!$target.closest('#more-details-dropdown').length && 
  $('#more-details-dropdown').is(":visible")) {
    $('#more-details-dropdown').removeClass('is-active');;
  }        
});

$(document).on('click', '#connect-button', function() {
	console.log($(this).data('type'));
	if ($(this).data('type') == "default") {
		connect();
	}

	else if ($(this).data('type') == "pending"){
		undoConnect();
	}

	else if ($(this).data('type') == "accept"){
		acceptConnect();
	}

	else if ($(this).data('type') == "connected"){
    console.log("ye");
		disconnect();
	}

});

function connect() {
  var formData = new FormData();
   formData.append('do', true);
  $.post({
      type: "POST",
      url: "/connect/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {
          makeConnectButtonPending();
        }
      }});
}

function undoConnect() {
  var formData = new FormData();
   formData.append('undo', true);
  $.post({
      type: "POST",
      url: "/connect/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {
          makeConnectButtonDefault();
        }
      }});
}

function disconnect() {
  var formData = new FormData();
   formData.append('disconnect', true);
  $.post({
      type: "POST",
      url: "/connect/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {
          makeConnectButtonDefault();
        }
      }});
}

function acceptConnect() {
	var formData = new FormData();
   formData.append('accept', true);
  $.post({
      type: "POST",
      url: "/connect/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {
          makeConnectButtonConnected();
        }
      }});
}

$(".subprofile-identity").hover(
  function() {
    $(this).find('.subprofile-name').addClass('underlined');
        
  }, function() {
      $(this).find('.subprofile-name').removeClass('underlined');

  }
  );

$(".subprofile").on('click', function() {
  if (!getSelection().toString()) {
  window.location.href = $(this).find('.subprofile-identity').attr('href');
}
else {
    getSelection().empty();
}

});

$(".subprofile-bio").on('click', function(e) {
  e.stopPropagation();
  if (!getSelection().toString()) {
  window.location.href = $(this).find('.subprofile-identity').attr('href');
  }

});
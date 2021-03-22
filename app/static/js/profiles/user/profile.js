$(document).on('click', 'ul li', function() {
	$('ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-associate").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

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

  window.location.href = $(this).find('.subprofile-name').attr('href');

});

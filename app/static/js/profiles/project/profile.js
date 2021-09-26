$(document).on('click', 'ul li', function() {
	$('ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-associate").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

});

$(document).on('click', '#join-button', function() {
	console.log($(this).data('type'));
	if ($(this).data('type') == "default") {
    console.log("ok");
		connect();
	}

	else if ($(this).data('type') == "pending"){
    console.log("ha");
		undoConnect();
	}

	else if ($(this).data('type') == "accept"){
    console.log("ho");
		acceptConnect();
	}

	else if ($(this).data('type') == "joined"){
    console.log("ye");
		disconnect();
	}

});

function connect() {
  var formData = new FormData();
   formData.append('do', true);
   console.log("yo");
  $.post({
      type: "POST",
      url: "/join/project/"+handle+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        console.log("yo");
        var response = JSON.parse(response);
        console.log("yo");
        var status = response["status"];
        console.log("yo");
        if (status === "success") {
          console.log("yo");
          makeConnectButtonPending();
        }
      }});
}

function undoConnect() {
  var formData = new FormData();
   formData.append('undo', true);
  $.post({
      type: "POST",
      url: "/join/project/"+handle+"/",
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
      url: "/join/project/"+handle+"/",
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
      url: "/join/project/"+handle+"/",
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
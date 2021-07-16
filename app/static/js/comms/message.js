function sendMessage(msg) {
	var formData = new FormData();
	formData.append("msg", msg);
	$.post({
      type: "POST",
      url: "/message/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
    }});
}

function getMessages() {
	var formData = new FormData();
	formData.append("latest", msg);
	$.post({
      type: "POST",
      url: "/message/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
    }});
}

function pressSend() {
	if ($('#text-field').val()) {
		sendMessage($('#text-field').val());
	}
	$('#text-field').val('');
}

$(document).on('click','#send-button', pressSend);
$('#text-field').keypress(function(event){
  if(event.keyCode == 13){event.preventDefault(); pressSend()}});
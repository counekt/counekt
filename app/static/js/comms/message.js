function sendMessage(text) {
	var formData = new FormData();
	formData.append("text", text);
	$.post({
      type: "POST",
      url: "/message/"+username+"/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        sleep = false;
        console.log("SUCCESS");
        getMessages();
    }});
}

var sleep = false;


setInterval(getMessages, 5000);

function getMessages() {
  if (sleep) {
    return;
  }
  sleep = true;
  setTimeout(function() {
        sleep = false;
      }, 5000);
	var formData = new FormData();
	var latest_msg_id = $('#messages').children().last().data('id');
	formData.append("latest_id", latest_msg_id);
  $.get("/get/messages/"+username+"/"+latest_msg_id+"/", function(JSONresponse, status) {
        var response = JSON.parse(JSONresponse);
        var messages = response["latest_messages"];
        console.log(messages);
        if (messages) {
        messages.forEach(function(msg, index) {
          latest_msg_id += 1;
          console.log("this msg");
          console.log(msg.id);
          var displayed_messages = [];
          $('#messages .message').each(function(){
            displayed_messages.push($(this).data('id'));
          });
          console.log(displayed_messages);
          if (!(msg.id in displayed_messages)) {
          $("#messages").append(msg_template(msg.dname,msg.href,msg.sender,'unread',msg.id,msg.text));
          }
        });
      }
    });
}

function checkForDuplicates() {
  var displayed_messages = [];
          $('#messages .message').each(function(){
            displayed_messages.push($(this).data('id'));
          });

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
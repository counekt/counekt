$(".notif").on('click', function() {
	readNotif($(this).data('id'));
});

function readNotif(id) {
	var formData = new FormData();
   formData.append('id', id);
  $.post({
      type: "POST",
      url: "/notifications/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {
          makeNotifRead(id);
        }
      }});
}

function makeNotifRead(id) {
	$(".notif[data-id='"+id+"']").removeClass('unread');
}
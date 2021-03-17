$(document).on('click', 'ul li', function() {
	$('ul li').removeClass('is-active');
	$(this).addClass('is-active');
	$(".profile-associate").addClass('vanish');
	$($(this).data('content')).removeClass('vanish');

});

$(document).on('click', '#connect-button', function() {

	

});


function connect() {
  var formData = new FormData();
  formData.append('address', $("#location-field").val());
  $.post({
      type: "POST",
      url: "/connect/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {}
      }});
}
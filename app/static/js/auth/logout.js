$(document).on('click', '#logout', function() {
	logout(function() {
		window.location.replace("/");
	});
});

$(document).on('click', '#cancel', function() {
	if (document.referrer) {
        		window.location.replace(document.referrer);
        	}
        	else {
        		window.location.replace("/");
        	}
});

 function logout(callback) {
 	$.post({
      type: "POST",
      url: "/logout/",
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {callback();}

      }});
 }
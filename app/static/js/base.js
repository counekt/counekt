 $(window).on("load", function () {
		if (! $.cookie("hasEntered")){
      window.loading_delay = 0;
			unload(window.loading_delay);
   $.cookie("hasEntered", true);
}
else {
  window.loading_delay = 0;
	unload(window.loading_delay);
}});

function unload(_delay) {
	$("#loader").delay(_delay).fadeOut("slow");
	$("#page").css('display', 'block');
}

 function swap_url(url){
     window.history.pushState("", "", url);
 }

 function logout() {
 	$.post({
      type: "POST",
      url: "/logout/",
      success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        if (status === "success") {window.location.reload(true);}

      }});
 }
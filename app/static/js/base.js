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

 function redirect(object, title, url, what) {
   if (window.history.pushState) {
    // supported.
    window.history.pushState(object, title, url);
    what();
    }

   else {
     window.location = url;
   }
 }

 function flash(c,bgc,txt, delay=1500){
 $("#flash").stop(stopAll=true);
 $("#flash").css('color', c);
 $("#flash").css('background-color', bgc);
 $("#flash").animate({ opacity: 1, queue: false });
 $("#flash").children().text(txt);
 $("#flash").delay(delay).animate({ opacity: 0, queue: false });
}
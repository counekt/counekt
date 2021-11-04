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

 function redirect(object, title, url, what=function() {}) {
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

function post(url, success, args) {
    var formData = new FormData();
    Object.keys(args).forEach((key,index) => {
        formData.append(key,args[key]);
    });
    try {


    $.post({
        type: "POST",
        url: url,
        data: formData,
        processData: false,
        contentType: false,
        success
    });

} catch (error) {
  console.error(error);
  setTimeout(function(){post(url,success,args)}, 5000);
}
  
  }


function isScrolledIntoView(elem)
{
    var docViewTop = $(window).scrollTop();
    var docViewBottom = docViewTop + $(window).height();

    var elemTop = $(elem).offset().top;
    var elemBottom = elemTop + $(elem).height();

    return ((elemBottom <= docViewBottom) && (elemTop >= docViewTop));
}

function Utils() {

}

Utils.prototype = {
    constructor: Utils,
    isElementInView: function (element, fullyInView) {
        var pageTop = $(window).scrollTop();
        var pageBottom = pageTop + $(window).height();
        var elementTop = $(element).offset().top;
        var elementBottom = elementTop + $(element).height();

        if (fullyInView === true) {
            return ((pageTop < elementTop) && (pageBottom > elementBottom));
        } else {
            return ((elementTop <= pageBottom) && (elementBottom >= pageTop));
        }
    }
};

var Utils = new Utils();

$(document).on('click', '.q', function() {
var a = $(this).next('.a');
if (a.css("display") === "none") {
		$('.a').css("display", "none");
		a.css("display", "block");
		$('html, body').animate({
        scrollTop: $(this).offset().top - 10
    }, 2000);
}

else {
		a.css("display", "none");
}

});
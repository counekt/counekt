$(".subprofile-identity").hover(
  function() {
    $(this).find('.subprofile-name').addClass('underlined');
        
  }, function() {
      $(this).find('.subprofile-name').removeClass('underlined');

  }
  );

$(".subprofile").on('click', function() {
  if (!getSelection().toString()) {
    var href = $(this).find('.subprofile-identity').attr('href');
    if (href) {window.location.href = href;}
}
else {
    getSelection().empty();
}

});

$(".subprofile-bio").on('click', function(e) {
  e.stopPropagation();
  if (!getSelection().toString()) {
  var href = $(this).find('.subprofile-identity').attr('href');
  if (href) {window.location.href = href;}
  }

});
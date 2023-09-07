$(".subprofile-identity").hover(
  function() {
    $(this).find('.subprofile-name').addClass('underlined');
        
  }, function() {
      $(this).find('.subprofile-name').removeClass('underlined');

  }
  );

$(".subprofile").on('click', function() {
  if (!getSelection().toString()) {
  window.location.href = $(this).find('.subprofile-identity').attr('href');
}
else {
    getSelection().empty();
}

});

$(".subprofile-bio").on('click', function(e) {
  e.stopPropagation();
  if (!getSelection().toString()) {
  window.location.href = $(this).find('.subprofile-identity').attr('href');
  }

});
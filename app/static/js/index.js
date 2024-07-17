function adjustSurveyHeight() {
  $iframe = $(".survey-container");

  $iframeForm = $iframe.find('form');

  $iframe.height($iframeForm.height());
}

$(window).scroll(function(e){ 
  var $el = $('#semi-sticky');
  var stickyCloneExists = $('#semi-sticky-clone').length > 0;
  if ($(this).scrollTop() > $el.offset().top && !stickyCloneExists){
    $el.clone().removeAttr('id').attr("id","semi-sticky-clone").css({'position':'fixed','top':'0px'}).appendTo($el.parent());
  }
  if ($(this).scrollTop() < $el.offset().top && stickyCloneExists){
    $('#semi-sticky-clone').remove();
  } 
});
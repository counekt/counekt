function changeToFeed() {
  $("#modal-box").empty();
  $(document.body).removeClass('noscroll');
}

  $(document).on('click', '.close, .modal-background', function() {
    changeToFeed();
  //redirect({id:"user-profile"}, "Wall", "/wall/", changeToWall);
});

  $(document).on('click', '.medium-love-interact', function() {
    $this = $(this);
    $icon = $this.find('span i');
    $icon.toggleClass('far fas');
    
    $this.closest('.level-item').toggleClass('active inactive');

  });

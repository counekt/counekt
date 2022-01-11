function changeToFeed() {
  $("#modal-box").empty();
  $(document.body).removeClass('noscroll');
}

  $(document).on('click', '.close, .modal-background', function() {
    changeToFeed();
  //redirect({id:"user-profile"}, "Wall", "/wall/", changeToWall);
});


$(".search-filter-bar-b[data-active='false']").on('click', function() {
        searchFeedback();
});
  

  $('.medium').on('click', '.medium-love-interact', function() {
    console.log("WOOP");
    var $clicked = $(this);
    var $medium = $clicked.closest('.medium');
    var $medium_love = $clicked.closest('.medium-love');
    var $counter = $medium_love.find('.number-info').find('span');
    var is_hearted = $medium_love.hasClass('active');
    var medium_id = $medium.data('id');
    var clicked = this;
    $icon = $clicked.find('span i');
    console.log(is_hearted);
    if (!is_hearted) {
      heart(medium_id);
    }

    else if (is_hearted) {
      unheart(medium_id);
    }

  function display_heart() {
    $medium_love.addClass('active');
    $counter.text(parseInt($counter.text())+1);
    $clicked.attr('data-active', "true");
    $icon.addClass('fas').removeClass('far');


  }

  function display_unheart() {
     $medium_love.removeClass('active');
     $counter.text(parseInt($counter.text())-1);
     $clicked.attr('data-active', "false");
     $icon.addClass('far').removeClass('fas');
  }

  function heart(medium_id) {
    display_heart();
    post("/medium/vote/", function (response) {
      var status = JSON.parse(response)["status"];
      if (status === "success") {
      

      }
      else {
      
        display_unheart();
    }
      },{'action':'heart','medium_id':medium_id});
  
  }

  function unheart(medium_id) {
    display_unheart();
    post("/medium/vote/", function (response) {
      var status = JSON.parse(response)["status"];
      if (status === "success") {
     
      }
      else {
        display_heart();
      }
    },{'action':'unheart','medium_id':medium_id});
  }

    });

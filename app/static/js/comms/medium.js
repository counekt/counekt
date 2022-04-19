function changeToFeed() {
  $("#modal-box").empty();
  $(document.body).removeClass('noscroll');
}

  $(document).on('click', '.medium', function(e) {

    var $target = $(e.target);
  // if click not on clickables
  if (!$('.clickable').has($target).length && !$target.hasClass('clickable')) {
      var medium_id = $(this).data('id');
      console.log("MEDIUM CLICK");
      goToIndividualMedium(medium_id);
  }
  
});

  function clearWall() {
  $(".wall").empty();
}

  function displayLoading() {
  clearWall();
  $(".wall").append(infoLoader());
}

function goToIndividualMedium(medium_id, do_redirect=true) {
      console.log(medium_id);
        var pageObject = {'is_search':false,'medium_id':medium_id};
      if (do_redirect) {redirect(pageObject, "Medium Post", "/user/"+username+"/medium/"+medium_id +"/", function(){});}
         else {window.history.replaceState(pageObject,"Medium Post", "/user/"+username+"/medium/"+medium_id +"/");}
      displayLoading();
      post("/user/"+username+"/medium/"+medium_id +"/", function (response) {
      var response = JSON.parse(response);
      var status = response["status"];
      if (status === "success") {
        var medium = response["medium"];
        clearWall();
        $(".wall").append(mediumFocused(medium.id,medium.title,medium.content,medium.author.dname,medium.author.symbol,medium.author.username,medium.creation_datetime,medium.author.href, medium.author.profile_photo_src, medium.reply_count, medium.quote_count, medium.heart_count, medium.is_hearted));
      }},{});
  
}

  $(document).on('click', '.medium .medium', function(e) {
    var $target = $(e.target);
  // if click not on clickables
  if (!$('.clickable').has($target).length && !$target.hasClass('clickable')) {
      var medium_id = $(this).data('id');
      console.log("MEDIUM QUOTE CLICK");
  }
  });


  $(document).on('click', '.close, .modal-background', function() {
    changeToFeed();
  //redirect({id:"user-profile"}, "Wall", "/wall/", changeToWall);
});


$(".search-filter-bar-b[data-active='false']").on('click', function() {
        searchFeedback();
});
  
  $('.medium').on('click', '.medium-quote-reply-interact', function() {
      var $clicked = $(this);
      var $medium = $clicked.closest('.medium');
      var $identiy = $medium.find('.medium-identity');
      var $profile_picture = $medium.find('figure.image');
      var $text_content = $medium.find('.text-content');
      var medium_id = $medium.data('id');
      console.log($text_content.html());
      changeToQuoteMedium($identiy.html(), $profile_picture.html(), $text_content.html(), medium_id);

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

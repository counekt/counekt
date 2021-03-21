// Open or Close mobile & tablet menu
// https://github.com/jgthms/bulma/issues/856
$("#navbar-burger-id").click(function () {
  if($("#navbar-burger-id").hasClass("is-active")){
    $("#navbar-burger-id").removeClass("is-active");
    $("#navbar-menu-container-id").css("display","none");
    closeMore();
  }else {
    $("#navbar-burger-id").addClass("is-active");
    $("#navbar-menu-container-id").css("display","block");
  }
});
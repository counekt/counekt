function loadImage(event, display) {
  if (event.target.files[0]) {
  $(display).attr('src', URL.createObjectURL(event.target.files[0]));
}
};
$(document).on('change','#selected-skill',function(){
               if ($('#selected-skill').val() != 'Select skill') {
                $('#add-skill').prop("disabled", false);
               }       
             });



 $(document).on("click", "#add-a-skill", function() {
    $('#add-a-skill-wrap').remove();
    $('#skill-select-form').removeClass("vanish");
    if ($('#selected-skill').val() == 'Select skill') {
            $('#add-skill').prop("disabled", true);
    }
    $(".modal-card-body").animate({ scrollTop: $(".modal-card-body").prop("scrollHeight")}, 1000);     
  });

 $(document).on("click", "#add-skill", function() {
  $('#skill-select-form').addClass("vanish");
  $("#skills").append("<div class='skill'><button class='button is-info is-normal is-'><span class='skill-title'>"+$('#selected-skill').val()+"</span><span class='icon remove-skill'><a class='delete'></a></span></button></div>");
  $('#skills').append(`<div id="add-a-skill-wrap"><button id="add-a-skill" class="button is-info is-normal is-inverted">
      <span>Add skill</span>
      <span class="icon is-normal is-danger"><i class="fa fa-plus"></i>
      </span></button></div>
      </div>`);
  $('#selected-skill option:selected').remove();
  console.log($('#selected-skill').children().length)
  if ($('#selected-skill').children().length == 1) {
    $('#add-a-skill-wrap').remove();
  }
 });


 $(document).on("click", ".remove-skill", function() {
  $('#selected-skill').append('<option>'+$(this).prev('span').text()+'</option>')
  $(this).closest('div').remove();
  if (!$("#add-a-skill-wrap").length && $('#skill-select-form').hasClass('vanish')) {
  $('#skills').append(`<div id="add-a-skill-wrap"><button id="add-a-skill" class="button is-info is-normal is-inverted">
      <span>Add skill</span>
      <span class="icon is-normal is-danger"><i class="fa fa-plus"></i>
      </span></button></div>
      </div>`);
}

});
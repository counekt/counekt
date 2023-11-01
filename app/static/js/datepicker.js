$(document).on('change', '#month', function() {
  console.log("Change in month");
  if ($('#month').val() == 1 || $('#month').val() == 3 || $('#month').val() == 5 || $('#month').val() == 7 || $('#month').val() == 8 || $('#month').val() == 10 || $('#month').val() == 12) {
    $('#day').children().eq(29).prop('disabled', false);
    $('#day').children().eq(30).prop('disabled', false);
    $('#day').children().eq(31).prop('disabled', false);
    $('#year').children('[data-leapyear="0"]').prop('disabled', false);
  }
  else if ($('#month').val() == 4 || $('#month').val() == 6 || $('#month').val() == 9 || $('#month').val() == 11) {
    $('#day').children().eq(29).prop('disabled', false);
    $('#day').children().eq(30).prop('disabled', false);
    $('#day').children().eq(31).prop('disabled', true);
    $('#year').children().prop('disabled', false);

    if ($('#day option:selected').val() == 31) {
      $('#day option:selected').prop("selected", false);
    }

    $('#year').children('[data-leapyear="0"]').prop('disabled', false);
  }
  else if ($('#month').val() == 2) {
    console.log("February")
    // If Leap Year; add the 29th day of February
    if ($('#year option:selected').attr('data-leapyear') == 1 ){
      $('#day').children().eq(29).prop('disabled', false);
    }
    else {
      $('#day').children().eq(29).prop('disabled', true);
    }
    $('#day').children().eq(30).prop('disabled', true);
    $('#day').children().eq(31).prop('disabled', true);

    if ($('#day option:selected').val() >= 30) {
      $('#day option:selected').prop("selected", false);
    }

    if ($('#day option:selected').val() == 29) {

      if ($('#year option:selected').attr('data-leapyear') == 0) {
        console.log("Not leapyear");
        $('#day option:selected').prop("selected", false);
      }
      else {
      $('#year').children('[data-leapyear="0"]').prop('disabled', true);
    }
    }
  }
});

$(document).on('change', '#day', function() {
  if ($('#day').val() == 29 && $('#month').val() == 2) {
    $('#year').children('[data-leapyear="0"]').prop('disabled', true);
  }
  else {
    $('#year').children('[data-leapyear="0"]').prop('disabled', false);
  }});

$(document).on('change', '#year', function() {
  // If Leap Year; add the 29th day of February
  if (parseInt($('#year').val()) % 4 === 0 && (parseInt($('#year').val()) % 100 !== 0 || parseInt($('#year').val()) % 400 === 0)) {
    $('#day').children().eq(29).prop('disabled', false);
  }});
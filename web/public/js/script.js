$.urlParam = function(name) {
    return decodeURI(
        (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,null])[1]
    );
}

$(document).ready(function() {
	// load embedded JSON for locations
	var locations = $.parseJSON($('#locations').html());
	var body_types = $.parseJSON($('#body_types').html());

	var location_select = $('#select_location');
	var body_type_select = $('#select_body_type');
	$.each(locations,function(ind,location) {
		location_select.append("<option>"+location+"</option>");
	});
	$.each(body_types,function(ind,body_type) {
		body_type_select.append("<option>"+body_type+"</option>");
	});

	if($.urlParam("location") != 0) {
		location_select.val(decodeURIComponent($.urlParam("location")));
	}
	if($.urlParam("body_type") != 0) {
		body_type_select.val(decodeURIComponent($.urlParam("body_type")));
	}

	location_select.change(function(){
		window.location = "/?location="+$('#select_location').val()+"&body_type="+$('#select_body_type').val();
	});
	body_type_select.change(function(){
		window.location = "/?location="+$('#select_location').val()+"&body_type="+$('#select_body_type').val();
	});

  // Load embedded JSON into list templates
  image_paths = $("#image_paths").html();
  image_paths = $.parseJSON(image_paths);
  tempo = Tempo.prepare("pictures").render(image_paths);

  // Request more JSON when scrolling close to the bottom
  pixelBuffer = 100;
  alreadyloading = false;
  last = parseInt($('#pictures').attr('last'));
  $(window).scroll(function() {
    if ($('body').height() <= (pixelBuffer +
                               $(window).height() +
                               $(window).scrollTop())) {
      if (alreadyloading == false) {
        alreadyloading = true;
        $.getJSON(
          "/pics",
          {
						last: last,
						location: $('#select_location').val(),
						body_type: $('#select_body_type').val()
					},
          function(data) {
            tempo.append(data);
            last += data.length;
            alreadyloading = false;
						$('.tipper').tipsy();
          }
        );
      }
    }
  });
	$('.tipper').tipsy();
});

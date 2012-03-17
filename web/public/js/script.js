$.urlParam = function(name) {
    return decodeURI(
        (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,null])[1]
    );
}

$(document).ready(function() {
	// load embedded JSON for locations
	var locations = $.parseJSON($('#locations').html());
	
	var loc_sel = $('#select_location');
	$.each(locations,function(ind,location) {
		loc_sel.append("<option>"+location+"</option>");
	});
	
	if($.urlParam("location") != 0) {
		loc_sel.val(decodeURIComponent($.urlParam("location")));
	}
	
	loc_sel.change(function(){
		window.location = "/?location="+$('#select_location').val();
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
						location: $('#select_location').val()
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

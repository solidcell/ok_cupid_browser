$(document).ready(function() {
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
          {last: last},
          function(data) {
            tempo.append(data);
            last += data.length;
            alreadyloading = false;
          }
        );
      }
    }
  });
	$('.tipper').tipsy();
});

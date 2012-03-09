$(document).ready(function() {
  // Load embedded JSON into list templates
  image_paths = $("#image_paths").html();
  image_paths = $.parseJSON(image_paths);
  tempo = Tempo.prepare("pictures").render(image_paths);

  // TODO: we probably don't need this since we only load
  //       a handful of images past the bottom
  function lazyload() {
    $("img.lazy").lazyload({ threshold: 200 });
  }
  // Set the list templates to lazy load the images
  lazyload();

  // Request more JSON when scrolling close to the bottom
  pixelBuffer = 300;
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
            lazyload();
            last += data.length;
            alreadyloading = false;
          }
        );
      }
    }
  });
});

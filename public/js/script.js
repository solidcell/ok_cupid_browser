$(document).ready(function() {
  var image_paths = $("#image_paths").html();
  image_paths = $.parseJSON(image_paths);
  Tempo.prepare("pictures").render(image_paths);

  $("img.lazy").lazyload();
});

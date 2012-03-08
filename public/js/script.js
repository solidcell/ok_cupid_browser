$(document).ready(function() {
  var image_paths = $("#image_paths").html();
  image_paths = $.parseJSON(image_paths);
  test_image_paths = [
    {'url':'profile_pictures/small/chottochagol_13533430516552857947.jpeg',
     'username':'chottochagol'},
    {'url':'profile_pictures/small/Cierrautumn_8193661997457597102.jpeg',
     'username':'Cierrautumn'}
  ]

  Tempo.prepare("pictures").render(test_image_paths);

  $("img.lazy").lazyload();
});

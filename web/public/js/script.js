$.urlParam = function(name) {
    return decodeURI(
        (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,null])[1]
    );
}

$(document).ready(function() {
	// load embedded JSON for dropdowns
  var filters = ["location", "body_type"]
  filters.forEach(function(filter){
    var collection = $.parseJSON($('#'+filter+'s').html());
    var select = $('#select_'+filter);
    $.each(collection,function(ind,element) {
      select.append("<option>"+element+"</option>");
    });
    if($.urlParam(filter) != 0) {
      select.val(decodeURIComponent($.urlParam(filter)));
    }
    select.change(function(){
      var params = []
      filters.forEach(function(f){
        params.push(f+"="+$('#select_'+f).val());
      })
      window.location = "/?"+params.join("&");
    });
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
        var params = { last: last };
        filters.forEach(function(filter){
          params[filter] = $('#select_'+filter).val();
        });
        $.getJSON(
          "/pics",
          params,
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

  $('.picture').hover(function() {
    $(this).find('.hide').fadeIn(100);
  }, function() {
    $(this).find('.hide').fadeOut(200);
  });
});

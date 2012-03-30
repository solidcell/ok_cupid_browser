$.urlParam = function(name) {
    return decodeURI(
        (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,null])[1]
    );
}

$(document).ready(function() {
  var busy_usernames = {};

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

  $('.picture').hover(
    function() {
      $(this).find('.hide').show();
    },
    function() {
      if (busy_usernames[$(this).attr('original-title')] != true)
        $(this).find('.hide').hide();
    }
  );

  $('.picture .hide').hover(
    function() {
      $(this).addClass('hover');
    },
    function() {
      $(this).removeClass('hover');
    }
  );

  $('.hide').click(function() {
    var t = $(this);
    var parent = t.parent('.picture');
    var hide_do = t.find('.prompt.do');
    var hide_undo = t.find('.prompt.undo');
    var spinner = t.find('.spinner');
    var username = parent.attr('original-title');
    var imgs = $("[original-title='"+username+"'] .profile_link img")
    busy_usernames[username] = true;
    hide_do.hide();
    spinner.show();
    imgs.addClass('translucent');
    var data = {};
    data[username] = "hide";
    $.post('/hide',
           data,
           function(reponse) {
             spinner.hide();
             hide_undo.show();
           }
    );
  });
});

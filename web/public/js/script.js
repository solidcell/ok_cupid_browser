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
      var username = $(this).attr('original-title');
      var container_set = $("[original-title='"+username+"']");
      var img_set = container_set.find(".profile_link img");
      img_set.addClass('translucent80');
    },
    function() {
      if (busy_usernames[$(this).attr('original-title')] != true)
        $(this).find('.hide').hide();
      var username = $(this).attr('original-title');
      var container_set = $("[original-title='"+username+"']");
      var img_set = container_set.find(".profile_link img");
      img_set.removeClass('translucent80');
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
    var container = t.parent('.picture');
    var username = container.attr('original-title');
    var container_set = $("[original-title='"+username+"']");
    var hide_do = t.find('.prompt.do');
    var hide_do_set = container_set.find('.prompt.do');
    var hide_undo = t.find('.prompt.undo');
    var hide_undo_set = container_set.find('.prompt.undo');
    var spinner = t.find('.spinner');
    var img_set = container_set.find(".profile_link img");
    busy_usernames[username] = true;
    hide_do.hide();
    spinner.show();
    img_set.addClass('translucent25');
    var data = {};
    data[username] = "hide";
    $.post('/hide',
           data,
           function(reponse) {
             hide_do_set.hide();
             spinner.hide();
             hide_undo_set.show();
           }
    );
  });
});

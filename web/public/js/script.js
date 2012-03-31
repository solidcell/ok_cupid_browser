$.urlParam = function(name) {
    return decodeURI(
        (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,null])[1]
    );
}

function initTooltips() {
  $('.tipper').tipsy({offset:-5, title:'username'});
}

$(document).ready(function() {
  var busy_usernames = {};
  var hidden_usernames = {};
  var hovered_username;

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
            initTooltips();
          }
        );
      }
    }
  });

  initTooltips();

  $('#pictures li').hover(
    function() {
      var username = $(this).attr('username');
      hovered_username = username;
      var container_set = $("[username='"+username+"']");
      var img_set = container_set.find(".profile_link img");
      container_set.find('.hide').show();
      img_set.addClass('hover');
    },
    function() {
      hovered_username = "";
      var username = $(this).attr('username');
      var container_set = $("[username='"+username+"']");
      var img_set = container_set.find(".profile_link img");
      //don't hide the button while it's spinning
      if (busy_usernames[username] != true)
        container_set.find('.hide').hide();
      img_set.removeClass('hover');
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

  $('.hide').click(function(e) {
    var t = $(this);
    var container = t.parents('#pictures li');
    var username = container.attr('username');
    if (busy_usernames[username] != true) {
      var container_set = $("[username='"+username+"']");
      var hide_set = container_set.find('.hide');
      var hide_do = t.find('.prompt.do');
      var hide_do_set = container_set.find('.prompt.do');
      var hide_undo = t.find('.prompt.undo');
      var hide_undo_set = container_set.find('.prompt.undo');
      var spinner = t.find('.spinner');
      var spinner_set = container_set.find('.spinner');
      var img_set = container_set.find(".profile_link img");
      busy_usernames[username] = true;
      if (hidden_usernames[username] != true) {
        hide_do_set.hide();
        spinner_set.show();
        var data = {};
        data[username] = "hide";
        $.post('/hide',
               data,
               function(reponse) {
                 hidden_usernames[username] = true;
                 busy_usernames[username] = false;
                 img_set.addClass('greyed');
                 hide_do_set.hide();
                 spinner_set.hide();
                 hide_undo_set.show();
                 //ensure buttons are hidden
                 //if mouse left hover while dissabled
                 if (hovered_username != username)
                   hide_set.hide();
               }
        );
      } else {
        hide_undo_set.hide();
        spinner_set.show();
        var data = {};
        data[username] = "unhide";
        $.post('/hide',
               data,
               function(reponse) {
                 hidden_usernames[username] = false;
                 busy_usernames[username] = false;
                 img_set.removeClass('greyed');
                 hide_undo_set.hide();
                 spinner_set.hide();
                 hide_do_set.show();
                 //ensure buttons are hidden
                 //if mouse left hover while dissabled
                 if (hovered_username != username)
                   hide_set.hide();
               }
        );
      }
    }
    e.preventDefault();
  });
});

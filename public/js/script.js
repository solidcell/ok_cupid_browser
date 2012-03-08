function fetch_pics() {
  $.ajax({
    url: '/pics',
    data: {
      last: $('ul.list').attr('last')
    },
    dataType: 'json',
    success: function(data){
      //TODO: if data is empty, then remove #infinite-scroll
      $('li.template').loadJSON(data);
      var last = parseInt($('ul.list').attr('last'));
      last = last + 10;
      $('ul.list').attr('last', last);
    }
  });
}

$(document).ready(function() {
  fetch_pics();

  $('ul').endlessScroll({
    fireOnce: true,
    fireDelay: 500,
    bottomPixels: 300,
    ceaseFire: function(){
      return $('#infinite-scroll').length ? false : true;
    },
    callback: fetch_pics
  });
});

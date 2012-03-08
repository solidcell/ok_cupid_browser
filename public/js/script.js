$(document).ready(function() {
  $('ul').endlessScroll({
    fireOnce: true,
    fireDelay: 500,
    bottomPixels: 300,
    ceaseFire: function(){
      return $('#infinite-scroll').length ? false : true;
    },
    callback: function(){
      $.ajax({
        url: '/pics',
        data: {
          last: $(this).attr('last')
        },
        dataType: 'json',
        success: function(data){
          //TODO: if data is empty, then remove #infinite-scroll
          $('li.template').loadJSON(data);
        }
      });
    }
  });
});

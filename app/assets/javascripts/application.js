// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .

document.addEventListener('DOMContentLoaded', function() {
  // HACK: Adjust the height of .board-container if the window is resized.
  //       Using css height isn't that accurate.
  function adjustBoardContainer() {
    var height = window.innerHeight || window.clientHeight;
    var divs = document.getElementsByClassName('board-container');
    var nav = document.querySelector('nav[aria-label="main navigation"]');

    for (var i = 0; i < divs.length; i++) {
      divs[i].style.height = (height - nav.clientHeight - 10) + 'px';
    }
  }

  window.addEventListener('resize', adjustBoardContainer);
  setTimeout(function() { adjustBoardContainer(); }, 1000);
});



require("@rails/activestorage").start()
require("turbolinks").start()
require.context('../images', true)
//= require('jquery');
global.$ = require('jquery')
import Rails from '@rails/ujs';
Rails.start();

//プラグイン
import "@fortawesome/fontawesome-free/js/all"
//scss
import '../src/stylesheets/application'
//
import "../src/javascripts/likes_btn.js";



require("@rails/activestorage").start()
require.context('../images', true)
global.$ = require('jquery')

import Rails from '@rails/ujs';
Rails.start();

//プラグイン
import "bootstrap"
import "@fortawesome/fontawesome-free/js/all"

//scss
import '../src/stylesheets/application'
//Javascript
import '../src/javascripts/application'

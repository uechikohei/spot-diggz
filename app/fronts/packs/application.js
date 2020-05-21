require("@rails/activestorage").start()
require.context('../images', true)
global.$ = require('jquery')

//プラグイン
import "bootstrap"
import "@fortawesome/fontawesome-free/js/all"

//scss
import '../src/stylesheets/application'
//Javascript
import '../src/javascripts/application'

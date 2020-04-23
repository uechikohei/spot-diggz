require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require.context('../images', true)

// require("channels")
// require("bootstrap"); // bootstrap_custom.js を使います
global.$ = require('jquery')

//プラグイン
import "bootstrap"
import "@fortawesome/fontawesome-free/js/all"

//scss
import '../src/stylesheets/application'
//Javascript
import '../src/javascripts/application'

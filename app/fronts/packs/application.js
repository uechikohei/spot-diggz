require("@rails/activestorage").start()
require.context('../images', true)

//↓これを削除すると、ログアウトできなくなるので注意
require("@rails/ujs").start()
global.$ = require('jquery')

//プラグイン
import "@fortawesome/fontawesome-free/js/all"

//scss
import '../src/stylesheets/application'

//Javascript
import '../src/javascripts/application'

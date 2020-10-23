global.$ = require('jquery')

import 'select2/dist/js/select2.min.js';

jQuery(function ($) {
  $('.pref').select2({
    dropdownAutoWidth: true,
    width: 'auto'
  })
})
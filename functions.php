<?php

#filter for wp_options, set WPLANG to en_GB - this is to stop it looking in the database for it before it exists
add_filter('option_WPLANG', function($value) {
	return 'en_GB';
});
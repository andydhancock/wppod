<?php

#filter for wp_options, set WPLANG to en_GB
add_filter('option_WPLANG', function($value) {
	return 'en_GB';
});
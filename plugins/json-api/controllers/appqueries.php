<?php



function tomremove_more_wpse($content) {
    if(get_query_var('json'))
    	{
        global $post;
        $content = preg_replace('/<!--more(.*?)?-->/','',$post->post_content);
	}
    return $content;
}

class JSON_API_appqueries_Controller {

var $debug1;
var $debug2;
var $debug3 = 'Test';


  public function get_recent_posts() {
    global $json_api;
    global $more; $more = -1;

    add_filter('the_content', 'tomremove_more_wpse',10);

    $posts = $json_api->introspector->get_posts();

    return $this->posts_result($posts);
  }


  public function get_recent_posts_and_features() {
    global $json_api;
    global $more; $more = -1;


    add_filter('the_content', 'tomremove_more_wpse',10);

    $url = parse_url($_SERVER['REQUEST_URI']);
    $query = wp_parse_args($url['query']);
    $tax_query = array( array(
	'taxonomy' => 'post_format',
	'field' => 'slug',
	'terms' => array( 'post-format-aside' ),
	'operator' => 'IN',
	) );

    $query['tax_query'] = $tax_query;
//    $query['count] = '2';
    $features = $json_api->introspector->get_posts($query);

    $query1 = wp_parse_args($url['query']);
    $posts = $json_api->introspector->get_posts($query1);

//    return $this->posts_result($posts);

//    add_action( 'pre_get_posts', 'be_exclude_post_formats_from_blog' );


    return $this->posts_result_pf($posts, $features);
  }

function be_exclude_post_formats_from_blog( $query ) {

	if( $query->is_main_query() && $query->is_home() ) 
{
		$tax_query = array( array(
			'taxonomy' => 'post_format',
			'field' => 'slug',
			'terms' => array( 'post-format-aside' ),
			'operator' => 'IN',
		) );
		$query->set( 'tax_query', $tax_query );
	    	$query->set( 'count', '3' );
	}

}

function get_recent_featuresOLD( ) {
    global $json_api;
    global $more; $more = -1;

    $url = parse_url($_SERVER['REQUEST_URI']);
   $query = wp_parse_args($url['query']);
    unset($query['json']);
    unset($query['post_status']);

    add_filter('the_content', 'tomremove_more_wpse',10);
 //   add_action( 'pre_get_posts', 'be_exclude_post_formats_from_blog' );

//be_exclude_post_formats_from_blog($query);
//set($query[ 'count'], 3);
//	    	$query[ 'count'] = '3';

   $query['tax_query'] = array( array(
          'taxonomy' => 'post_format',
          'field'    => 'slug',
          'terms'    => array( 'post-format-aside' ),
          'operator' => 'IN'
    ));

    $posts = $json_api->introspector->get_posts($query);
    return $this->posts_result($posts);
}


function get_recent_features( ) {
    global $json_api;
    global $more; $more = -1;

    $url = parse_url($_SERVER['REQUEST_URI']);
   $query = wp_parse_args($url['query']);
    unset($query['json']);
    unset($query['post_status']);

    add_filter('the_content', 'tomremove_more_wpse',10);
 //   add_action( 'pre_get_posts', 'be_exclude_post_formats_from_blog' );

//be_exclude_post_formats_from_blog($query);
//set($query[ 'count'], 3);
//	    	$query[ 'count'] = '3';

   $query['meta_key'] =  'vw_post_featured';
   $query['meta_value'] = '1';

    $posts = $json_api->introspector->get_posts($query);
    return $this->posts_result($posts);
}


public function get_search_results() 
{
    global $json_api;
    global $more; $more = -1;
    add_filter('the_content', 'tomremove_more_wpse',10);

    if ($json_api->query->search) {
      $posts = $json_api->introspector->get_posts(array(
        's' => $json_api->query->search
      ));
    } else {
      $json_api->error("Include 'search' var in your request.");
    }
    return $this->posts_result($posts);
  }


public function get_search_feature_resultsOLD() 
{
    global $json_api;
    global $more; $more = -1;
    add_filter('the_content', 'tomremove_more_wpse',10);

    $tax_query = array( array(
	'taxonomy' => 'post_format',
	'field' => 'slug',
	'terms' => array( 'post-format-aside' ),
	'operator' => 'IN',
	) );

    if ($json_api->query->search) {
      $posts = $json_api->introspector->get_posts(array(
        's' => $json_api->query->search,
	'tax_query' => $tax_query
      ));
    } else {
      $json_api->error("Include 'search' var in your request.");
    }
    return $this->posts_result($posts);
}

public function get_search_feature_results() 
{
    global $json_api;
    global $more; $more = -1;
    add_filter('the_content', 'tomremove_more_wpse',10);

    if ($json_api->query->search) {
      $posts = $json_api->introspector->get_posts(array(
        's' => $json_api->query->search,
	'meta_key' => 'vw_post_featured',
	'meta_value' => '1'
      ));
    } else {
      $json_api->error("Include 'search' var in your request.");
    }
    return $this->posts_result($posts);
}
 
  protected function posts_result($posts) {
    global $wp_query;

    return array(
      'count' => count($posts),
      'count_total' => (int) $wp_query->found_posts,
      'pages' => $wp_query->max_num_pages,
      'posts' => $posts
    );
  }

  protected function posts_result_pf($posts, $features) {
    global $wp_query;

    return array(
      'count' => count($posts),
      'featurecount' => count($features),
      'count_total' => (int) $wp_query->found_posts,
      'pages' => $wp_query->max_num_pages,
      'posts' => $posts,
      'features' => $features
    );
  }

}

?>
jQuery(document).ready(function($) {



// Uploading files
var file_frame;
var parentId;
 
  jQuery('.pn_button.attachment').live('click', function( event ){

    parentId = $(this).parent().attr('id');

    event.preventDefault();
 
    if ( file_frame ) {
      file_frame.open();
      return;
    }
 


    file_frame = wp.media.frames.file_frame = wp.media({
      title: jQuery( this ).data( 'uploader_title' ),
      button: {
        text: jQuery( this ).data( 'uploader_button_text' ),
      },
      multiple: false
    });
 
    file_frame.on( 'select', function() {

      var inputCer = $("input[name='"+parentId+"']");
      console.log($(inputCer));

      attachment = file_frame.state().get('selection').first().toJSON();
      $(inputCer).val(attachment['url']);


    });

 
    file_frame.open();
  });


  /* - - -- - - - -- - - - -- - - - -- */

  $('input[name="pn_text"]').on('input',function(){outputLength()});
  $('input[name="pn_badge"]').on('input',function(){outputLength()});
  $('input[name="pn_sound"]').on('input',function(){outputLength()});

  function outputLength(){

        var length = 42
         + checkLength( $('input[name="pn_text"]').val()  )
         + checkLength( $('input[name="pn_badge"]').val() ) 
         + checkLength( $('input[name="pn_sound"]').val() );

         if (length > 255) {

          $("#output").html("<b style='color:#f00'>"+length+"</b>"); 
          $("#push_button").prop('disabled', true);

         }else{
          $("#push_button").prop('disabled', false);
          $("#output").html(length); 
        }


  }

  function checkLength(text) {

      var escapedStr = encodeURI(text);
      if (escapedStr.indexOf("%") != -1) {
          var count = escapedStr.split("%").length - 1;
          if (count == 0) count++; 
          var tmp = escapedStr.length - (count * 3);
          count = count + tmp;
      } else {
          count = escapedStr.length;
      }
      return count;
  }


});
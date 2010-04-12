$(document).ready(function(){
	$(':checkbox').iphoneStyle({
	  checkedLabel: 'YES',
	  uncheckedLabel: 'NO'
	});
	
	$('#AllowEditing').bind('change',function() {
		if (this.checked) {
			$('#opt-Editor').fadeIn()
		} else {
			$('#opt-Editor').fadeOut()
		}
	})
	
	$('form').bind('submit',function(e) {
		e.preventDefault();
	})
	
	$('#import').bind('submit',function(e) {
		$('#TumblrUser').disabled = true
		$.ajax({
			url:'/import/'+$('#TumblrUser').val(),
			success: function(d) {
				$('#TumblrUser,#importinput').effect("highlight", {color:'#00ff00'}, 1000)
				$('#TumblrUser').val('')
				$('#TumblrUser').disabled = false
			},
			error: function(d) {
				$('#TumblrUser,#importinput').effect("highlight", {color:'#ff0000'}, 2000)
				$('#TumblrUser').val('')
				$('#TumblrUser').disabled = false
			}
		})
	})
	
	$('table.settings a.preset').bind('click',function(e) {
		e.preventDefault();
		$('#'+$(this).parent().attr('rel')).val(this.rel).effect("highlight", {}, 500);
	})
	
	$('#settings input').bind('change',function(e) {
		$.get($('#settings').attr('action'),$('#settings').serialize(),function(d,status) {
			$('#saved').effect("highlight", {}, 500);
			$('#saved em').text(d)
		})
	})
})
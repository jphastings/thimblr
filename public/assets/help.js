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
	
	$('table.settings a.preset').bind('click',function(e) {
		e.preventDefault();
		$('#'+$(this).parent().attr('rel')).val(this.rel).effect("highlight", {}, 500);
	})
	
	$('#settings input').bind('change',function(e) {
		$.get($('#settings').attr('action'),$('#settings').serialize())
	})
})
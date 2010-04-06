$(document).ready(function(){
	$('#thimblr a.action').bind('click',function(e) {
		console.log("CLICK!")
		e.preventDefault();
		$.get(this.href,function(data,status) {
			// Do some informing
		})
	})
	checkThemes();
	$('#theme-selector').bind('mouseenter',function(){checkThemes();});

	$('#theme-select').bind('submit',function(e){
		$.get('/theme.set',{'theme':$('#theme-selector').children(':selected').val()},function() {
			$('#theme-preview').attr('src','/thimblr');
			$('#theme-selector').children(':selected').removeClass('altered')
		})
		return false;
	});

	$('#theme-selector').bind('mouseup',function(e){
		if (e.target.nodeName.toLowerCase() === 'option')
	  		$('#theme-select').trigger('submit');
	});
	
	checkData();
	$('#data-selector').bind('mouseenter',function(){checkThemes();});

	$('#data-select').bind('submit',function(e){
		$.get('/data.set',{'data':$('#data-selector').children(':selected').val()},function() {
			$('#data-preview').attr('src','/thimblr');
			$('#data-selector').children(':selected').removeClass('altered')
		})
		return false;
	});

	$('#data-selector').bind('mouseup',function(e){
		if (e.target.nodeName.toLowerCase() === 'option')
	  		$('#data-select').trigger('submit');
	});
});

function checkThemes() {
	$.getJSON('/themes.json',function(themes) {
		$('#theme-selector option.keep').removeClass('keep')
		$('#nothemes').addClass('keep')
		$('#nothemes').css('display','block')
		$.each(themes,function(theme,hash) {
			obj = $("#theme-selector option[value='"+theme+"']")
			if (obj.length > 0) {
				if (obj.data('hash') != hash) { // Exists and is new, add a star
					obj.data('hash',hash).addClass('keep')
					obj.addClass('altered')
				} else { // Exists
					obj.addClass('keep')
				}
			} else {
				var opt = $('<option value="'+theme+'" class="keep">'+theme+'</option>')
				opt.data('hash',hash)
				$('#theme-selector').append(opt)
			}
			$('#nothemes').css('display','none')
		})
		// Remove options without the 'save' data
		$('#theme-selector :not(option.keep)').remove()
	})
}

function checkData() {
	$.getJSON('/data.json',function(data) {
		$('#data-selector option.keep').removeClass('keep')
		$.each(data,function(datum,hash) {
			obj = $("#data-selector option[value='"+datum+"']")
			if (obj.length > 0) {
				if (obj.data('hash') != hash) { // Exists and is new, add a star
					obj.data('hash',hash).addClass('keep')
					obj.addClass('altered')
				} else { // Exists
					obj.addClass('keep')
				}
			} else {
				var opt = $('<option value="'+datum+'" class="keep altered">'+datum+'</option>')
				opt.data('hash',hash)
				$('#data-selector').append(opt)
			}
		})
		// Remove options without the 'save' data
		$('#data-selector :not(option.keep)').remove()
	})
}
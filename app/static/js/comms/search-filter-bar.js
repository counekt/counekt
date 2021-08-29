$(".search-filter-bar-b").on('click', function() {
		var $clicked = $(this);
		var clicked	= this;
		$(".search-filter-bar-b").each(function() {
			var $this = $(this);
			if (this != clicked) {
			$this.attr('data-active', "false");
				$this.removeClass($this.data('on'));
			}
		});
		
		console.log($clicked.attr('data-active'));
		if ($clicked.attr('data-active') == "true") {
			/*
					$clicked.attr('data-active', "false");
					$clicked.removeClass($clicked.data('on'));
					console.log("DDED");
			*/
		}
		else {
			console.log("ADASASD");
		$clicked.attr('data-active', "true");
		$clicked.addClass($clicked.data('on'));
	}

});

	function clearSearchBy() {
		$(".search-filter-bar-b").each(function() {
			var $this = $(this);
			$this.attr('data-active', "false");
				$this.removeClass($this.data('on'));
		})
	}

	function changeSearchBy(by) {
		$(".search-filter-bar-b").each(function() {
			var $this = $(this);
		if ($this.data('name') != by) {
			$this.attr('data-active', "false");
				$this.removeClass($this.data('on'));
	}});
}

function getSearch() {
	return $('#search-bar-input').val();
}

function getBy() {
	return simplify($('.search-filter-bar-b[data-active="true"]').data('name'));
}

function simplify(value) {
	if (value == undefined) {
		return "";
	}
	return value;
}
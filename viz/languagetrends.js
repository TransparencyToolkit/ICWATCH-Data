var years = new Array();
var vals = new Array();
d3.json('../results/top_language_formatted.json', function(error, data){
    var chart1 = c3.generate({
	bindto: '#chart1',
	data: {
	    x: 'x',
	    columns: data,
	},
	axis: {
	    x : {
		tick: {
		    fit: true
		}
	    }
	}
    });
});


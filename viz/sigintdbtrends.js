var years = new Array();
var vals = new Array();
d3.json('../results/sigintdbtrends.json', function(error, data){
    years[0] = 'x';
    vals[0] = 'People using SIGINT Databases';
    for(var z = 1; z <= data.length; z++){
	years[z] = data[z-1][0];
	vals[z] = data[z-1][1];
    }

    var chart1 = c3.generate({
	bindto: '#chart1',
	data: {
	    x: 'x',
	    columns: [
		years,
		vals
	    ],
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


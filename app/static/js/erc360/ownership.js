function update_ownership(address) {
        console.log("updating...");
        $("#reload-ownership").prop('disabled', true);$("#reload-ownership").addClass('is-loading');
        $.post("/€"+address+"/update/ownership/",function(response) {
                $.get("/€"+address+"/get/ownership/", function(ownership, status) {
                        var chartStatus = Chart.getChart("erc360-ownership-chart");
                        if (chartStatus != undefined) {chartStatus.destroy();}
                        $('#erc360-ownership-chart').show();
                        $("#loadOwnershipChart").replaceWith(ownership);
                        loadOwnershipChart();
                        $("#reload-ownership").removeClass('is-loading').prop('disabled', false);
                        console.log("success!");
        });
        });
        
}


function update_ownership(handle) {
        console.log("updating...");
        $("#reload-ownership").prop('disabled', true);$("#reload-ownership").addClass('is-loading');
        $.post("/€"+handle+"/update/ownership/",function(response) {
                $.get("/€"+handle+"/get/ownership/", function(ownership, status) {
                        var chartStatus = Chart.getChart("myChart");
                        if (chartStatus != undefined) {chartStatus.destroy();}
                        $("#loadOwnershipChart").replaceWith(ownership);
                        loadOwnershipChart();
                        $("#reload-ownership").removeClass('is-loading');
                        console.log("success!");
        });
        });
        
}


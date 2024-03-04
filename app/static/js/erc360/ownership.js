function update_ownership(address) {
        console.log("updating...");
        $("#reload-ownership").prop('disabled', true);$("#reload-ownership").addClass('is-loading');
        $.post("/€"+address+"/update/ownership/",function(response) {
                $.get("/€"+address+"/get/ownership/", function(ownershipChartHTML, status) {
                        $('#erc360-ownership-chart').show(); // show chart if hidden
                        var chart = Chart.getChart("erc360-ownership-chart");
                        if (chart != undefined) {
                                chart.destroy();
                        }
                        $("#loadOwnershipChart").replaceWith(ownershipChartHTML);
                        LOAD_OWNERSHIP_CHART_HTML = ownershipChartHTML;
                        loadOwnershipChart();
                        $("#reload-ownership").removeClass('is-loading').prop('disabled', false);
                        console.log("success!");
        });
        });
        
}


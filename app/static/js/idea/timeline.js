function update_timeline(handle) {
        console.log("updating...");
        $("#reload-timeline").prop('disabled', true);$("#reload-timeline").addClass('is-loading');
        $.post("/€"+handle+"/update/timeline/",function(response) {
                $.get("/€"+handle+"/get/timeline/", function(timeline, status) {
                        $("#timeline-content").empty();
                        $("#timeline-content").append(timeline);
                        $("#reload-timeline").removeClass('is-loading');
                        console.log("success!");
        });
        });
        
}


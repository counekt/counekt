function update_timeline(handle) {
        $.get("/€"+handle+"/get/timeline/", function(timeline, status) {
                        $("#timeline-content").html(timeline);
        });
}
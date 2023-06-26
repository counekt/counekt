function update_timeline(handle) {
        $.post("/€"+handle+"/timeline/",function(response) {
                $.get("/€"+handle+"/get/timeline/", function(timeline, status) {
                        $("#timeline-content").html(timeline);
        });
        });
        
}


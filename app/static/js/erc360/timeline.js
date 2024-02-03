function update_timeline(address) {
        console.log("updating...");
        $("#reload-timeline").prop('disabled', true);$("#reload-timeline").addClass('is-loading');
        $.post("/€"+address+"/update/timeline/",function(response) {
                $.get("/€"+address+"/get/timeline/", function(timeline, status) {
                        TIMELINE_HTML = timeline;
                        $("#timeline-content").html(timeline);
                        $("#reload-timeline").removeClass('is-loading');
                        console.log("success!");
        });
        });
        
}


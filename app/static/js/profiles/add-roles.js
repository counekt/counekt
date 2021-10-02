function load_add_roles_js() {
    $(document).on("click", "#role-save-button", function() {
        console.log("ok");
       sendRole();
    });
}


function sendRole(){
    post("/club/"+handle+"/roles/", function(response){
        var response = JSON.parse(response);
        var status = response["status"]; 
        if (status == "success") {
      		flash('#ffff','#3abb8','A role has been created', delay=1500);
        }
    }, {permissionToReceiveNotifications: $('#notif').is(':checked') ? 1 : 0, permissionToAnswerInvite: $('#invite').is(':checked') ? 1 : 0, permissionToRejectPeople: $('#reject').is(':checked') ? 1 : 0, permissionToCreateRoles: $('#roleCreator').is(':checked') ? 1 : 0, permissionToChangePeopleRoles: $('#changeRole').is(':checked') ? 1 : 0, permissionToEditPage: $('#edit').is(':checked') ? 1 : 0, permissionToCreatePrivatePosts: $('#privatePost').is(':checked') ? 1 : 0, permissionToCreatePublicPosts: $('#publicPost').is(':checked') ? 1 : 0, name: $("#name").val()});
}

/*
function getSelectedValue(){
    var selectedValue = document.getElementById("list").value;
    console.log(selectedValue);
}
getSelectedValue();*/
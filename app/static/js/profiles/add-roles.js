function load_add_roles_js() {

    $(document).on("click", "#send-invites-button", function() {
       sendInvites();
      });
    
    var checkboxes = document.querySelectorAll("input[type='checkbox']");
    for(var checkbox of checkboxes){
        checkbox.addEventListener('click', function(){
            if(this.checked == true){
                
            }
        })
    }
    
}
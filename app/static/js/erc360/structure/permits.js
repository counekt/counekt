async function uploadPermitAssignment(abi) {
    const tx = await assignPermit(abi,address,getAssignmentRecipient(),getAssignedPermit());

    if (tx) {
      update_structure(address);
      changeToStructureTab('#permits-tab-button');
    }
}

async function uploadPermitRevocation(abi) {
    const tx = await revokePermit(abi,address,getRevocationRecipient(),getRevokedPermit());

    if (tx) {
      update_structure(address);
      changeToStructureTab('#permits-tab-button');
    }
}

async function assignPermit(abi,contractAddress,account,permit) {
   setPermit(abi,contractAddress,account,permit,true);
}

async function revokePermit(abi,contractAddress,account,permit) {
 setPermit(abi,contractAddress,account,permit,false);
}

async function setPermit(abi,contractAddress,account,permit,status) {
  if (status) {
      $("#assign").prop('disabled', true).addClass('is-loading');
  } else {
    $("#revoke").prop('disabled', true).addClass('is-loading');
  }
  
  // Address of the original erc360 contract
  const web3 = getWeb3Provider();

    try {

    console.log("contract code");
    const accounts = await web3.eth.getAccounts().catch((e) => console.log(e.message));
    if (!makeSureWalletConnected()) {return;}
    console.log(accounts);
    console.log("get accounts");
    const ERC360 = new web3.eth.Contract(abi,contractAddress);
    console.log("parse contract");
    console.log(accounts[0]);
    const setting = ERC360.methods.setPermit(account,permit,status);

    const parameters = {
      from: accounts[0]
    };

    var tx;
    const settingTransaction = await setting.send(parameters, (err, transactionHash) => {
      tx = transactionHash;
    console.log(err);
    console.log('Transaction Hash :', transactionHash);
}).on('confirmation', () => {return true}).catch(()=>{

   })

      if (status) {
        console.log('Permit assignment completed:', settingTransaction);
      }
      else{console.log('Permit revocation completed:', settingTransaction);}

    return tx;
  } catch (error) {
        if (status) {
          console.error('Error Approving Permit Assignment:', error);
      }
        else {console.error('Error Approving Permit Revocation:', error);}
      }
  if (status) {
      $("#assign").prop('disabled', false).removeClass('is-loading');
  }
  else {
    $("#revoke").prop('disabled', false).removeClass('is-loading');
  }
}

async function checkAssignmentRecipient(feedback=false) {
  $this = $('#assignment-recipient-input')
  var text = getAssignmentRecipient();
  var isAddress = await getWeb3Provider().utils.isAddress(text);
  if (!feedback) {return isAddress;}
  if (isAddress) {
    $this.addClass('is-success').removeClass('is-danger');
    return true;
  } else {
    displayInvalidAssignmentRecipient();
    return false;
  }
}


function displayInvalidAssignmentRecipient() {
  message("Invalid address", ['recipient'], true);
  $('#assignment-recipient-input').addClass('is-danger').removeClass('is-success');
}

async function checkRevocationRecipient(feedback=false) {
  $this = $('#revocation-recipient-input')
  var text = getRevocationRecipient();
  var isAddress = await getWeb3Provider().utils.isAddress(text);
  if (!feedback) {return isAddress;}
  if (isAddress) {
    $this.addClass('is-success').removeClass('is-danger');
    return true;
  } else {
    displayInvalidRevocationRecipient();
    return false;
  }
}

function displayInvalidRevocationRecipient() {
  message("Invalid address", ['recipient'], true);
  $('#revocation-recipient-input').addClass('is-danger').removeClass('is-success');
}

function checkAssignable() {
  const recipientCheck = checkAssignmentRecipient(true);
  if (recipientCheck) {
    $("#assign").prop('disabled',false);
  } else {$("#assign").prop('disabled',true);}
}

function checkRevokable() {
  const recipientCheck = checkRevocationRecipient(true);
  if (recipientCheck) {
    $("#assign").prop('disabled',false);
  } else {$("#assign").prop('disabled',true);}
}

$(document).on('click', '#assign', function() {
  console.log("assign");
   var abi = $.getJSON("/erc360corporatizable/abi/", function(abi) {
        uploadPermitAssignment(abi);
     });
});

$(document).on('click', '#revoke', function() {
  console.log("revoke");
   var abi = $.getJSON("/erc360corporatizable/abi/", function(abi) {
        uploadPermitRevocation(abi);
     });
});

$(document).on('blur input','#assignment-recipient-input',function(event) {
    checkAssignable();
 });

$(document).on('blur input','#revocation-recipient-input',function(event) {
    checkRevokable();
 });

function getAssignmentRecipient() {return $('#assignment-recipient-input').val();}
function getRevocationRecipient() {return $('#revocation-recipient-input').val();}
function getAssignedPermit() {return "0x"+$('#assignment-permit-select').find('option:selected').val();}
function getRevokedPermit() {return "0x"+$('#revocation-permit-select').find('option:selected').val();}

$(document).on('change', '#permits-select', function (e) {
    var optionSelected = $(this).find("option:selected");
      console.log(optionSelected);
    console.log(optionSelected.val());
    $(".permit-table").addClass('vanish');
    $(optionSelected.val()).removeClass('vanish');
    console.log("dwed");
});
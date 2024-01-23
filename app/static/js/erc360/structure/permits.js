async function uploadPermitAssignment(abi) {
    const tx = await assignPermit(abi,address,getAssignedPermit(),getAssignmentRecipient());

    if (tx) {
      update_structure(address);
      changeToStructureTab('#permits-tab-button');
    }
}

async function uploadPermitRevocation(abi) {
    const tx = await revokePermit(abi,address,getRevokedPermit(),getRevocationRecipient());

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
        console.log('Permit assignment completed:', transferTransaction);
      }
      else{console.log('Permit revocation completed:', transferTransaction);}

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
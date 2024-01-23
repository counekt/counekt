async function uploadVoteIssuance(abi) {
    const tx = await issueVote(abi,address,getProposals());

    if (tx) {
      update_structure(address);
      changeToStructureTab('#referendums-tab-button');
    }
}

async function issueVote(abi,contractAddress,proposals) {
  $("#issue").prop('disabled', true).addClass('is-loading');
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
    const issuance = ERC360.methods.issueVote(sigs,args,duration);

    const parameters = {
      from: accounts[0]
    };

    var tx;
    const issuanceTransaction = await issuance.send(parameters, (err, transactionHash) => {
      tx = transactionHash;
    console.log(err);
    console.log('Transaction Hash :', transactionHash);
}).on('confirmation', () => {return true}).catch(()=>{

   })


    console.log('Vote Issuance completed:', transferTransaction);
    return tx;
  } catch (error) {
    console.error('Error Approving Vote Issuance:', error);
  }
  $("#issue").prop('disabled', false).removeClass('is-loading');
}

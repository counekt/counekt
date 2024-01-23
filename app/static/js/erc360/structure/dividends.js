async function uploadDividendDistribution(abi) {
    const tx = await distributeDividend(abi,address,getDividend(),getPermitRecipient());

    if (tx) {
      update_structure(address);
      changeToStructureTab('#dividends-tab-button');
    }
}

async function distributeDividend(abi,contractAddress,bank,token,amount) {
  $("#distribute").prop('disabled', true).addClass('is-loading');
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
    const distribution = ERC360.methods.issueDividend(bank,token,amount);

    const parameters = {
      from: accounts[0]
    };

    var tx;
    const distributionTransaction = await distribution.send(parameters, (err, transactionHash) => {
      tx = transactionHash;
    console.log(err);
    console.log('Transaction Hash :', transactionHash);
}).on('confirmation', () => {return true}).catch(()=>{

   })


    console.log('Dividend Distribution completed:', transferTransaction);
    return tx;
  } catch (error) {
    console.error('Error Approving Dividend Distribution:', error);
  }
  $("#distribute").prop('disabled', false).removeClass('is-loading');
}

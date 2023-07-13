$(document).on("click", "#create-idea", async function() {
    $(this).prop('disabled', true);$(this).addClass('is-loading');
    await executeStep1();
});

async function executeStep1() {

   //var skills = $(".skill-title").map(function() { return $(this).text();}).get();
   var formData = new FormData();
   formData.append('step', "step-1");

   formData.append("handle", $("#handle-field").val());

   formData.append("name", $("#name-field").val());

   formData.append("description", $("#description-field").val());

   formData.append("show-location", $("#show-location").is(':checked') ? 1 : 0);
   if ($("#show-location").is(':checked')) {
   
   if (window.markerIsPlaced()) {
   formData.append("lat", window.getLatLng().lat);
   formData.append("lng", window.getLatLng().lng);
   }

  }

   //formData.append("skills", JSON.stringify(skills));

   if (!$("#location-field").hasClass('errorClass') && ! $("#map").hasClass('errorClass')) {

    $.post({
      type: "POST",
      url: "/create/idea/",
      data: formData,
      processData: false,
      contentType: false,
      async success(response) {
        var response = JSON.parse(response);
        var status = response["status"];
        var handle = response["handle"];
        if (status === "success") { console.log("passed step1"); await executeStep2(formData,response["abi"], response["bytecode"]); }
        else{stopButtonLoading();message(status, response["box_id"], true);}
        
      }});
     }
     else {
       $(".errorClass").effect("shake", {direction: "right", times: 2, distance: 8}, 350);
       document.getElementById("#map").scrollIntoView(false);

     }
}

async function executeStep2(formData, abi, bytecode) {
    var isInstalled = await walletIsInstalled();
    if (!isConnected) {
      flash("MetaMask not installed!");
    }
    var isConnected = await walletIsConnected();
    if (!isConnected) {
      flash("Connecting wallet...");
      await checkIfWalletConnected();
    }
    const tx = await deployNewIdea(abi, bytecode);
    console.log("continuing...");
    formData.set('step', "step-2");
    formData.append('tx', tx);
    formData.append('photo', $("#upload").prop('files')[0]);
    formData.append("visible", $("#visible").is(':checked') ? 1 : 0);
    formData.append("public", $("#public").is(':checked') ? 1 : 0);
    console.log("sending next request...");
    $.post({
      type: "POST",
      url: "/create/idea/",
      data: formData,
      processData: false,
      contentType: false,
      success(response) {
        stopButtonLoading();
        var response = JSON.parse(response);
        var status = response["status"];
        var handle = response["handle"];
        if (status === "success") { location.replace("/€"+handle+"/");}
        else{flash(status);console.log(status);}
        
      }});

}

$(document).on("click", "#edit-associate-image-upload", function() {
  $("#upload").click();
});

async function deployNewIdea(abi, bytecode) {
  // Address of the original Idea contract
  const web3 = getWeb3Provider();

    try {

    console.log("contract code");
    console.log(bytecode);
    const accounts = await web3.eth.getAccounts().catch((e) => console.log(e.message));
    if (!accounts) {
      await checkIfWalletConnected();
    }
    console.log(accounts);
    console.log("get accounts");
    const Contract = new web3.eth.Contract(abi);
    console.log("parse contract");
    console.log(accounts[0]);
    const deploy = Contract.deploy({
      arguments: [1000],
      data: bytecode,
      from: accounts[0]
    });
    console.log("basic deploy");

    const gasEstimate = await deploy.estimateGas() + 450199;
    console.log("gas estimate");
    console.log(gasEstimate);
    const parameters = {
      gas: gasEstimate,
      from: accounts[0]
    };

    var tx;
    const deployedContract = await deploy.send(parameters, (err, transactionHash) => {
      tx = transactionHash;
    console.log(err);
    console.log('Transaction Hash :', transactionHash);
}).on('confirmation', () => {}).then((newContractInstance) => {
    return newContractInstance;
});


    console.log('Contract deployed:', deployedContract.options.address);
    return tx;
  } catch (error) {
    console.error('Error deploying contract:', error);
  }

}
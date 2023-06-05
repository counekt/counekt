$(document).on("click", "#create-idea", function() {
    executeStep1();
});

function executeStep1() {
   $(this).prop('disabled', true);$(this).addClass('is-loading');

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
      success(response) {
        stopButtonLoading();
        var response = JSON.parse(response);
        var status = response["status"];
        var handle = response["handle"];
        if (status === "success") { executeStep2(formData) }
        else{message(status, response["box_id"], true);}
        
      }});
     }
     else {
       $(".errorClass").effect("shake", {direction: "right", times: 2, distance: 8}, 350);
       document.getElementById("#map").scrollIntoView(false);

     }
}

function executeStep2(formData) {
    var isConnected = walletIsConnected();
    if (!isConnected) {
      checkIfWalletConnected();
    }
    const ideaAddress = deployNewIdea();

    formData.set('step', "step-2");
    formData.append('ideaAddress', ideaAddress);
    formData.append('photo', $("#upload").prop('files')[0]);
    formData.append("visible", $("#visible").is(':checked') ? 1 : 0);
    formData.append("public", $("#public").is(':checked') ? 1 : 0);

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
        else{flash(status);}
        
      }});

}

$(document).on("click", "#edit-associate-image-upload", function() {
  $("#upload").click();
});

async function deployNewIdea() {
  const ideaAddress = '0xeaF64BC8bf09BD13829e4d9d7a2173824d71AbdC'; // Address of the original Idea contract

  const retrieveContractData = async () => {
    try {
      const web3 = getWeb3Provider();
      const contractCode = await web3.eth.getCode(ideaAddress);
      const contractAbi = await web3.eth.getContractAbi(ideaAddress);

      // Ensure the existing contract code is not empty
      if (contractCode === '0x') {
        throw new Error('Invalid contract address or contract does not exist');
      }

      // Ensure the existing contract ABI is available
      if (!contractAbi) {
        throw new Error('Contract ABI not found');
      }

      return { contractCode, contractAbi };
    } catch (error) {
      console.error('Error retrieving contract data:', error);
    }
  };

    try {

    const { contractCode, contractAbi } = await retrieveContractData();

    const accounts = await web3.eth.getAccounts();

    const Contract = new web3.eth.Contract(JSON.parse(contractAbi));
    const deploy = Contract.deploy({
      data: contractBytecode
    });

    const gasEstimate = await deploy.estimateGas();
    const deployedContract = await deploy.send({
      from: accounts[0],
      gas: gasEstimate
    });

    console.log('Contract deployed:', deployedContract.options.address);
    return deployedContract.options.address;
  } catch (error) {
    console.error('Error deploying contract:', error);
  }

}
function update_timeline(handle) {
        $.get("/€"+handle+"/get/timeline/", function(timeline, status) {
                console.log(timeline);
                for (var i = timeline.length - 1; i >= 0; i--) {
                        var e = timeline[i];
                        console.log(e);
                        if (e.func == "sP") {
                                $("#timeline-content").append("<p>Permit Set</p>");
                                $("#timeline-content").append("<p>"+e.permitName+"</p>");
                                $("#timeline-content").append("<p>"+e.account+"</p>");
                                $("#timeline-content").append("<p>"+e.newState+"</p>");

                        }
                        else if (e.func == "sB") {
                                $("#timeline-content").append("<p>Base Permit Set</p>");
                                $("#timeline-content").append("<p>"+e.permitName+"</p>");
                                $("#timeline-content").append("<p>"+e.newState+"</p>");
                        }
                        else if (e.func == "sNS") {
                                $("#timeline-content").append("<p>Non Shard Holder State Set</p>");
                                $("#timeline-content").append("<p>"+e.newState+"</p>");
                        }
                        else if (e.func == "iD") {
                                $("#timeline-content").append("<p>Dividend Issued</p>");
                                $("#timeline-content").append("<p>"+e.newState+"</p>");
                                $("#timeline-content").append("<p>"+e.bankName+"</p>");
                                $("#timeline-content").append("<p>"+e.tokenAddress+"</p>");
                                $("#timeline-content").append("<p>"+e.value+"</p>");

                        }
                        else if (e.func == "dD") {
                                $("#timeline-content").append("<p>Dividend Dissolved</p>");
                                $("#timeline-content").append("<p>"+e.dividend+"</p>");
                                $("#timeline-content").append("<p>"+e.dividendValue+"</p>");
                        }
                        else if (e.func == "cD") {
                                $("#timeline-content").append("<p>Dividend Claimed</p>");
                                $("#timeline-content").append("<p>"+e.dividend+"</p>");
                                $("#timeline-content").append("<p>"+e.dividendValue+"</p>");
                        }
                        else if (e.func == "cB" || e.func == "aA" || e.func == "rA") {
                                if (e.func == "cB") {$("#timeline-content").append("<p>Bank Created</p>");}
                                if (e.func == "aA") {$("#timeline-content").append("<p>Bank Admin Added</p>");}
                                if (e.func == "rA") {$("#timeline-content").append("<p>Bank Admin Removed</p>");}
                                $("#timeline-content").append("<p>"+e.bankName+"</p>");
                                $("#timeline-content").append("<p>"+e.bankAdmin+"</p>");
                        }
                        else if (e.func == "dB") {
                                $("#timeline-content").append("<p>Bank Deleted</p>");
                                $("#timeline-content").append("<p>"+e.bankName+"</p>");

                        }
                        else if (e.func == "tT") {
                                $("#timeline-content").append("<p>Token Transferred</p>");
                                $("#timeline-content").append("<p>"+e.bankName+"</p>");
                                $("#timeline-content").append("<p>"+e.tokenAddress+"</p>");
                                $("#timeline-content").append("<p>"+e.value+"</p>");
                                $("#timeline-content").append("<p>"+e.to+"</p>");
                        }
                        else if (e.func == "mT") {
                                $("#timeline-content").append("<p>"+e.fromBankName+"</p>");
                                $("#timeline-content").append("<p>"+e.toBankName+"</p>");
                                $("#timeline-content").append("<p>"+e.tokenAddress+"</p>");
                                $("#timeline-content").append("<p>"+e.value+"</p>");
                        }

                        $("#timeline-content").append("<br>");

                }
        });
}
/*
contract = w3.eth.contract(address=self.address,abi=funcs.get_abi())
events = contract.events.ActionTaken.getLogs(fromBlock=self.block)
return [funcs.decode_action_event(e) for e in events]
*/
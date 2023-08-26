pragma solidity ^0.8.20;

import {ERC360Liquidable} from "ERC360Liquidable.sol";
import {ERC360Votable} from "ERC360Votable.sol";
import {ERC360Managable} from "ERC360Managable.sol";

/// @author Frederik W. L. Christoffersen
abstract contract ERC360Corporatizable is ERC360Managable, ERC360Liquidable, ERC360Votable {

    function issueVote(bytes4[] sigs, bytes[] args, uint256 duration) external onlyPermit(keccak256("ISSUE_VOTE")) {
        _issueVote(sigs,args,duration);
    }

    function issueLiquid(bytes32 bank, address token, uint256 amount) external onlyPermit(bank) onlyPermit(keccak256("ISSUE_LIQUID"))  {
        _registerTransferFromBank(bank,token,amount);
        _issueLiquid(token,amount);
    }

    function implementResolution(uint256 voteId) onlyPermit(keccak256("IMPLEMENT_RESOLUTION")) {
        _implementResolution(voteId);
    }

    function _implementProposal(bytes4 sig, bytes args) internal virtual override {
        if (sig == _mint.selector) {
            _mint(abi.decode(args,(address,uint256)));
        } else if (sig == _issueVote.selector) {
            _issueVote(abi.decode(args,(bytes4[],bytes[],uint256)));
        } else if (sig == _issueLiquid.selector) {
            _issueLiquid(abi.decode(args,(uint256)));
        } else if (sig == _setPermit.selector) {
            _setPermit(abi.decode(args,(bytes32,address,bool)));
        } else if (sig == _setPermitParent.selector) {
            _setPermitParent(abi.decode(args,(bytes32,bytes32)));
        } else if (sig == _callExternal.selector) {
            _callExternal(abi.decode(args,(address,bytes4,bytes,uint256,bytes32)));
        } else if (sig == _setExternalCallPermit.selector) {
            _setExternalCallPermit(abi.decode(args,(address,bytes4,bytes32)));
        } else if (sig == _moveFunds.selector) {
            _moveFunds(abi.decode(args,(bytes32,bytes32,address,uint256)));
        } else if (sig == _transferFundsFromBank.selector) {
            _transferFundsFromBank(abi.decode(args,(bytes32,address,address,uint256)));
        } else {revert ERC360CorporatizableInvalidProposal(sig);}
    }

}
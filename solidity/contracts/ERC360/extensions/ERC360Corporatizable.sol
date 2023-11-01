// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC360Liquidable} from "./ERC360Liquidable.sol";
import {ERC360Votable} from "./ERC360Votable.sol";
import {ERC360Managable} from "./ERC360Managable.sol";


/// @author Frederik W. L. Christoffersen
contract ERC360Corporatizable is ERC360Liquidable,ERC360Votable,ERC360Managable {

    error ERC360CorporatizableInvalidProposal(bytes4);

    constructor(string memory name_, string memory symbol_) ERC360Managable(name_,symbol_) {}

    function issueVote(bytes4[] memory sigs, bytes[] memory args, uint256 duration) external onlyPermit(keccak256("ISSUE_VOTE")) {
        _issueVote(sigs,args,duration);
    }

    function issueDividend(bytes32 bank, address token, uint256 amount) external onlyPermit(bank) onlyPermit(keccak256("ISSUE_DIVIDEND"))  {
        _issueDividend(bank,token,amount);
    }

    function implementResolution(uint256 voteId) onlyPermit(keccak256("IMPLEMENT_RESOLUTION")) external {
        _implementResolution(voteId);
    }

    function _issueDividend(bytes32 bank, address token, uint256 amount) internal  {
        _registerTransferFromBank(bank,token,amount);
        _issueLiquid(token,amount);
    }

    function _implementProposal(bytes4 _sig, bytes memory _args) internal virtual override {
        if (_sig == bytes4(keccak256("_mint(address,uint256)"))) {
            (address account, uint256 amount) = abi.decode(_args,(address,uint256));
            _mint(account,amount);
        } else if (_sig == bytes4(keccak256("_issueVote(bytes4[],bytes4[],uint256)"))) {
            (bytes4[] memory sigs, bytes[] memory args, uint256 duration) = abi.decode(_args,(bytes4[],bytes[],uint256));
            _issueVote(sigs,args,duration);
        } else if (_sig == bytes4(keccak256("_issueDividend(bytes32,address,uint256)"))) {
            (bytes32 bank, address token, uint256 amount) = abi.decode(_args,(bytes32,address,uint256));
            _issueDividend(bank,token,amount);
        } else if (_sig == bytes4(keccak256("_setPermit(address,bytes32,bool)"))) {
            (address account, bytes32 permit, bool status) = abi.decode(_args,(address,bytes32,bool));
            _setPermit(account,permit,status);
        } else if (_sig == bytes4(keccak256("_setPermitParent(bytes32,bytes32)"))) {
            (bytes32 permit, bytes32 parent) = abi.decode(_args,(bytes32,bytes32));
            _setPermitParent(permit,parent);
        } else if (_sig == bytes4(keccak256("_callExternal(address,bytes4,bytes,uint256,bytes32)"))) {
            (address ext, bytes4 sig, bytes memory args, uint256 value, bytes32 bank) = abi.decode(_args,(address,bytes4,bytes,uint256,bytes32));
            _callExternal(ext,sig,args,value,bank);
        } else if (_sig == bytes4(keccak256("_setExternalCallPermit(address,bytes4,bytes32)"))) {
            (address ext, bytes4 sig, bytes32 permit) = abi.decode(_args,(address,bytes4,bytes32));
            _setExternalCallPermit(ext,sig,permit);
        } else if (_sig == bytes4(keccak256("_moveFunds(bytes32,bytes32,address,uint256)"))) {
            (bytes32 fromBank, bytes32 toBank, address token, uint256 amount) = abi.decode(_args,(bytes32,bytes32,address,uint256));
            _moveFunds(fromBank,toBank,token,amount);
        } else if (_sig == bytes4(keccak256("_transferFundsFromBank(bytes32,address,address,uint256)"))) {
            (bytes32 bank,address to, address token, uint256 amount) = abi.decode(_args,(bytes32,address,address,uint256));
            _transferFundsFromBank(bank,to,token,amount);
        } else {revert ERC360CorporatizableInvalidProposal(_sig);}
    }

}
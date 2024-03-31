pragma solidity ^0.8.20;

import {ERC360Redeemable} from "./ERC360Redeemable.sol";
import {ERC20Holder} from "../utils/ERC20Holder.sol";


abstract contract ERC360Liquidable is ERC20Holder, ERC360Redeemable {

    mapping(uint256 => address) private _tokenByLiquid;
    mapping(uint256 => uint256) private _amountByLiquid;

    event LiquidIssued(uint256 liquidId);
    event LiquidClaimed(address claimant, uint256 tokenId, uint256 liquidId);

    function claimLiquid(uint256 tokenId, uint256 liquidId) external {
        _requireUnredeemed(tokenId,liquidId);
        _requireValidAt(tokenId,clockOf(liquidId));
        _redeemEvent(tokenId,liquidId);
        _transferFunds(_msgSender(),_tokenByLiquid[liquidId],_amountByLiquid[liquidId]*totalSupplyAt(clockOf(liquidId))/amountOf(tokenId));
        emit LiquidClaimed(_msgSender(),tokenId,liquidId);
    }

    function _issueLiquid(address token, uint256 amount) internal {
        uint256 liquidId = _createEvent();
        _tokenByLiquid[liquidId] = token;
        _amountByLiquid[liquidId] = amount;
        emit LiquidIssued(liquidId);
    }

}
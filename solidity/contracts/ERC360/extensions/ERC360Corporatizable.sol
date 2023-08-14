pragma solidity ^0.8.20;

import {ERC360} from "../ERC360.sol";
import {Administrable} from "../utils/Administrable.sol";
import {Liquidable} from "../utils/Liquidable.sol";
import {Votable} from "../utils/Votable.sol";


/// @author Frederik W. L. Christoffersen
abstract contract ERC360Corporatizable is ERC360, Liquidable, Votable {
    
    constructor(uint256 amount, string memory name_, string memory symbol_) ERC360(name_,symbol_) {
        _mint(_msgSender(),amount); // mint the initial supply to creator
        _setPermit(_msgSender(),bytes32(0),true); // grant the master permit to creator
    }


}
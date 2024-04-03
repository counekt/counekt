pragma solidity ^0.8.20;
import {ERC20} from "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Required interface of an ERC360Broker compliant contract.
 */
interface IERC360Broker {

	/// @notice An enum representing a sale status
    /// @param notForSale The token is NOT FOR SALE.
    /// @param forSale The token is FOR SALE.
    /// @param sold The token has been SOLD.
    enum Status {
        notForSale,
        forSale,
        sold
    }

	/// @notice A struct representing sale details.
    /// @param notForSale The token is NOT FOR SALE.
    /// @param forSale The token is FOR SALE.
    /// @param sold The token has been SOLD.
    struct Sale {
        ERC20 paymentToken; // in exchange for
        uint256 amount; // amount for sale
        uint256 price; // per token
    }

} 
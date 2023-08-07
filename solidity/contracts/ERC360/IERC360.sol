// SPDX-License-Identifier: MIT

/**
 * @dev Required interface of an ERC360 compliant contract.
 */
interface IERC360 {

    /**
     * @dev Emitted when an `amount` of tokens are moved `from` one account `to`
     * another.
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Emitted when the current balance of an `owner` is tied to
     * a new `tokenId`.
     */
    event NewTokenId(address owner, uint256 tokenId);

    /**
     * @dev Moves an `amount` of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

   	/**
     * @dev Moves an `amount` of tokens `from` one account `to` another using the
     * allowance mechanism. The `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev Sets an `amount` of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining amount of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This amount changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the amount of valid tokens in existence.
     */
    function totalSupply() external view returns (uint256);


    /**
     * @dev Returns the amount of tokens ever created.
     */
    function currentClock() external view returns (uint256);


    /**
     * @dev Returns the amount of tokens currently owned by ``account``.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @dev Returns the amount tied to the ``tokenId``.
     */
    function amountOf(uint256 tokenId) external view returns (uint256 amount);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns true if the `tokenId` is currently valid.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isValid(uint256 tokenId) public view returns(bool);


    /**
     * @dev Returns true if the `tokenId` was valid at 'clock'.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function wasValid(uint256 tokenId, uint256 clock) public view returns(bool);



    /**
     * @dev Returns the clock at which a ``tokenId`` expired.
     * 
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function expirationOf(uint256 tokenId) external view returns (uint256 expiration);
}
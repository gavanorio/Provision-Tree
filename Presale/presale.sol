// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private  _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract BuyTicket is Context, Ownable{

    IERC20 tokenContract = IERC20(0x81859BBa11Fc4c1B737f10bcf1cE9eD6116FD4a8); 

    address payable public devWallet = payable(0xB6Dc1316C975C52C4165D23656538a8b57da59f7); //team taxes
    address payable public marketingWallet = payable(0x0950A4c3a404a1cdB0af23994096D24CDb222a9A); //marketing
    address payable public socialFundingWallet = payable(0x840f388Cc87081bc28A1442C54Ba4Be0B3A7d524); //donation
    address payable public initialOwnerWallet = payable(0xFaC7B3ad3661a2Bc9fd30e4854D062dC43623A5c); //initialOwner

    uint public taxFee = 3; //3%
    uint public marketingFee = 3; //3%
    uint public socialFunding = 5; //5%
    
    bool public automaticBNB = true;


    //ETHER is the Solidity denomination for the unit base currency of the blockchain
    //this would transalte to BNB on the Binance Chain
    uint tokenPrice = 12000 gwei; //Review
    
    function noOfTokensAvailable() public view returns(uint) {
        return tokenContract.balanceOf(address(this));
    }

    function balance() public view returns(uint){
        return address(this).balance;
    }

    function buyTokens(uint numberOfTokens) external payable {
        uint _amount = tokenPrice*numberOfTokens;
        require (msg.value == _amount, "msg value is not correct");
        numberOfTokens  = numberOfTokens*10**18;

        require (numberOfTokens <= noOfTokensAvailable(), "not enough tokens to buy");
        require (numberOfTokens <= 2500000*10**18, "Maximum quantity allowed is 2,500,000PTREE");
        address callerWallet = msg.sender;
        tokenContract.transfer(callerWallet,numberOfTokens);
        
        if(automaticBNB){
            deliverBNB();
        }
    }

    function recoverTokens () external onlyOwner() {
        address callerWallet = msg.sender;
        tokenContract.transfer(callerWallet,noOfTokensAvailable());
    }

    function splitEther () external onlyOwner() {
        payable(owner()).transfer(balance());
    }

    function deliverBNB () internal{
        uint256 contractBNBBalance = address(this).balance;
        devWallet.transfer(contractBNBBalance*taxFee/100);
        marketingWallet.transfer(contractBNBBalance*marketingFee/100);
        socialFundingWallet.transfer(contractBNBBalance*socialFunding/100);

        contractBNBBalance = address(this).balance;
        initialOwnerWallet.transfer(contractBNBBalance);
    }

    function automaticBNBOn(bool _truefalse) external onlyOwner() {
        automaticBNB = _truefalse;
    }

    function destroy() external onlyOwner() {
        selfdestruct(payable(owner()));
    }
    

}

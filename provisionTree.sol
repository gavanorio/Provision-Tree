// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
INHERITANCE CLASSES
*/


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Ownable is Context {
    address private _owner;
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

    function renounceOwnership() public virtual onlyOwner {
        transferOwnership(address(0));
    }

}

/*
PANCAKESWAP & UNISWAP CLASSES
*/

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Token is Context, Ownable {
    using Address for address;

    mapping(address => uint) public balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _blacklistedAccount;
    address[] private _excluded;

/*
TOKEN INFO
*/

    uint public _decimals = 18;
    string public _name = "Provision Tree";
    string public _symbol = "PTREE";
    uint public _totalSupply = 50000000 * 10 ** 18;

    uint public _maxTxAmount = _totalSupply/20; //5% of total supply maximum tx amount
    uint public _maxWalletAmount = _totalSupply/20; //5c% of total supply maximum wallet amount

    address payable public taxAddress = payable(); //team taxes
    address payable public marketingAddress = payable(); //marketing
    address payable public socialFundingAddress = payable(); //donation
    address payable public initialOwnerAddress = payable(); //initialOwner
    address public contractAddress = address(this);
    

    uint public taxFee = 3; //3%
    uint public marketingFee = 3; //3%
    uint public socialFunding = 5; //5%

    uint public previousTaxFee=taxFee;
    uint public previousMarketingFee = marketingFee;
    uint public previousSocialFunding = socialFunding;

    //HOTEL CALIFORNIA
    //Used to capture Sniper Bots
    uint256 public maxRoomRent = 50000000000;
    bool public hotelCaliforniaMode = false;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool public swapAndLiquifyEnabled = false;
    receive() external payable {} 

    constructor() {

        balances[taxAddress] = _totalSupply*3/100; //team wallet
        balances[marketingAddress] = _totalSupply*3/100; //marketing wallet
        balances[initialOwnerAddress] = _totalSupply*94/100; //initialOwner wallet

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[taxAddress] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[socialFundingAddress] = true;
        _isExcludedFromFee[contractAddress] = true;

        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[taxAddress] = true;
        _isExcludedFromLimits[marketingAddress] = true;
        _isExcludedFromLimits[socialFundingAddress] = true;
        _isExcludedFromLimits[contractAddress] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        //0x10ED43C718714eb63d5aA57B78B54704E256024E mainnet
        //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 testnet
        
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromLimits[uniswapV2Pair] = true;


        emit Transfer(address(0), msg.sender, _totalSupply);
    }


/*
GENERAL FUNCTIONS
*/



    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address value) public view returns(uint256) {
        return balances[value];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, 0);
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function totalFees() public view returns (uint256) {
        return taxFee+marketingFee+socialFunding;
    }

/*
SWAPPING FUNCTIONS
*/

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function recoverAllTokens() external onlyOwner {
        balances[owner()]+=(balanceOf(contractAddress));
        balances[contractAddress]-=(balanceOf(contractAddress));
    }

    function recoverAllBNB() external onlyOwner {
       owner().transfer(balance());
    }


//HOTEL CALIFORNIA
    //
    function activateHotelCalifornia(bool activated) external onlyOwner {
        hotelCaliforniaMode = activated;
    }

    function setRoomRent(uint256 maxTxRoomRent) external onlyOwner {
        maxRoomRent = maxTxRoomRent;
    }



/*
TRANSFER FUNCTIONS
*/


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()]-amount <= amount, "transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]-amount);
        return true;
    }


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, 'balance too low');
        require(_blacklistedAccount[from] != true, "Account is blacklisted");

        // Hotel California
        //Used to capture Sniper Bots. Must be deactivated after the first few minutes after the token launch
        if(hotelCaliforniaMode){
            _blacklistedAccount[msg.sender] = true;
        }


        if(_isExcludedFromLimits[from] == false) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(_isExcludedFromLimits[to] == false) {
            require(balanceOf(to) + amount <=  _maxWalletAmount, 'Transfer amount exceeds the maxWalletAmount.');
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        uint256 taxAmount;
        uint256 marketingAmount;
        uint256 socialFundingAmount;

        if(!takeFee) {

            taxAmount = 0;
            marketingAmount = 0;
            socialFundingAmount = 0;

            balances[sender]-=(amount);
            balances[recipient]+=(amount);

            emit Transfer(sender, recipient, amount);

        }

        else {

            taxAmount = calculateTaxFee(amount);
            marketingAmount = calculateMarketingFee(amount);
            socialFundingAmount = calculateSocialFundingFee(amount);


            balances[sender]-=(amount);

            balances[contractAddress]+=(taxAmount);
            balances[contractAddress]+=(marketingAmount);
            balances[contractAddress]+=(socialFundingAmount);

            balances[recipient]+=(amount-taxAmount-socialFundingAmount-marketingAmount);

            if(swapAndLiquifyEnabled){
                sendFees();
            }

            emit Transfer(sender, recipient, amount);

        }   
    }
    


/*
CALCULATE FEES 
*/

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount*(taxFee)/(100);
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256){
        return _amount*(marketingFee)/(100);
    }

    function calculateSocialFundingFee(uint256 _amount) private view returns (uint256){
        return _amount*(socialFunding)/(100);
    }

/*
SEND FEES
*/

    function sendFees() private {
        uint256 contractBalance = balanceOf(contractAddress);
        swapTokensForEth(contractBalance);

        uint256 contractBNBBalance = address(this).balance;
        
        marketingAddress.transfer(contractBNBBalance*marketingFee/100);
        socialFundingAddress.transfer(contractBNBBalance*socialFunding/100);
        taxAddress.transfer(contractBNBBalance);


    }

    function sendFeesOwnable() public onlyOwner {
        sendFees();
    }


/*
INCLUDE AND EXCLUDE FROM FEES FUNCTIONS
*/

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromLimits(address account) public onlyOwner {
        _isExcludedFromLimits[account] = true;
    }
    
    function includeInLimits(address account) public onlyOwner {
        _isExcludedFromLimits[account] = false;
    }

    function isExcludedFromLimits(address account) public view returns(bool) {
        return _isExcludedFromLimits[account];
    } 

    function blacklistWallet(address wallet) external onlyOwner() {
        _blacklistedAccount[wallet] = true;
    }

    function removeFromBlacklistWallet(address wallet) external onlyOwner() {
        _blacklistedAccount[wallet] = false;
    }

    function isBlacklisted(address wallet) public view returns(bool){
        return _blacklistedAccount[wallet];
    }


/*
ONLYOWNER EDIT CONTRACT FUNCTIONS
*/

    function setTaxAddress(address _taxAddress) external onlyOwner() {
        taxAddress = payable(_taxAddress);
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        marketingAddress = payable(_marketingAddress);
    }

    function setSocialFundingAddress(address _socialFundingAddress) external onlyOwner() {
        socialFundingAddress = payable(_socialFundingAddress);
    }


    function setTaxFeePercent(uint256 _taxFee) external onlyOwner() {
        taxFee = _taxFee;     
    }

    function setSocialFundingPercent(uint256 _socialFee) external onlyOwner() {  
        socialFunding = _socialFee;     
    }

    function setMarketingFeePercent(uint256 _marketingFee) external onlyOwner() {  
        marketingFee = _marketingFee;     
    }

    function setMaxTransaction(uint256 _maxTransaction) external onlyOwner(){
        _maxTxAmount = _maxTransaction;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner(){
        _maxWalletAmount = _maxWallet;
    }

    function deactivateAllFees() external onlyOwner() {  
        
        previousTaxFee = taxFee;
        previousMarketingFee = marketingFee;
        previousSocialFunding = socialFunding;

        taxFee = 0; 
        marketingFee = 0;
        socialFunding = 0;     
    }

    function activateAllFees() external onlyOwner() {  
        taxFee = previousTaxFee;
        marketingFee = previousMarketingFee;
        socialFunding = previousSocialFunding;     
    }

    function manualBurn(uint256 _amount) external onlyOwner() {
        balances[msg.sender] -=_amount;
        _totalSupply -=_amount;
    }


}

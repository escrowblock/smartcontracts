pragma solidity ^0.4.19;

import "zeppelin/contracts/math/SafeMath.sol";
import "./interface/TokenController.sol";
import "./ESCBCoin.sol";
import "./ESCBCoinPlaceholder.sol";
import "./SaleWallet.sol";

/**
 * Copyright 2018, Konstantin Viktorov (EscrowBlock Foundation)
 * Copyright 2017, Jorge Izquierdo (Aragon Foundation)
 * Copyright 2017, Jordi Baylina (Giveth)
 *
 * Based on SampleCampaign-TokenController.sol from https://github.com/Giveth/minime
 * This is the new token sale smart contract for conduction IITO and Airdrop together,
 * also it will allow having a stable price for some period after exchange listing.
 **/

contract ESCBTokenSale is TokenController {
  uint256 public initialTime;           // Time in which the sale starts. Inclusive. sale will be opened at initial time.
  uint256 public controlTime;           // The Unix time in which the sale needs to check on the refunding start.
  uint256 public price;                 // Number of wei-ESCBCoin tokens for 1 ether
  address public ESCBDevMultisig;       // The address to hold the funds donated

  uint256 public affiliateBonusPercent = 2;     // Purpose in percentage of payment via referral
  uint256 public totalCollected = 0;            // In wei
  bool public saleStopped = false;              // Has ESCB Dev stopped the sale?
  bool public saleFinalized = false;            // Has ESCB Dev finalized the sale?

  mapping (address => bool) public activated;   // Address confirmates that wants to activate the sale

  ESCBCoin public token;                         // The token
  ESCBCoinPlaceholder public networkPlaceholder; // The network placeholder
  SaleWallet public saleWallet;                  // Wallet that receives all sale funds

  uint256 constant public dust = 1 finney; // Minimum investment
  uint256 public minGoal;                  // amount of minimum fund in wei
  uint256 public goal;                     // Goal for IITO in wei
  uint256 public currentStage = 1;         // Current stage
  uint256 public allocatedStage = 1;       // Current stage when was allocated tokens for ESCB
  uint256 public usedTotalSupply = 0;      // This uses for calculation ESCB allocation part

  event ActivatedSale();
  event FinalizedSale();
  event NewBuyer(address indexed holder, uint256 ESCBCoinAmount, uint256 etherAmount);
  event NewExternalFoundation(address indexed holder, uint256 ESCBCoinAmount, uint256 etherAmount, bytes32 externalId);
  event AllocationForESCBFund(address indexed holder, uint256 ESCBCoinAmount);
  event NewStage(uint64 numberStage);
  // @dev There are several checks to make sure the parameters are acceptable
  // @param _initialTime The Unix time in which the sale starts
  // @param _controlTime The Unix time in which the sale needs to check on the refunding start
  // @param _ESCBDevMultisig The address that will store the donated funds and manager for the sale
  // @param _price The price. Price in wei-ESCBCoin per wei
  function ESCBTokenSale (uint _initialTime, uint _controlTime, address _ESCBDevMultisig, uint256 _price)
           non_zero_address(_ESCBDevMultisig) {
    assert (_initialTime >= getNow());
    assert (_initialTime < _controlTime);

    // Save constructor arguments as global variables
    initialTime = _initialTime;
    controlTime = _controlTime;
    ESCBDevMultisig = _ESCBDevMultisig;
    price = _price;
  }

  modifier only(address x) {
    require(msg.sender == x);
    _;
  }

  modifier only_before_sale {
    require(getNow() < initialTime);
    _;
  }

  modifier only_during_sale_period {
    require(getNow() >= initialTime);

    // if minimum goal is reached, then infinite time to reach the main goal
    require(getNow() < controlTime || minGoalReached());
    _;
  }

  modifier only_after_sale {
    require(getNow() >= controlTime || goalReached());
    _;
  }

  modifier only_sale_stopped {
    require(saleStopped);
    _;
  }

  modifier only_sale_not_stopped {
    require(!saleStopped);
    _;
  }

  modifier only_before_sale_activation {
    require(!isActivated());
    _;
  }

  modifier only_sale_activated {
    require(isActivated());
    _;
  }

  modifier only_finalized_sale {
    require(getNow() >= controlTime || goalReached());
    require(saleFinalized);
    _;
  }

  modifier non_zero_address(address x) {
    require(x != 0);
    _;
  }

  modifier minimum_value(uint256 x) {
    require(msg.value >= x);
    _;
  }

  // @notice Deploy ESCBCoin is called only once to setup all the needed contracts.
  // @param _token: Address of an instance of the ESCBCoin token
  // @param _networkPlaceholder: Address of an instance of ESCBCoinPlaceholder
  // @param _saleWallet: Address of the wallet receiving the funds of the sale
  // @param _minGoal: Minimum fund for success
  // @param _goal: The end fund amount
  function setESCBCoin(address _token, address _networkPlaceholder, address _saleWallet, uint256 _minGoal, uint256 _goal)
           payable
           non_zero_address(_token)
           only(ESCBDevMultisig)
           public {

    // 3 times by non_zero_address is not working for current compiler version
    require(_networkPlaceholder != 0);
    require(_saleWallet != 0);

    // Assert that the function hasn't been called before, as activate will happen at the end
    assert(!activated[this]);

    token = ESCBCoin(_token);
    networkPlaceholder = ESCBCoinPlaceholder(_networkPlaceholder);
    saleWallet = SaleWallet(_saleWallet);

    assert(token.controller() == address(this));             // sale is controller
    assert(token.totalSupply() == 0);                        // token is empty

    assert(networkPlaceholder.tokenSale() == address(this)); // placeholder has reference to Sale
    assert(networkPlaceholder.token() == address(token));    // placeholder has reference to ESCBCoin

    assert(saleWallet.multisig() == ESCBDevMultisig);        // receiving wallet must match
    assert(saleWallet.tokenSale() == address(this));         // watched token sale must be self

    assert(_minGoal > 0);                                   // minimum goal is not empty
    assert(_goal > 0);                                      // the main goal is not empty
    assert(_minGoal < _goal);                               // minimum goal is less than the main goal

    minGoal = _minGoal;
    goal = _goal;

    // Contract activates sale as all requirements are ready
    doActivateSale(this);
  }

  function activateSale()
           public {
    doActivateSale(msg.sender);
    ActivatedSale();
  }

  function doActivateSale(address _entity)
    non_zero_address(token) // cannot activate before setting token
    only_before_sale
    private {
    activated[_entity] = true;
  }

  // @notice Whether the needed accounts have activated the sale.
  // @return Is sale activated
  function isActivated()
           constant
           public
           returns (bool) {
    return activated[this] && activated[ESCBDevMultisig];
  }

  // @notice Get the price for tokens for the current stage
  // @param _amount the amount for which the price is requested
  // @return Number of wei-ESCBToken
  function getPrice(uint256 _amount)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           constant
           public
           returns (uint256) {
    return priceForStage(SafeMath.mul(_amount, price));
  }

  // @notice Get the bonus tokens for a stage
  // @param _amount the amount of tokens
  // @return Number of wei-ESCBCoin with bonus for 1 wei
  function priceForStage(uint256 _amount)
           internal
           returns (uint256) {

    if (totalCollected >= 0 && totalCollected <= 80 ether) { // 1 ETH = 500 USD, then 40 000 USD 1 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 20), 100));
    }

    if (totalCollected > 80 ether && totalCollected <= 200 ether) { // 1 ETH = 500 USD, then 100 000 USD 2 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 18), 100));
    }

    if (totalCollected > 200 ether && totalCollected <= 400 ether) { // 1 ETH = 500 USD, then 200 000 USD 3 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 16), 100));
    }

    if (totalCollected > 400 ether && totalCollected <= 1000 ether) { // 1 ETH = 500 USD, then 500 000 USD 4 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 14), 100));
    }

    if (totalCollected > 1000 ether && totalCollected <= 2000 ether) { // 1 ETH = 500 USD, then 1 000 000 USD 5 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 12), 100));
    }

    if (totalCollected > 2000 ether && totalCollected <= 4000 ether) { // 1 ETH = 500 USD, then 2 000 000 USD 6 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 10), 100));
    }

    if (totalCollected > 4000 ether && totalCollected <= 8000 ether) { // 1 ETH = 500 USD, then 4 000 000 USD 7 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 8), 100));
    }

    if (totalCollected > 8000 ether && totalCollected <= 12000 ether) { // 1 ETH = 500 USD, then 6 000 000 USD 8 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 6), 100));
    }

    if (totalCollected > 12000 ether && totalCollected <= 16000 ether) { // 1 ETH = 500 USD, then 8 000 000 USD 9 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 4), 100));
    }

    if (totalCollected > 16000 ether && totalCollected <= 20000 ether) { // 1 ETH = 500 USD, then 10 000 000 USD 10 stage
      return SafeMath.add(_amount, SafeMath.div(SafeMath.mul(_amount, 2), 100));
    }

    if (totalCollected > 20000 ether) { // without bonus
      return _amount;
    }
  }

  // ESCBDevMultisig can use this function for allocation tokens
  // for ESCB Foundation by each stage, start from 2nd
  // Amount of stages can not be more than MAX_GRANTS_PER_ADDRESS
  function allocationForESCBbyStage()
           only(ESCBDevMultisig)
           public {
     if (totalCollected >= 0 && totalCollected <= 80 ether) { // 1 ETH = 500 USD, then 40 000 USD 1 stage
       currentStage = 1;
     }

     if (totalCollected > 80 ether && totalCollected <= 200 ether) { // 1 ETH = 500 USD, then 100 000 USD 2 stage
       currentStage = 2;
     }

     if (totalCollected > 200 ether && totalCollected <= 400 ether) { // 1 ETH = 500 USD, then 200 000 USD 3 stage
       currentStage = 3;
     }

     if (totalCollected > 400 ether && totalCollected <= 1000 ether) { // 1 ETH = 500 USD, then 500 000 USD 4 stage
       currentStage = 4;
     }

     if (totalCollected > 1000 ether && totalCollected <= 2000 ether) { // 1 ETH = 500 USD, then 1 000 000 USD 5 stage
       currentStage = 5;
     }

     if (totalCollected > 2000 ether && totalCollected <= 4000 ether) { // 1 ETH = 500 USD, then 2 000 000 USD 6 stage
       currentStage = 6;
     }

     if (totalCollected > 4000 ether && totalCollected <= 8000 ether) { // 1 ETH = 500 USD, then 4 000 000 USD 7 stage
       currentStage = 7;
     }

     if (totalCollected > 8000 ether && totalCollected <= 12000 ether) { // 1 ETH = 500 USD, then 6 000 000 USD 8 stage
       currentStage = 8;
     }

     if (totalCollected > 12000 ether && totalCollected <= 16000 ether) { // 1 ETH = 500 USD, then 8 000 000 USD 9 stage
       currentStage = 9;
     }

     if (totalCollected > 16000 ether && totalCollected <= 20000 ether) { // 1 ETH = 500 USD, then 10 000 000 USD 10 stage
       currentStage = 10;
     }
    if(currentStage > allocatedStage) {
      // ESCB Foundation owns 30% of the total number of emitted tokens.
      // totalSupply here 66%, then we 30%/66% to get amount 30% of tokens
      uint256 ESCBTokens = SafeMath.div(SafeMath.mul(SafeMath.sub(uint256(token.totalSupply()), usedTotalSupply), 15), 33);
      uint256 prevTotalSupply = uint256(token.totalSupply());
      if(token.generateTokens(address(this), ESCBTokens)) {
        allocatedStage = currentStage;
        usedTotalSupply = prevTotalSupply;
        uint64 cliffDate = uint64(SafeMath.add(uint256(now), 365 days));
        uint64 vestingDate = uint64(SafeMath.add(uint256(now), 547 days));
        token.grantVestedTokens(ESCBDevMultisig, ESCBTokens, uint64(now), cliffDate, vestingDate, true, false);
        AllocationForESCBFund(ESCBDevMultisig, ESCBTokens);
      } else {
        revert();
      }
    }
  }

  // @notice Notifies the controller about a transfer, for this sale all
  //  transfers are allowed by default and no extra notifications are needed
  // @param _from The origin of the transfer
  // @param _to The destination of the transfer
  // @param _amount The amount of the transfer
  // @return False if the controller does not authorize the transfer
  function onTransfer(address _from, address _to, uint _amount)
           public
           returns (bool) {
    return true;
  }

  // @notice Notifies the controller about an approval, for this sale all
  //  approvals are allowed by default and no extra notifications are needed
  // @param _owner The address that calls `approve()`
  // @param _spender The spender in the `approve()` call
  // @param _amount The amount in the `approve()` call
  // @return False if the controller does not authorize the approval
  function onApprove(address _owner, address _spender, uint _amount)
           public
           returns (bool) {
    return true;
  }

  // @dev The fallback function is called when ether is sent to the contract, it
  // simply calls `doPayment()` with the address that sent the ether as the
  // `_owner`. Payable is a require solidity modifier for functions to receive
  // ether, without this modifier functions will throw if ether is sent to them
  function ()
           public
           payable {
    doPayment(msg.sender);
  }

// @dev This function allow to get bonus tokens for a buyer and for referral
  function paymentAffiliate(address _referral)
           non_zero_address(_referral)
           payable
           public {
    uint256 boughtTokens = doPayment(msg.sender);
    uint256 affiliateBonus = SafeMath.div(
                               SafeMath.mul(boughtTokens, affiliateBonusPercent), 100
                             ); // Calculate how many bonus tokens need to add
    assert(token.generateTokens(_referral, affiliateBonus));
    assert(token.generateTokens(msg.sender, affiliateBonus));
  }

////////////
// Controller interface
////////////

  // @notice `proxyPayment()` allows the caller to send ether to the Token directly and
  // have the tokens created in an address of their choosing
  // @param _owner The address that will hold the newly created tokens

  function proxyPayment(address _owner)
           payable
           public
           returns (bool) {
    doPayment(_owner);
    return true;
  }

  // @dev `doPayment()` is an internal function that sends the ether that this
  //  contract receives to the ESCBDevMultisig and creates tokens in the address of the sender
  // @param _owner The address that will hold the newly created tokens
  function doPayment(address _owner)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           non_zero_address(_owner)
           minimum_value(dust)
           internal
           returns (uint256) {
    assert(totalCollected + msg.value <= goal); // If goal is reached, throw
    uint256 boughtTokens = priceForStage(SafeMath.mul(msg.value, price)); // Calculate how many tokens bought
    saleWallet.transfer(msg.value); // Send funds to multisig
    saleWallet.deposit(_owner, msg.value); // Send info about deposit to multisig
    assert(token.generateTokens(_owner, boughtTokens)); // Allocate tokens.
    totalCollected = SafeMath.add(totalCollected, msg.value); // Save total collected amount
    NewBuyer(_owner, boughtTokens, msg.value);

    return boughtTokens;
  }

  // @notice Function for issuing new tokens for address which made purchasing not in
  // ETH currency, for example via cards or wire transfer.
  // @dev Only ESCB Dev can do it with the publishing of transaction id in an external system.
  // Any audits will be able to confirm eligibility of issuing in such case.
  // @param _owner The address that will hold the newly created tokens
  // @param _amount Amount of purchasing in ETH
  function issueWithExternalFoundation(address _owner, uint256 _amount, bytes32 _extId)
           only_during_sale_period
           only_sale_not_stopped
           only_sale_activated
           non_zero_address(_owner)
           only(ESCBDevMultisig)
           public
           returns (uint256) {
    assert(totalCollected + _amount <= goal); // If goal is reached, throw
    uint256 boughtTokens = priceForStage(SafeMath.mul(_amount, price)); // Calculate how many tokens bought

    assert(token.generateTokens(_owner, boughtTokens)); // Allocate tokens.
    totalCollected = SafeMath.add(totalCollected, _amount); // Save total collected amount

    // Events
    NewBuyer(_owner, boughtTokens, _amount);
    NewExternalFoundation(_owner, boughtTokens, _amount, _extId);

    return boughtTokens;
  }

  // @notice Function to stop sale for an emergency.
  // @dev Only ESCB Dev can do it after it has been activated.
  function emergencyStopSale()
           only_sale_activated
           only_sale_not_stopped
           only(ESCBDevMultisig)
           public {
    saleStopped = true;
  }

  // @notice Function to restart stopped sale.
  // @dev Only ESCB Dev can do it after it has been disabled and sale is ongoing.
  function restartSale()
           only_during_sale_period
           only_sale_stopped
           only(ESCBDevMultisig)
           public {
    saleStopped = false;
  }

  // @notice Finalizes sale when main goal is reached or if for control time the minimum goal was not reached.
  // @dev Transfers the token controller power to the ESCBCoinPlaceholder.
  function finalizeSale()
           only_after_sale
           only(ESCBDevMultisig)
           public {
    token.changeController(networkPlaceholder); // Sale loses token controller power in favor of network placeholder
    saleFinalized = true;  // Set finalized flag as true, that will allow enabling network deployment
    saleStopped = true;
    FinalizedSale();
  }

  // @notice Deploy ESCB Network contract.
  // @param _networkAddress: The address the network was deployed at.
  function deployNetwork(address _networkAddress)
           only_finalized_sale
           non_zero_address(_networkAddress)
           only(ESCBDevMultisig)
           public {
    networkPlaceholder.changeController(_networkAddress);
  }

  // @notice Set up new ESCB Dev.
  // @param _newMultisig: The address new ESCB Dev.
  function setESCBDevMultisig(address _newMultisig)
           non_zero_address(_newMultisig)
           only(ESCBDevMultisig)
           public {
    ESCBDevMultisig = _newMultisig;
  }

  // @notice Get current unix time stamp
  function getNow()
           constant
           internal
           returns (uint) {
    return now;
  }

  // @notice If crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund()
           only_finalized_sale
           public {
    require(!minGoalReached());
    saleWallet.refund(msg.sender);
  }

  // @notice Check minimum goal for 1st stage
  function minGoalReached()
           public
           view
           returns (bool) {
    return totalCollected >= minGoal;
  }

  // @notice Check the main goal for 10th stage
  function goalReached()
           public
           view
           returns (bool) {
    return totalCollected >= goal;
  }
}

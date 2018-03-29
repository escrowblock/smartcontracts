pragma solidity ^0.4.19;

import "zeppelin/contracts/math/SafeMath.sol";

// @dev Contract to hold sale raised funds during the sale period.
// Prevents attack in which the ESCB Multisig sends raised ether
// to the sale contract to mint tokens to itself, and getting the
// funds back immediately.

contract AbstractSale {
    function saleFinalized() public returns (bool);
    function minGoalReached() public returns (bool);
}

contract SaleWallet {
    using SafeMath for uint256;

    enum State { Active, Refunding }
    State public currentState;

    mapping (address => uint256) public deposited;

    //Events
    event Withdrawal();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Deposit(address beneficiary, uint256 weiAmount);

    // Public variables
    address public multisig;
    AbstractSale public tokenSale;

    // @dev Constructor initializes public variables
    // @param _multisig The address of the multisig that will receive the funds
    // @param _tokenSale The address of the token sale
    function SaleWallet(address _multisig, address _tokenSale) {
        currentState = State.Active;
        multisig = _multisig;
        tokenSale = AbstractSale(_tokenSale);
    }

    // @dev Receive all sent funds and build the refund map
    function deposit(address investor, uint256 amount) public {
        require(currentState == State.Active);
        require(msg.sender == address(tokenSale));
        deposited[investor] = deposited[investor].add(amount);
        Deposit(investor, amount);
    }

    // @dev Withdraw function sends all the funds to the wallet if conditions are correct
    function withdraw() public {
        require(currentState == State.Active);
        assert(msg.sender == multisig);    // Only the multisig can request it
        if (tokenSale.minGoalReached()) {     // Allow when sale reached minimum goal
            return doWithdraw();
        }
    }

    function doWithdraw() internal {
        assert(multisig.send(this.balance));
        Withdrawal();
    }

    function enableRefunds() public {
        require(currentState == State.Active);
        assert(msg.sender == multisig);         // Only the multisig can request it
        require(!tokenSale.minGoalReached());    // Allow when minimum goal isn't reached
        require(tokenSale.saleFinalized()); // Allow when sale is finalized
        currentState = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public {
        require(currentState == State.Refunding);
        require(msg.sender == address(tokenSale));
        require(deposited[investor] != 0);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        assert(investor.send(depositedValue));
        Refunded(investor, depositedValue);
    }

    // @dev Receive all sent funds
    function () public payable {}
}

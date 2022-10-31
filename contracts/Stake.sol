// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Stake is OwnableUpgradeable {
    mapping(address => uint256) public stakeBalance;
    mapping(address => address) public nodeAddresses;
    mapping(address => address) public stakeAddresses;

    

    struct Order{
        address nodeAddress;
        address buyer;
        uint256 tokenAmount;
        uint256 messageAmount;
    }

    
    

    event MessagePurchase(address indexed node, address indexed buyer, uint256 token, uint256 messages, bytes32 indexed nonce);
    event MessageTokenRate(address indexed node, uint256 rate);

    bool public withdrawalEnabled;
    bool public locked;
    uint256 public minStake;
    IERC20 tokenContract;

    mapping(address => uint256) public nodeTokenPerMessage;
    mapping(address => mapping(address => uint256)) public userMessages;
    mapping(bytes32 => Order ) public orders;

    uint256 public stakerIndex;
    mapping(uint256 => address) public stakerIds;
    mapping(address => uint256) public stakerIdsRef;

    uint256 public minConst;

    event StakeEvent(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event UnStakeEvent(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );

    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    
    function initialize(address _address) public initializer {
        tokenContract = IERC20(_address);
    }

    function stake(uint256 amount) public {
        require(amount > 0, "You need to Stake at least some tokens");
        require(amount >= getMinStake(), "You need to Stake at least some tokens");

        if(stakerIdsRef[msg.sender] == 0 ){
            stakerIndex++;
            stakerIds[stakerIndex] == msg.sender;
            stakerIdsRef[msg.sender] == stakerIndex;
        }
        // uint256 allowance = tokenContract.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Check the token allowance");
        tokenContract.transferFrom(msg.sender, address(this), amount);
        stakeBalance[msg.sender] += amount;
        emit StakeEvent(msg.sender, amount, block.timestamp);
    }

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake() public noReentrancy {
        require(withdrawalEnabled, "Withdrawal is not enabled");
        tokenContract.transfer(msg.sender, stakeBalance[msg.sender]);
        emit UnStakeEvent(
            msg.sender,
            stakeBalance[msg.sender],
            block.timestamp
        );
        stakeBalance[msg.sender] = 0;
    }

    function registerNodeAccount(address nodeAddress) public {
        require(
            msg.sender != nodeAddress,
            "Node address can not be equal to stake address"
        );
        nodeAddresses[msg.sender] = nodeAddress;
        stakeAddresses[nodeAddress] = msg.sender;
    }

    function setMinStake(uint256 _stake) public onlyOwner {
        minStake = _stake;
    }

    function getNodeLevel(address _nodeAddresses)
        public
        view
        returns (uint256)
    {
        address _staker = stakeAddresses[_nodeAddresses];
        if (_staker == address(0)) {
            return 0;
        }
        uint256 balance = stakeBalance[_staker];
        if (balance < getMinStake()) return 0;
        return 1;
    }


    function setTokenPerMessage(uint256 rate) public {
        nodeTokenPerMessage[msg.sender] = rate;
        emit MessageTokenRate(msg.sender, rate);
    }

    function buyMessages(address _nodeAddresses, uint256 tokens, bytes32 nonce) public {
        require(_nodeAddresses != address(0), "Node Address must not be an empty address");
        require(tokens > 0, "You need to add at least a token");
        require(orders[nonce].nodeAddress == address(0), "Order already created");
        tokenContract.transferFrom(msg.sender, _nodeAddresses, tokens);
        uint256 rate = nodeTokenPerMessage[_nodeAddresses];
        uint256 messageCount = tokens/rate;
        userMessages[msg.sender][_nodeAddresses] += messageCount;
        Order memory _order = Order({
            nodeAddress: _nodeAddresses,
            buyer: msg.sender,
            tokenAmount: tokens,
            messageAmount: messageCount
        });
        orders[nonce] = _order;
        emit MessagePurchase(_nodeAddresses, msg.sender, tokens, messageCount, nonce);

    }


    function getMinStake()
        public
        view
        returns (uint256)
    {
        return minConst + (minConst * stakerIndex**2);   
    }

    function setMinConst(uint256 _const) public onlyOwner {
        minConst = _const;
    }
}

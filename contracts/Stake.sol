// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Stake is OwnableUpgradeable {
    mapping(address => uint256) public stakeBalance;
    mapping(address => address) public nodeAddresses;
    mapping(address => address) public stakeAddresses;

    mapping(address => uint256) public nodeTokenPerMessage;
    mapping(address => mapping(address => uint256)) public userMessages;
    

    event MessageTokenIncrease(address node, address nodeAddresses);
    event MessageTokenRate(address node, uint256 rate);

    bool public withdrawalEnabled;
    bool public locked;
    uint256 public minStake;
    IERC20 tokenContract;
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
        if (balance < minStake) return 0;
        return 1;
    }


    function setTokenPerMessage(uint256 rate) public {
        nodeTokenPerMessage[msg.sender] = rate;
        emit MessageTokenRate(msg.sender, rate);
    }

    function transferTokenToAddress(address _address, uint256 tokens) public {
        require(tokens > 0, "You need to add at least a token");
        userMessages[_address][msg.sender] += tokens;
        emit MessageTokenIncrease(_address, msg.sender);

    }
}

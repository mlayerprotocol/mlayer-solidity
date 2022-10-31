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

    uint256 public stakerCount;
    mapping(uint256 => address) public stakerIds;
    mapping(address => uint256) public stakerIdsRef;

    uint256 public minStakable;
    uint256 public calibrator;

    struct AllocationStruct{
        uint256 price;
        uint256 count;
    }

    mapping(address => AllocationStruct[]) public nodeAllocation;

    mapping(address => uint256) public nodeAllocationIndexes;
    mapping(address => address[]) public stakerNodeAddresses;

    uint256 public nodeCount;
    mapping(uint256 => address) public nodeIds;
    mapping(address => uint256) public nodeIdsRef;

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
        minStakable = 5000 * 10**18;
        calibrator= 10000;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "You need to Stake at least some tokens");
        require(amount >= getMinStake(), "You need to Stake at least some tokens");

        if(stakerIdsRef[msg.sender] == 0 ){
            stakerCount++;
            stakerIds[stakerCount] == msg.sender;
            stakerIdsRef[msg.sender] == stakerCount;
        }
        // uint256 allowance = tokenContract.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Check the token allowance");
        tokenContract.transferFrom(msg.sender, address(this), amount);
        stakeBalance[msg.sender] += amount;
        int existingAlloctionIndex = -1;
        for (uint i = 0; i < nodeAllocation[msg.sender].length; i++) {
            if(nodeAllocation[msg.sender][i].price == getMinStake()){
                existingAlloctionIndex = int(i);
                break;
            }
        }
        if(existingAlloctionIndex == -1){
            nodeAllocation[msg.sender].push(AllocationStruct({
                price:  getMinStake(),
                count:  amount/getMinStake()
            }));
        }else{
            nodeAllocation[msg.sender][uint(existingAlloctionIndex)].count += amount/getMinStake();
        }
        
        emit StakeEvent(msg.sender, amount, block.timestamp);
    }

    function enableWithdrawal(bool _enabled) public onlyOwner {
        withdrawalEnabled = _enabled;
    }

    function unStake() public noReentrancy {
        require(withdrawalEnabled, "Withdrawal is not enabled");

        uint total;
        for (uint i = 0; i < nodeAllocation[msg.sender].length; i++) {
            if(nodeAllocation[msg.sender][i].count > 0){
                total += nodeAllocation[msg.sender][i].count * nodeAllocation[msg.sender][i].price;
                nodeAllocation[msg.sender][i].count = 0;
            }
        }
        require(total > 0, "Inadequate Withdrawal Balance");
        tokenContract.transfer(msg.sender, stakeBalance[msg.sender]);
        emit UnStakeEvent(
            msg.sender,
            stakeBalance[msg.sender],
            block.timestamp
        );
        stakeBalance[msg.sender] = 0;
        
    }

    function withdrawableAmount() public view returns (uint) {

        uint total;
        for (uint i = 0; i < nodeAllocation[msg.sender].length; i++) {
            if(nodeAllocation[msg.sender][i].count > 0){
                total += nodeAllocation[msg.sender][i].count * nodeAllocation[msg.sender][i].price;
            }
        }
        return total;
        
    }

    function registerNodeAccount(address nodeAddress) public noReentrancy {
        require(
            msg.sender != nodeAddress,
            "Node address can not be equal to stake address"
        );
        require(
            stakeAddresses[nodeAddress] == address(0),
            "Node already exist"
        );

        bool success;
        for (uint i = 0; i < nodeAllocation[msg.sender].length; i++) {
            if(nodeAllocation[msg.sender][i].count > 0){
                nodeAllocation[msg.sender][i].count -= 1;
                // nodeAddresses[msg.sender] = nodeAddress;
                stakeAddresses[nodeAddress] = msg.sender;
                nodeAllocationIndexes[nodeAddress] = i;
                stakerNodeAddresses[msg.sender].push(
                    nodeAddress
                );
                success = true;

                if(nodeIdsRef[nodeAddress] == 0 ){
                    nodeCount++;
                    nodeIds[nodeCount] == nodeAddress;
                    nodeIdsRef[nodeAddress] == nodeCount;
                }
                break;
            }
        }
        require(
            success,
            "Inadequate Stake Amount"
        );
    }

    function deRegisterNodeAccount(address nodeAddress) public noReentrancy {
        require(
            msg.sender != nodeAddress,
            "Node address can not be equal to stake address"
        );
        require(
            stakeAddresses[nodeAddress] == msg.sender,
            "Not Authorized"
        );
        uint i = nodeAllocationIndexes[nodeAddress];
        nodeAllocation[msg.sender][i].count += 1;
        // nodeAddresses[msg.sender] = address(0);
        stakeAddresses[nodeAddress] = address(0);
        for (uint j = 0; j < stakerNodeAddresses[msg.sender].length; j++) {
            if(stakerNodeAddresses[msg.sender][j] == nodeAddress){
                stakerNodeAddresses[msg.sender][j] = address(0);
            }
            
        }
        
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
        if (_staker == address(0) || stakeBalance[_staker] == 0) {
            return 0;
        }
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
        // return minConst * (1 + (stakerCount/100)**2);   
        return minStakable + ((minStakable*(stakerCount**2))/calibrator);   
    }

    function setMinStakable(uint256 _minStakable) public onlyOwner {
        minStakable = _minStakable;
    }

    function setCalibrator(uint256 _calibrator) public onlyOwner {
        calibrator = _calibrator;
    }
}

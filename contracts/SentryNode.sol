// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";
import {MLUtils} from "./libs/mlayer/utils.sol";

import "hardhat/console.sol";

contract SentryContract is OwnableUpgradeable {
    mapping(uint => bytes) public licenseOperator;
    mapping(uint256 => address) public licenseOwner;
    uint256 private initLicenseCount = 1000; 
    uint256 private licenseCount; 
    mapping(address => uint256[]) public addressLicenses;
    mapping(address => uint) public addressLicenseCount;
    mapping(bytes => uint[]) public operatorLicenses;
    mapping(bytes => uint) public operatorLicenseCount;

    // struct Order {
    //     address nodeAddress;
    //     address buyer;
    //     uint256 tokenAmount;
    //     uint256 messageAmount;
    // }

    // event MessagePurchase(address indexed node, address indexed buyer, uint256 token, uint256 messages, bytes32 indexed nonce);
    // event MessageTokenRate(address indexed node, uint256 rate);

    
    bool public locked;
    uint256 public startNodePrice;
    IERC20 tokenContract;

    // mapping(address => uint256) public nodeTokenPerMessage;
    // mapping(address => mapping(address => uint256)) public userMessages;
    

    uint256 public totalAccounts;
    // mapping(uint256 => address) public stakerIds;
    // mapping(address => uint256) public stakerIdsRef;

    // uint256 public minStakable;
    uint256 public calibrator;

    struct AllocationStruct{
        uint256 price;
        uint256 count;
    }

    // mapping(address => AllocationStruct[]) public nodeAllocation;

    // mapping(address => uint256) public nodeAllocationIndexes;
    // mapping(address => address[]) public stakerNodeAddresses;

   // uint256 public nodeCount;
    // mapping(uint256 => address) public nodeIds;
    // mapping(address => uint256) public nodeIdsRef;

    event PurchaseEvent(
        address indexed account,
        uint256 price,
        uint256 quantity,
        uint256 timestamp
    );
  

    modifier noReentrancy() {
        require(!locked, "Contract Locked");
        locked = true;
        _;
        locked = false;
    }

    function initialize(address _address) public initializer {
        __Ownable_init(msg.sender);
        tokenContract = IERC20(_address);
        startNodePrice = 1 * 10**15;
        calibrator = 10000;
        licenseCount = initLicenseCount;
    }


    struct RegistrationData {
        bytes publicKey;
        uint64 nonce;
        bytes signature;
        bytes commitment;
    }

    mapping(address => bytes[])  public nodesOwned;
    mapping(bytes => address) public operatorsOwner;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

     fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
    function purchaseLicense(uint quantity) public payable noReentrancy()  returns (uint256[] memory) { 
        uint256[] memory licenses = new uint256[](quantity);
        uint licenseCost =  getLicencePrice() * quantity;
        require(msg.value >= licenseCost, "Message value less than total cost");
        // require(tokenContract.transferFrom(msg.sender, address(this), licencePrice * quantity), "Transfer failed");
        // uint balBefore = address(this).balance;
       
        // require(address(this).balance  == (balBefore + licenseCost), "Transfer failed");

        if (msg.value > licenseCost ) {
            // refund excess
            payable(msg.sender).transfer(msg.value - licenseCost);
        }
        uint256 license = licenseCount;
        for (uint i = 0; i < licenses.length; i++) {
            licenses[i] = license;
            licenseOwner[license] = msg.sender;
            addressLicenses[msg.sender].push(license);
            
            license++;
            
        }
        addressLicenseCount[msg.sender] += quantity;
        licenseCount += quantity;
        emit PurchaseEvent(msg.sender, licenseCost, quantity, block.timestamp);
        return licenses;
        
    }
    

    function getRegistrationData(bytes calldata data) public pure returns(RegistrationData memory regData) {
         bytes memory part;
         bytes memory part2;
         bytes memory nonce;
        (regData.publicKey, part) = MLUtils.split(data,  0x3A);
        (nonce,  part2) = MLUtils.split(part,  0x3A);
        regData.nonce = MLUtils.bytesToUint64(nonce);
        (regData.commitment,  regData.signature) = MLUtils.split(part2,  0x3A);
        return regData;
    }

    function registerOperator(bytes calldata regDataBytes, uint[] calldata licenses) public noReentrancy {
         require(
            addressLicenseCount[msg.sender] > 0,
            "Not a license holder"
        );
        RegistrationData memory regData = getRegistrationData(regDataBytes);
        this.registerNodeOperator(regData, licenses);
    }

    function verifySingleSigner(RegistrationData calldata regData, bytes32 message) public pure returns (bool) {
         return LibSchnorr.verifySignature(
           LibSecp256k1Extended.decompressPublicKey(regData.publicKey), message, bytes32(regData.signature), MLUtils.bytesToAddress(regData.commitment)
        );
    }

    function registerNodeOperator(RegistrationData calldata regData, uint[] calldata licenses) public noReentrancy {
         require(
            addressLicenseCount[msg.sender] > 0,
            "Not a license holder"
        );
        address owner = operatorsOwner[regData.publicKey];
        require(owner == address(0) || owner == msg.sender,  "Sentry/registerNodeAccount: Sentry node is registered to different account");
        if (owner == address(0)) {
           //  require(MLUtils.abs(int256(block.timestamp - (regData.nonce)/1000)) < 3600, "Sentry/registerNodeAccount: Nonce expired/invalid");
            operatorsOwner[regData.publicKey] = msg.sender;
            nodesOwned[msg.sender].push(regData.publicKey);
        }
        bytes memory data = abi.encodePacked(uint64(block.chainid), regData.nonce);
      
        bytes32 dataHash = keccak256(data);
       
        bool ok = verifySingleSigner(regData, dataHash);
        
        require(ok, "Sentry/registerNodeAccount: invalid node signature");
        // assign the licences to operator

         // 2. check if any of the licences is already registered
        for (uint i; i < licenses.length; i++ ) {
            require(licenseOwner[licenses[i]]  == msg.sender, "Sentry/registerNodeAccount: you must own all licences");
            require(licenseOperator[licenses[i]].length == 0, "Sentry/registerNodeAccount: license already registered");
            licenseOperator[licenses[i]] = regData.publicKey;
            operatorLicenses[regData.publicKey].push(licenses[i]);
        }
        operatorLicenseCount[regData.publicKey] += licenses.length;
    }

    function deRegisterNodeOperator(bytes memory publicKey, uint[] memory licences) public noReentrancy {
        // require(
        //     msg.sender != nodeAddress,
        //     "Node address can not be equal to stake address"
        // );
        // require(
        //     stakeAddresses[nodeAddress] == msg.sender,
        //     "Not Authorized"
        // );
        // uint i = nodeAllocationIndexes[nodeAddress];
        // nodeAllocation[msg.sender][i].count += 1;
        // // nodeAddresses[msg.sender] = address(0);
        // stakeAddresses[nodeAddress] = address(0);
        // for (uint j = 0; j < stakerNodeAddresses[msg.sender].length; j++) {
        //     if(stakerNodeAddresses[msg.sender][j] == nodeAddress){
        //         stakerNodeAddresses[msg.sender][j] = address(0);
        //     }
        // }
    }

  
    // function getNodeLevel(address _nodeAddresses)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     address _staker = stakeAddresses[_nodeAddresses];
    //     if (_staker == address(0) || stakeBalance[_staker] == 0) {
    //         return 0;
    //     }
    //     return 1;
    // }


    // function setTokenPerMessage(uint256 rate) public {
    //     nodeTokenPerMessage[msg.sender] = rate;
    //     emit MessageTokenRate(msg.sender, rate);
    // }

    // function buyMessages(address _nodeAddresses, uint256 tokens, bytes32 nonce) public {
    //     require(_nodeAddresses != address(0), "Node Address must not be an empty address");
    //     require(tokens > 0, "You need to add at least a token");
    //     require(orders[nonce].nodeAddress == address(0), "Order already created");
    //     tokenContract.transferFrom(msg.sender, _nodeAddresses, tokens);
    //     uint256 rate = nodeTokenPerMessage[_nodeAddresses];
    //     uint256 messageCount = tokens/rate;
    //     userMessages[msg.sender][_nodeAddresses] += messageCount;
    //     Order memory _order = Order({
    //         nodeAddress: _nodeAddresses,
    //         buyer: msg.sender,
    //         tokenAmount: tokens,
    //         messageAmount: messageCount
    //     });
    //     orders[nonce] = _order;
    //     emit MessagePurchase(_nodeAddresses, msg.sender, tokens, messageCount, nonce);

    // }
    function withdrawEthers(address  to) public onlyOwner() {
        withdraw(address(0), to, address(this).balance);
    }

    function withdraw(address token,  address  to, uint amount) public onlyOwner() {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20(token).transfer(to, amount), "transfer failed");
        }
    }

    function getLicencePrice()
        public
        view
        returns (uint256)
    {
        // return minConst * (1 + (stakerCount/100)**2);   
        return startNodePrice + ((startNodePrice*((licenseCount-initLicenseCount)**2))/calibrator);   
    }

    function setStartNodePrice(uint256 _price) public onlyOwner {
        startNodePrice = _price;
    }

    function setCalibrator(uint256 _calibrator) public onlyOwner {
        calibrator = _calibrator;
    }
}

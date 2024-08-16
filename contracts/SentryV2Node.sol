// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import {console} from "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";
import {MLUtils} from "./libs/mlayer/utils.sol";
import {INodeContract} from "./interfaces/ISentryNode.sol";
import {ChainInfo} from "./common/ChainInfo.sol";

contract SentryV2Node is OwnableUpgradeable {
    mapping(uint => bytes) public licenseOperator;
    mapping(uint256 => address) public licenseOwner;
    uint256 private licenseIdPadding = 1000;
    uint256 private licenseCount;
    uint256 private lastCycleLicensePurchase;
    mapping(uint => uint) public cycleLicenseCount;
    mapping(address => uint256[]) public accountLicenses;
    mapping(address => uint) public accountLicenseCount;
    mapping(bytes => uint[]) public operatorLicenses;
    mapping(bytes => uint) public operatorLicenseCount;
    mapping(bytes => mapping(uint => uint)) public operatorCycleLicenseCount;

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

    struct AllocationStruct {
        uint256 price;
        uint256 count;
    }

    uint256 public startTime;
    uint256 public startBlock;
    uint256 public epochDivider;
    uint256 public blockTime;

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

    function initialize(
        address _token,
        uint256 _blockTime,
        uint _startBlock
    ) public initializer {
        __Ownable_init(msg.sender);
        tokenContract = IERC20(_token);
        startNodePrice = 1 * 10 ** 15;
        calibrator = 10000;
        // licenseCount = initLicenseCount;
       startTime = block.timestamp;
        startBlock = block.number;
        blockTime = _blockTime;
        if (_startBlock > 0) {
            startBlock = _startBlock;
        }
    }

    struct RegistrationData {
        bytes publicKey;
        uint nonce;
        bytes signature;
        address commitment;
    }

    struct CycleGapData {
        uint start;
        uint end;
        uint256 licenseCount;
    }

    CycleGapData[] cycleGapData;

    mapping(address => bytes[]) public nodesOwned;
    mapping(bytes => address) public operatorsOwner;

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    function purchaseLicense(
        uint quantity
    ) public payable noReentrancy returns (uint256[] memory) {
        uint256[] memory licenses = new uint256[](quantity);
        uint licenseCost = getLicencePrice() * quantity;
        require(msg.value >= licenseCost, "Message value less than total cost");
        // require(tokenContract.transferFrom(msg.sender, address(this), licencePrice * quantity), "Transfer failed");
        // uint balBefore = address(this).balance;

        // require(address(this).balance  == (balBefore + licenseCost), "Transfer failed");

        if (msg.value > licenseCost) {
            // refund excess
            payable(msg.sender).transfer(msg.value - licenseCost);
        }
        lastCycleLicensePurchase = getCurrentCycle();
        uint256 licenseId = licenseCount + licenseIdPadding;
        for (uint i = 0; i < licenses.length; i++) {
            licenses[i] = licenseId;
            licenseOwner[licenseId] = msg.sender;
            accountLicenses[msg.sender].push(licenseId);

            licenseId++;
        }
        accountLicenseCount[msg.sender] += quantity;

        fillLicenseCountGap();

       
        licenseCount += quantity;
        cycleLicenseCount[lastCycleLicensePurchase + 1] = licenseCount;
        emit PurchaseEvent(msg.sender, licenseCost, quantity, block.timestamp);
        return licenses;
    }

    function fillLicenseCountGap() public {
        uint curCycle = getCurrentCycle();
        if (curCycle - lastCycleLicensePurchase > 1) {
            for (uint i = lastCycleLicensePurchase; i <= curCycle; i++) {
                cycleLicenseCount[i] = licenseCount;
            }
        }
    }

    function getRegistrationData(
        bytes calldata data
    ) public pure returns (RegistrationData memory regData) {
        bytes memory part;
        bytes memory part2;
        bytes memory nonce;
        bytes memory commitment;
        (regData.publicKey, part) = MLUtils.split(data, 0x3A);
        (nonce, part2) = MLUtils.split(part, 0x3A);
        regData.nonce = MLUtils.bytesToUint(nonce);
        (commitment, regData.signature) = MLUtils.split(part2, 0x3A);
        regData.commitment = MLUtils.bytesToAddress(commitment);
        return regData;
    }

    function registerOperator(
        bytes calldata regDataBytes,
        uint[] calldata licenses
    ) public noReentrancy {
        require(accountLicenseCount[msg.sender] > 0, "Not a license holder");
        RegistrationData memory regData = getRegistrationData(regDataBytes);
        this.registerNodeOperator(regData, licenses);
    }

    function registerNodeOperator(
        RegistrationData calldata regData,
        uint[] calldata licenses
    ) public noReentrancy {
        require(accountLicenseCount[msg.sender] > 0, "Not a license holder");
        //  bytes32 hashSign = keccak256(abi.encodePacked(regData.signature, regData.nonce));
        address owner = operatorsOwner[regData.publicKey];
        require(
            owner == address(0) || owner == msg.sender,
            "registerNodeOperator: Node is registered to different account"
        );
        if (owner == address(0)) {
            require(
                MLUtils.abs(int256(block.timestamp - (regData.nonce) / 1000)) <
                    36000,
                "registerNodeOperator: Nonce expired/invalid"
            );
            operatorsOwner[regData.publicKey] = msg.sender;
            nodesOwned[msg.sender].push(regData.publicKey);
        }

        bytes32 dataHash = keccak256(
            abi.encodePacked(block.chainid, regData.nonce)
        );
       console.log("DATATHAA", uint(dataHash), regData.nonce);
        bool ok = LibSchnorr.verifySignature(
            LibSecp256k1Extended.decompressPublicKey(regData.publicKey),
            dataHash,
            bytes32(regData.signature),
            regData.commitment
        );

        require(ok, "registerNodeOperator: invalid node signature");
        // assign the licences to operator

        // 2. check if any of the licences is already registered
        for (uint i; i < licenses.length; i++) {
            require(
                licenseOwner[licenses[i]] == msg.sender,
                "registerNodeOperator: you must own all licenses"
            );
            require(
                licenseOperator[licenses[i]].length == 0,
                "registerNodeOperator: license already registered"
            );
            licenseOperator[licenses[i]] = regData.publicKey;
            operatorLicenses[regData.publicKey].push(licenses[i]);
        }
        operatorLicenseCount[regData.publicKey] += licenses.length;
        operatorCycleLicenseCount[regData.publicKey][
            getCurrentCycle()
        ] += licenses.length;
    }

    function deRegisterNodeOperator(
        bytes memory publicKey,
        uint[] memory licenses
    ) public noReentrancy {
        for (uint i; i < licenses.length; i++) {
            require(
                licenseOwner[licenses[i]] == msg.sender,
                "deRegisterNodeOperator: not license owner"
            );
            require(
                licenseOperator[licenses[i]].length == 0,
                "deRegisterNodeOperator: license already registered"
            );

            delete licenseOperator[licenses[i]];

            for (uint j = 0; j < operatorLicenses[publicKey].length; j++) {
                if (operatorLicenses[publicKey][j] == licenses[i]) {
                    operatorLicenses[publicKey][j] = operatorLicenses[
                        publicKey
                    ][operatorLicenses[publicKey].length - 1];
                    operatorLicenses[publicKey].pop();
                    break;
                }
            }

            operatorLicenses[publicKey].push(licenses[i]);
        }
        operatorLicenseCount[publicKey] -= licenses.length;
    }

    function withdrawEthers(address to) public onlyOwner {
        withdraw(address(0), to, address(this).balance);
    }

    function withdraw(address token, address to, uint amount) public onlyOwner {
        fillLicenseCountGap();
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            require(IERC20(token).transfer(to, amount), "transfer failed");
        }
    }

    function getLicencePrice() public view returns (uint256) {
        // return minConst * (1 + (stakerCount/100)**2);
        return
            startNodePrice +
            ((startNodePrice * ((licenseCount) ** 2)) /
                calibrator);
    }

    function setStartNodePrice(uint256 _price) public onlyOwner {
        startNodePrice = _price;
    }

    function setCalibrator(uint256 _calibrator) public onlyOwner {
        calibrator = _calibrator;
    }

    function getChainInfo()
        public
        view
        returns (ChainInfo memory)
    {}

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getStartBlock() public view returns (uint256) {
        return startBlock;
    }

    function getEpoch(
        uint256 blockNumber
    ) public view returns (uint256) {
        return ((blockNumber - startBlock) * blockTime) / ((1 days) / 2);
    }

    /**
     * ~ 24 hours
     */
    function getCycle(uint256 blockNumber) public view returns (uint256) {
        return ((blockNumber - startBlock) * blockTime) / ((1 days));
    }

    function getCurrentCycle() public view returns (uint256) {
        return getCycle(block.number);
    }

    function getCurrentBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /**
     * ~ 12 hour epoch
     */
    function getCurrentEpoch() public view returns (uint256) {
        return getEpoch(block.number);
    }

    function getYear(uint256 _block) public view returns (uint256) {
        return
            ((_block - startBlock) * blockTime) / ((365 days) + ((1 days) / 4));
    }

    function getCycleLicenseCount(
        uint256 cycle
    ) public view returns (uint256) {
        if (cycleLicenseCount[cycle] != 0) {
            return cycleLicenseCount[cycle];
        } else {
            return licenseCount;
        }
    }

    function getTotalValidatorLicenceCount(
        uint256 cycle
    ) public view returns (uint256) {}

    function getSentryLicenseCount(
        uint256 cycle,
        bytes memory operator
    ) public view returns (uint256) {
        return operatorCycleLicenseCount[operator][cycle];
    }

    function getValidatorLicenceCount(
        uint256 cycle,
        bytes memory operator
    ) public view returns (uint256) {}

}

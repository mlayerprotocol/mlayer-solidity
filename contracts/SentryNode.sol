// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./common/IERC20.sol";
import {console} from "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibSchnorr} from "./libs/schnorr/LibSchnorr.sol";
import {LibSecp256k1Extended} from "./libs/schnorr/LibSecp256k1Extended.sol";
import {MLUtils} from "./libs/mlayer/utils.sol";
import {INodeContract} from "./interfaces/ISentryNode.sol";
import {INetwork} from "./interfaces/INetwork.sol";
import {ILicenseContract, PromoCode} from "./interfaces/ILicense.sol";
import {ChainInfo, RegistrationData} from "./common/ChainInfo.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract SentryNode is OwnableUpgradeable, AccessControlUpgradeable {
    mapping(uint => bytes) public licenseOperator;
    // mapping(uint256 => address) public licenseContract.ownerOf(;
    uint256 private licenseIdPadding;
    uint256 private licenseCount;
    uint256 private lastCycleLicensePurchase;
    uint256 public activeLicenseCount;
    mapping(uint256 => uint256) private activeLicenseByIndex; // serial id to license
    mapping(uint256 => uint256) public activeLicensesIndex; // license to serial id
    mapping(uint => uint) private cycleLicenseCount;
    mapping(uint => uint) private cycleActiveLicenseCount;
    // mapping(address => uint256[]) public accountLicenses;
    mapping(address => uint) public accountLicenseCount;
    mapping(bytes => uint[]) public operatorLicenses;
    mapping(bytes => uint) public operatorLicenseCount;
    mapping(bytes => mapping(uint => uint)) public operatorCycleLicenseCount;
    INetwork public network;
   //  mapping(address => uint) initialLicencePrice;
    bytes[] public operators;
    mapping(bytes16=>uint) private operatorIndex;
    bool public locked;
    IERC20 tokenContract;
    ILicenseContract licenseContract;
    uint256 public totalAccounts;
    uint256 public calibrator;
    CycleGapData[] cycleGapData;
    mapping(address => bytes[]) public nodesOwned;
    mapping(bytes => address) public operatorsOwner;

    struct AllocationStruct {
        uint256 price;
        uint256 count;
    }

    

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
         address _network,
        address _token,
        address _licenseContract
    ) public initializer {
        __Ownable_init(msg.sender);
         __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        licenseIdPadding = 1000;
        tokenContract = IERC20(_token);
        // initialLicencePrice[address(0)] = licensePrice; //1 * 10 ** 15;
        // calibrator = 10000;
        network = INetwork(_network);
        licenseContract = ILicenseContract(_licenseContract);
        // will error if invalid network address is passed
        require(network.getChainInfo().currentBlock >= 0, "invalid network contract");
    }

    function authorizeAdmin() public onlyOwner() {
         //__AccessControl_init();

         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
         _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }
    struct CycleGapData {
        uint start;
        uint end;
        uint256 licenseCount;
    }

   

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    

    function purchaseLicense(
        uint quantity,
     string memory promoCode
    ) public payable  returns (uint256[] memory) {
        return purchaseLicenseFor(quantity, msg.sender, promoCode);
    }

    function purchaseLicenseFor(
        uint quantity,
        address reciever,
        string memory promoCode
    ) public payable noReentrancy returns (uint256[] memory) {
        uint256[] memory licenses = licenseContract.mint{value: msg.value}(quantity, reciever, promoCode);
        // uint totalCost = getLicencePrice(token) * quantity;
        // require(totalCost > 0, "invalid token");
        
        // require(tokenContract.transferFrom(msg.sender, address(this), licencePrice * quantity), "Transfer failed");
        // uint balBefore = address(this).balance;

        // require(address(this).balance  == (balBefore + totalCost), "Transfer failed");
        // if(token == address(0)) {
        //     require(msg.value >= totalCost, "Message value less than total cost");
        //     if (msg.value > totalCost) {
        //         // refund excess
        //         payable(msg.sender).transfer(msg.value - totalCost);
        //     }
        // } else {
        //     require(IERC20(token).transferFrom(msg.sender, address(this), totalCost), "Token transfer failed");
        //     IERC20(token).burn(totalCost);
        // }
        lastCycleLicensePurchase = network.getCurrentCycle();
        // uint256 licenseId = licenseCount + licenseIdPadding;
        // for (uint i = 0; i < licenses.length; i++) {
            // licenses[i] = licenseId;
           //  licenseContract.ownerOf([licenseId] = reciever;
           // accountLicenses[reciever].push(licenseId);

            // licenseId++;
        // }
        fillLicenseCountGap();
        licenseCount += licenses.length;
        cycleLicenseCount[lastCycleLicensePurchase + 1] = licenseCount;
        //  emit PurchaseEvent(reciever, totalCost, quantity, block.timestamp);
        return licenses;
    }

    function fillLicenseCountGap() public {
        uint curCycle = network.getCurrentCycle();
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

    function isActive(uint license) public view returns(bool) {
        return licenseOperator[license].length > 0;
    }

    function registerOperatorBytes(
        bytes calldata regDataBytes,
        uint[] calldata licenses
    ) public noReentrancy {
        require(licenseContract.balanceOf(msg.sender) > 0, "Not a license holder");
        RegistrationData memory regData = getRegistrationData(regDataBytes);
        this.registerOperator(regData, licenses);
    }

    function registerOperator(
        RegistrationData calldata regData,
        uint[] calldata licenses
    ) public noReentrancy {
        require(licenseContract.balanceOf(msg.sender) > 0, "Not a license holder");
        if (operatorIndex[bytes12(regData.publicKey)] == 0) {
            operators.push(regData.publicKey);
            operatorIndex[bytes12(regData.publicKey)] = operators.length - 1;
        }
        //  bytes32 hashSign = keccak256(abi.encodePacked(regData.signature, regData.nonce));
        address owner = operatorsOwner[regData.publicKey];
        require(
            owner == address(0) || owner == msg.sender,
            "registerNodeOperator: Node is registered to different account"
        );
        if (owner == address(0)) {
            // require(
            //     MLUtils.abs(int256(block.timestamp - (regData.nonce) / 1000)) <
            //         3600,
            //     "registerNodeOperator: Nonce expired/invalid"
            // );
            operatorsOwner[regData.publicKey] = msg.sender;
            nodesOwned[msg.sender].push(regData.publicKey);
        }

        bytes32 dataHash = keccak256(
            abi.encodePacked(block.chainid, regData.nonce)
        );
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
             console.log("REGISTER", "yes");
            require(
                licenseOwner(licenses[i]) == msg.sender,
                "registerNodeOperator: you must own all licenses"
            );
            require(
                !isActive(licenses[i]),
                "registerNodeOperator: license already registered"
            );
            licenseOperator[licenses[i]] = regData.publicKey;
            operatorLicenses[regData.publicKey].push(licenses[i]);
            uint activeIndex = activeLicensesIndex[licenses[i]] ;
            if (activeIndex != 0) {
                activeLicenseByIndex[activeIndex] = licenses[i];
            } else {
                activeLicenseByIndex[activeLicenseCount+i] = licenses[i];
                activeLicensesIndex[licenses[i]] = activeLicenseCount+i;
            }
            
        }

        cycleActiveLicenseCount[network.getCurrentCycle()+1] += licenses.length;
        activeLicenseCount += licenses.length;
        operatorLicenseCount[regData.publicKey] += licenses.length;
        operatorCycleLicenseCount[regData.publicKey][
            network.getCurrentCycle()+1
        ] += licenses.length;
    }
    function licenseOwner(uint tokenId) public view returns(address) {
        try licenseContract.ownerOf(tokenId) returns (address result) {
            return result;
        } catch(bytes memory) {
            return address(0x0);
        }
    }

    function deRegisterNodeOperator(
        uint[] memory licenses
    ) public noReentrancy {
        uint deregistered;
        for (uint i; i < licenses.length; i++) {
            bool isActiveLicense = isActive(licenses[i]);
            if (!isActiveLicense) continue;
            require(
                licenseOwner(licenses[i]) == msg.sender,
                "deRegisterNodeOperator: not license owner"
            );
          
            bytes memory publicKey = licenseOperator[licenses[i]];
           
            require(
                publicKey.length == 0,
                "deRegisterNodeOperator: license already registered"
            );
            
            if (isActiveLicense) {
                deregistered++;
                delete licenseOperator[licenses[i]];
                delete activeLicenseByIndex[activeLicensesIndex[licenses[i]]];
                for (uint j = 0; j < operatorLicenses[publicKey].length; j++) {
                    if (operatorLicenses[publicKey][j] == licenses[i]) {
                        operatorLicenses[publicKey][j] = operatorLicenses[
                            publicKey
                        ][operatorLicenses[publicKey].length - 1];
                        operatorLicenses[publicKey].pop();
                        break;
                    }
                }
                operatorLicenseCount[publicKey] -= 1;
            } 
            // operatorLicenses[publicKey].push(licenses[i]);
            if (operatorLicenseCount[publicKey] == 0) {
                operators[operatorIndex[bytes12(publicKey)]] = operators[operators.length-1];
                operators.pop();
                operatorIndex[bytes12(publicKey)] = 0;
                removeOperatorFromOwnerList(msg.sender, publicKey);
            }
        }
       cycleActiveLicenseCount[network.getCurrentCycle()+1] -= deregistered;
       activeLicenseCount -= deregistered;
       

    }
    function removeOperatorFromOwnerList(address owner, bytes memory operator) private {
        uint len = nodesOwned[owner].length;
        if (len==1 &&  bytes32(nodesOwned[owner][0]) == bytes32(operator)) {
            nodesOwned[owner].pop();
            return;
        }
        for (uint i; i < len; i++ ) {
            if (bytes32(nodesOwned[owner][i]) == bytes32(operator)) {
                nodesOwned[owner][i]=nodesOwned[owner][len-1];
                nodesOwned[owner].pop();
                return;
            }
        } 
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

    // function getLicencePrice(address token) public view returns (uint256) {
    //     // return minConst * (1 + (stakerCount/100)**2);
    //     uint price = initialLicencePrice[token];
    //     if (price == 0) return 0;
    //     return
    //         price +
    //         ((price * ((licenseCount) ** 2)) /
    //             calibrator);
    // }

    // function setInitialLicencePrice(address token, uint256 _price) public onlyOwner {
    //     initialLicencePrice[token] = _price;
    // }

    // function setCalibrator(uint256 _calibrator) public onlyOwner {
    //     calibrator = _calibrator;
    // }

    function getCycleActiveLicenseCount(
        uint256 cycle
    ) public view returns (uint256) {
        if (cycleActiveLicenseCount[cycle] != 0) {
            return cycleActiveLicenseCount[cycle];
        } else {
            return activeLicenseCount;
        }
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


    function getOperatorCycleLicenseCount(
         bytes memory operator,
        uint256 cycle
    ) public view returns (uint256) {
        return operatorCycleLicenseCount[operator][cycle];
    }

    function getOperatorLicenses(
        bytes memory operator
    ) public view returns (uint256[] memory) {
        return operatorLicenses[operator];
    }

    function getOperators(uint page, uint perPage) public view returns (bytes[] memory opr) {
        if (perPage == 0) {
            perPage = 40;
        }
        bytes[] memory oprators = new bytes[](perPage);
        uint len;
        for(uint i = 0; i<perPage; i++) {
            uint index = i + ((page - 1) * perPage);
            if (index >= operators.length) {
                break;
            }
            oprators[i] = operators[index];
            len++;
        }
         opr = new bytes[](len);
         for(uint j = 0; j<len; j++) {
            opr[j] =  oprators[j];
        }
    }

  

}

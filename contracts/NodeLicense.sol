// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PromoCode} from "./interfaces/ILicense.sol";
import {console} from "hardhat/console.sol";

contract NodeLicense is ERC721EnumerableUpgradeable, AccessControlUpgradeable{
    using Strings for uint256;
   uint256 private tokenIds;
    uint256 public maxSupply; // Maximum number of licenses that can be minted
    // Define the pricing table
    Tier[] private pricingTiers;
    uint256 public referralDiscountPercentage;
    uint256 public referralRewardPercentage;
    uint256 public generatePromoCodeThreshold;
    mapping(address => string[]) public accountPromoCodes;

    address payable public  paymentReceiver;

    // Boolean to control whether referral rewards can be claimed
    bool public claimable;

    // Mapping from token ID to minting timestamp
    mapping (uint256 => uint256) private mintTimestamps;

    // Mapping from promo code to PromoCode struct
    mapping (bytes32 => PromoCode) private promoCodes;
    string[] public promoCodesList;

    // Mapping from referral address to referral reward
    mapping (address => uint256) public referralRewards;

    // Mapping from token ID to average cost, this is used for refunds over multiple tiers
    mapping (uint256 => uint256) private averagePrice;
    
    // Mapping for whitelist to claim NFTs without a price
    mapping (address => uint16) public whitelist;

    address public nodeContract;


 

    // Define the pricing tiers
    struct Tier {
        uint256 price;
        uint256 quantity;
    }

    // Define the PromoCode struct
    

    event PromoCodeAdded(string promoCode, address recipient);
    event PromoCodeUpdated(string promoCode, bool active);
    event PromoCodeGenerated(string promoCode, address recipient);
    event RewardClaimed(address indexed claimer, uint256 amount);
    event PricingTierSetOrAdded(uint256 index, uint256 price, uint256 quantity);
    event ReferralRewardPercentagesChanged(uint256 referralDiscountPercentage, uint256 referralRewardPercentage);
    event RefundOccurred(address indexed refundee, uint256 amount);
    event ReferralReward(address indexed buyer, address indexed referralAddress, uint256 amount);
    event FundsWithdrawn(address indexed admin, uint256 amount);
    event FundsReceiverChanged(address indexed admin, address newFundsReceiver);
    event ClaimableChanged(address indexed admin, bool newClaimableState);
    event WhitelistAmountUpdatedByAdmin(address indexed redeemer, uint16 newAmount);
    event WhitelistAmountRedeemed(address indexed redeemer, uint16 newAmount);
    
    

 function initialize(
         string memory name,
        string memory symbol,
        address _paymentReceiver,
        Tier[] memory _pricingTiers
    ) public initializer {
        __AccessControl_init();
        __ERC721Enumerable_init();
        __ERC721_init(name, symbol);
         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Optionally, make deployer an admin for this role
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        paymentReceiver = payable(_paymentReceiver);
        for(uint i; i<_pricingTiers.length; i++) {
            addPricingTier(_pricingTiers[i].price, _pricingTiers[i].quantity);
        }
        generatePromoCodeThreshold = 10;
    }

    /**
     * @notice Adds a new promo code.
     * @param _promoCode The promo code.
     * @param _recipient The recipient address.
     */
    function addPromoCode(string calldata _promoCode, address _recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        createPromoCode(_promoCode, _recipient);
    }

     /**
     * @notice Creates a new promo code.
     * @param _promoCode The promo code.
     * @param _recipient The recipient address.
     * @dev internal function
     */
    function createPromoCode(string calldata _promoCode, address _recipient) internal {
        require(_recipient != address(0), "Recipient address cannot be zero");
        bytes32 hash = hashPromoCode(_promoCode);
        require(promoCodes[hash].owner == address(0x0), "already exist");
        promoCodes[hash] = PromoCode(_recipient, 0, true, _promoCode);
        promoCodesList.push(_promoCode);
        accountPromoCodes[_recipient].push(_promoCode);
        emit PromoCodeAdded(_promoCode, _recipient);
    }

     /**
     * @notice Activate/Deactivate a promo code.
     * @param active The promo code to disable.
     */
    function updatePromoCode(string calldata _promoCode, bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
         bytes32 hash = hashPromoCode(_promoCode);
        require(promoCodes[hash].owner != address(0), "Promo code does not exist");
        promoCodes[hash].active = active;
        emit PromoCodeUpdated(_promoCode, active);
    }

    function getAccountPromocodes(address account) public view returns (PromoCode[] memory codes) {
        codes = new PromoCode[](accountPromoCodes[account].length);
        for(uint i; i<accountPromoCodes[account].length; i++ ) {
            string memory codeString = accountPromoCodes[account][i];
            codes[i] = promoCodes[hashPromoCode(codeString)];
        }
    }

    
    function setNodeContract(address addr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addr != address(0x0), "cannot be zero address");
        nodeContract = addr;
    }

    function hashPromoCode(string memory _promocode) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(_promocode));
    }
    /**
     * @notice Returns the promo code details.
     * @param _promoCode The promo code to get.
     * @return The promo code details.
     */
    function getPromoCode(string calldata _promoCode) external view returns (PromoCode memory) {
        return promoCodes[hashPromoCode(_promoCode)];
    }


 function setPaymentReceiver(address _receiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_receiver != address(0), "receiver cannot be the zero address");
    paymentReceiver = payable(_receiver);
}
    /**
     * @notice Returns the length of the pricing tiers array.
     * @return The length of the pricing tiers array.
     */
    function getPricingTiersLength() external view returns (uint256) {
        return pricingTiers.length;
    }

    /**
     * @notice Mints new NodeLicense tokens.
     * @param _amount The amount of tokens to mint.
     * @param _receiver The receiver.
     */
    function mint(uint256 _amount, address _receiver, string calldata promoCodeString) public payable returns (uint[] memory _tokenIds) {
        require(msg.sender == nodeContract, "not authorized");
        require(pricingTiers.length > 0,"contract not initialized");

        require(
            tokenIds + _amount <= maxSupply,
            "Exceeds maxSupply"
        );
        settlePayments(_amount, promoCodeString);
        _tokenIds = new uint256[](_amount);
        for (uint256 i = 0; i < _amount; i++) {
           
            tokenIds++;
             
            uint256 newItemId = tokenIds;
            _mint(_receiver, newItemId);
            // Record the minting timestamp
            mintTimestamps[newItemId] = block.timestamp;
            _tokenIds[i] = newItemId;
        }
        
    }

    /**
     * @notice Mints new NodeLicense tokens.
     * @param _amount The amount of tokens.
     * @param promoCodeString The promo code.
     */
    function settlePayments(uint _amount, string calldata promoCodeString) private {
        bytes32 _promoCode = hashPromoCode(promoCodeString);
        PromoCode memory promoCode = promoCodes[_promoCode];
        require(
            promoCode.owner != msg.sender,
            "Referral address cannot be the sender's address"
        );
        uint256 finalPrice = licensePrice(_amount, promoCodeString);
        require(msg.value >= finalPrice, "Ether value sent is not correct");

        // Calculate the referral reward
        uint256 referralReward = 0;
        if (promoCode.owner != address(0)) {
            referralReward = finalPrice * referralRewardPercentage / 100;
            referralRewards[promoCode.owner] += referralReward;
            promoCodes[_promoCode].received += referralReward;
            emit ReferralReward(msg.sender, promoCode.owner, referralReward);
        }
        (bool sent,) = paymentReceiver.call{value: finalPrice - referralReward}("");
        require(sent, "Failed to send payment");
        uint256 remainder = msg.value - finalPrice;

        // Send back the remainder amount
        if (remainder > 0) {
            (bool returnExcess,) = msg.sender.call{value: remainder}("");
            require(returnExcess, "Failed to send back the remainder Ether");
        }
    }

    
    /**
     * @notice Public function to redeem tokens from on whitelist.
     */
    function redeemFromWhitelist() external {

        uint256 startTime = 1703275200; // Fri Dec 22 2023 12:00:00 GMT-0800 (Pacific Standard Time)
        require(block.timestamp >= startTime, "Redemption is not eligible yet");
        require(block.timestamp <= startTime + 30 days, "Redemption period has ended");
        require(whitelist[msg.sender] > 0, "Invalid whitelist amount");
        uint16 toMint = whitelist[msg.sender];
        if(toMint > 50){
            toMint = 50;
        }
        require(
            tokenIds + toMint <= maxSupply,
            "Exceeds maxSupply"
        );
        for (uint16 i = 0; i < toMint; i++) {
           tokenIds++;
            uint256 newItemId = tokenIds;
            _mint(msg.sender, newItemId);
            mintTimestamps[newItemId] = block.timestamp;
        }
        uint16 newAmount = whitelist[msg.sender] - toMint;
        whitelist[msg.sender] = newAmount;
        emit WhitelistAmountRedeemed(msg.sender, newAmount);
    }

    /**
     * @notice Calculates the price for minting NodeLicense tokens.
     * @param _amount The amount of tokens to mint.
     * @param promoCode The promo code to use address.
     * @return The price in wei.
     */
    function licensePrice(uint256 _amount, string calldata promoCode) public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 totalCost = 0;
        uint256 remaining = _amount;
        uint256 tierSum = 0;
        bytes32 _promoCode = hashPromoCode(promoCode);

        for (uint256 i = 0; i < pricingTiers.length; i++) {
            tierSum += pricingTiers[i].quantity;
            uint256 availableInThisTier = tierSum > totalSupply
                ? tierSum - totalSupply
                : 0;

            if (remaining <= availableInThisTier) {
                totalCost += remaining * pricingTiers[i].price;
                remaining = 0;
                break;
            } else {
                totalCost += availableInThisTier * pricingTiers[i].price;
                remaining -= availableInThisTier;
                totalSupply += availableInThisTier;
            }
        }

        require(remaining == 0, "Not enough licenses available for sale");

        // Apply discount if promo code is active
        if (abi.encodePacked(promoCode).length > 0 && promoCodes[_promoCode].active) {
            totalCost = totalCost * (100 - referralDiscountPercentage) / 100;
        }

        return totalCost;
    }

    /**
     * @notice Allows a user to claim their referral reward.
     * @dev The function checks if claiming is enabled and if the caller has a reward to claim.
     * If both conditions are met, the reward is transferred to the caller and their reward balance is reset.
     */
    function claimPromoReward() external {
        require(claimable, "Claiming of referral rewards is currently disabled");
        uint256 reward = referralRewards[msg.sender];
        require(reward > 0, "No referral reward to claim");
        referralRewards[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed.");
        emit RewardClaimed(msg.sender, reward);
    }



    /**
     * @notice Allows the admin to toggle the claimable state of referral rewards.
     * @param _claimable The new state of the claimable variable.
     * @dev Only callable by the admin.
     */
    function setClaimable(bool _claimable) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimable = _claimable;
        emit ClaimableChanged(msg.sender, _claimable);
    }

    /**
     * @notice Allows the admin to toggle generatePromoCodeThreshold state.
     * @param limit The new state of the generatePromoCodeThreshold variable.
     * @dev Only callable by the admin.
     */
    function setGeneratePromoCodeThreshold(uint limit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        generatePromoCodeThreshold = limit;
    }

     /**
     * @notice Allows public generate promocodes after they have purchased a certain number of licenses.
     * @param code The new state of the claimable variable.
     * @dev Only callable by public.
     */
    function generatePromocode(string calldata code) external {
        require(balanceOf(msg.sender) >= generatePromoCodeThreshold, "not authorized");
        require(accountPromoCodes[msg.sender].length == 0, "already generated");
        createPromoCode(code, msg.sender);
        emit PromoCodeGenerated(code, msg.sender);
    }


    /**
     * @notice Sets the referral discount and reward percentages.
     * @param _referralDiscountPercentage The referral discount percentage.
     * @param _referralRewardPercentage The referral reward percentage.
     * @dev The referral discount and reward percentages cannot be greater than 99.
     */
    function setPromoPercentages(
        uint256 _referralDiscountPercentage,
        uint256 _referralRewardPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_referralDiscountPercentage <= 99, "Referral discount percentage cannot be greater than 99");
        require(_referralRewardPercentage <= 99, "Referral reward percentage cannot be greater than 99");
        referralDiscountPercentage = _referralDiscountPercentage;
        referralRewardPercentage = _referralRewardPercentage;
        emit ReferralRewardPercentagesChanged(_referralDiscountPercentage, _referralRewardPercentage);
    }

    /**
     * @notice Sets or adds a pricing tier.
     * @param _index The index of the tier to set or add.
     * @param _price The price of the tier.
     * @param _quantity The quantity of the tier.
     */
    function setPricingTier(uint256 _index, uint256 _price, uint256 _quantity) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_index < pricingTiers.length) {
            // Subtract the quantity of the old tier from maxSupply
            maxSupply -= pricingTiers[_index].quantity;
            pricingTiers[_index] = Tier(_price, _quantity);
        } else if (_index == pricingTiers.length) {
            pricingTiers.push(Tier(_price, _quantity));
        } else {
            revert("Index out of bounds");
        }
        // Add the quantity of the new or updated tier to maxSupply
        maxSupply += _quantity;
        emit PricingTierSetOrAdded(_index, _price, _quantity);
    }
     /**
     * @notice Sets or adds a pricing tier.
     * @param _price The price of the tier.
     * @param _quantity The quantity of the tier.
     */
    function addPricingTier(uint256 _price, uint256 _quantity) public onlyRole(DEFAULT_ADMIN_ROLE) {
       setPricingTier(pricingTiers.length, _price, _quantity);
    }

    /**
     * @notice Returns the pricing tier at the given index.
     * @param _index The index of the tier.
     * @return The Tier at the given index.
     */
    function getPricingTier(uint256 _index) public view returns (Tier memory) {
        require(_index < pricingTiers.length, "Index out of bounds");
        return pricingTiers[_index];
    }

    function _updateWhitelistAmounts(address _account, uint16 _amount) internal {
        whitelist[_account] = _amount;
        emit WhitelistAmountUpdatedByAdmin(_account, _amount);
    }

    /**
     * @notice Admin function so set wallets and their free mint amounts. Set amount to 0 to remove from whitelist.
     * @param _accounts The addresses that can mint the amount for free.
     * @param _amounts The amounts that can be minted for free, if 0 the user is not whitelisted anymore.
     */
    function updateWhitelistAmounts(address[] memory _accounts, uint16[] memory _amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_accounts.length == _amounts.length, "Invalid input");
        for(uint16 i = 0; i < _accounts.length; i++){
            _updateWhitelistAmounts(_accounts[i], _amounts[i]);
        }
    }

    /**
     * @notice Returns the metadata of a NodeLicense token.
     * @param _tokenId The ID of the token.
     * @return The token metadata.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory json;
       {
        address ownerAddress = ownerOf(_tokenId);
        json = getJson(ownerAddress, getImage(ownerAddress, _tokenId, name()), _tokenId);
       }
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

   
    function getJson(address ownerAddress, string memory image, uint _tokenId) private view returns(string memory) {
        return Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "License #',
                        _tokenId.toString(),
                        '", "description": "',
                        name(),
                        ' token", "image": "data:image/svg+xml;base64,',
                        image,
                        '", "attributes": [{"trait_type": "Owner", "value": "',
                        Strings.toHexString(uint160(ownerAddress)),
                        '"}, {"trait_type": "Legal", "value": "https://mlayer.network/license-terms"}]}'
                    )
                )
            )
        );
    }

    function getImage(address ownerAddress, uint _tokenId, string memory name) private view returns(string memory) {
        return Base64.encode(bytes(string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' width='100' height='100' style='background-color:black;'><polygon points='50,0 0,86.6 100,86.6' fill='none' stroke='purple' stroke-width='20' transform='scale(0.1) translate(60, 60)'/>",
                "<text x='5' y='25' font-size='2.8' fill='white' font-family='monospace'>License Id: ",
                name,
                "</text><text x='5' y='30' font-size='2.8' fill='white' font-family='monospace'>License Id: ",
                _tokenId.toString(),
                "</text><text x='5' y='35' font-size='2.8' fill='white' font-family='monospace'>Owner: ",
                Strings.toHexString(uint160(ownerAddress)),
                "</text><text x='5' y='40' font-size='2.8' fill='white' font-family='monospace'>Mint Timestamp: ",
                mintTimestamps[_tokenId].toString(),
                "</text></svg>"
            )
        )));
    }

    /**
     * @notice Allows the admin to refund a NodeLicense.
     * @param _tokenId The ID of the token to refund.
     * @dev Only callable by the admin.
     */
    function refundNodeLicense(uint256 _tokenId) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_exists(_tokenId), "ERC721Metadata: Refund for nonexistent token");
        uint256 refundAmount = averagePrice[_tokenId];
        require(refundAmount > 0, "No funds to refund");
        averagePrice[_tokenId] = 0;
        (bool success, ) = payable(ownerOf(_tokenId)).call{value: refundAmount}("");
        require(success, "Transfer failed.");
        emit RefundOccurred(ownerOf(_tokenId), refundAmount);
        _burn(_tokenId);
    }

    function _exists(uint _tokenId) public view  returns(bool) {
        return _ownerOf(_tokenId)  != address(0x0);
    }
    /**
     * @notice Returns the average cost of a NodeLicense token. This is primarily used for refunds.
     * @param _tokenId The ID of the token.
     * @return The average cost.
     */
    function getAveragePrice(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721Metadata: Query for nonexistent token");
        return averagePrice[_tokenId];
    }

    /**
     * @notice Returns the minting timestamp of a NodeLicense token.
     * @param _tokenId The ID of the token.
     * @return The minting timestamp.
     */
    function getMintTimestamp(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ERC721Metadata: Query for nonexistent token");
        return mintTimestamps[_tokenId];
    }

    function getOwnedByAddress(address owner) public view returns(uint[] memory _tokenIds) {
        uint bal = balanceOf(owner);
        if (bal > 0) {
            _tokenIds = new uint256[](bal);
            for (uint i; i<bal; i++) {
                tokenOfOwnerByIndex(owner, i);
            }
        }
    }

    /**
     * @notice Overrides the supportsInterface function of the AccessControl contract.
     * @param interfaceId The interface id.
     * @return A boolean value indicating whether the contract supports the given interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId) || ERC721EnumerableUpgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Overrides the transfer function of the ERC721 contract to make the token non-transferable.
     * @param to The address to receive the token.
     * @param tokenId The token id.
     */
    function _update(
        address to,
        uint256 tokenId,
        address owner
    ) internal override returns (address)  {
        require(owner==address(0x0), "NodeLicense: transfer is not allowed" );
        return super._update(to, tokenId, owner);
    }

}
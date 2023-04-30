// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Proof_Of_Trade_Arbi_One is Ownable, Pausable {

    // Using

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // Global variables

    IERC20 public _usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address public _byBitAddress = 0x11668139AC2569b7bA34ee43Ccb13f3CEb55b098;
    address public _signerAddress = 0x75ffe67F97D9259c08A8a3F192625752AEE66269;

    mapping(bytes32 => bool) public _swapKey;

    // Events

    event UserDeposit(address indexed _address, string _userid, uint indexed _amount);
    event UserTradeType(string _userid, uint indexed _amount, uint indexed _tradeType);
    event RewardClaimed(address indexed _address, uint indexed _amount, string _data);

    // Admin functions

    function pauseProtocol() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseProtocol() external virtual onlyOwner whenPaused {
        _unpause();
    }

    function setUsdt(address usdt_) external onlyOwner {
        _usdt = IERC20(usdt_);
    }

    function setByBitAddress(address byBitAddress_) external onlyOwner {
        _byBitAddress = byBitAddress_;
    }

    function setSignerAddress(address signerAddress_) external onlyOwner {
        _signerAddress = signerAddress_;
    }

    // External and public functions

    function deposit(
        uint amount_,
        uint tradeType_,
        string memory id_
    ) external whenNotPaused {
        require(amount_ > 0, "Invalid amount");
        require(tradeType_ == 1 || tradeType_ == 2, "Invalid Trade Type");
        _usdt.safeTransferFrom(msg.sender, address(this), amount_);
        _usdt.safeTransfer(_byBitAddress, amount_);
        emit UserDeposit(msg.sender, id_, amount_);
        emit UserTradeType(id_, amount_, tradeType_);
    }

    function claim(
        string calldata timestamp_,
        bytes calldata signature_,
        uint amount_
    ) external whenNotPaused {
        require(amount_ > 0, "Invalid amount");
        bytes32 message =  getMessage(timestamp_, amount_, msg.sender);
        require(!_swapKey[message], "Key Already Claimed");
        require(isValidData(message, signature_), "Invalid Signature");
        _swapKey[message] = true;
        _usdt.safeTransfer(msg.sender, amount_);
        emit RewardClaimed(msg.sender, amount_, string.concat(string.concat(timestamp_, Strings.toString(amount_)), Strings.toHexString(uint256(uint160(msg.sender)), 20)));
    }

    function isValidData(
        bytes32 message_,
        bytes memory signature_
    ) public view returns (bool) {
        return message_
        .toEthSignedMessageHash()
        .recover(signature_) == _signerAddress;
    }

    function getMessage(
        string calldata timestamp_,
        uint amount_,
        address msgSender_
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(timestamp_, amount_, msgSender_));
    }
}
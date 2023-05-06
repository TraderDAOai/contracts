// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20Wrapper is IERC20 {
    function burn(uint256 amount) external;
}

contract  Liquidity_Wallet is Ownable, Pausable {
    using Address for address;
    using SafeERC20 for IERC20Wrapper;
    
    uint public UserIdCounter = 0;
    uint public Rate = 100;
    uint public Decimal = 10 ** 18;
    uint public Fee = 0; // min=1(0.01%) max=10000(100%)
    address public FeeRecipient = address(0);

    IERC20Wrapper public USDT = IERC20Wrapper(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20Wrapper public POT = IERC20Wrapper(0xa7e5F7471D673fCcd38606FCd6c3dCbdE807D95c);

    address public gov;

    event RedeemedAmount(address indexed _address, uint indexed _amount, uint indexed _returnAmount);
    
    constructor(){
        gov = msg.sender;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function SetUSDT(address _address) external onlyOwner{
        USDT = IERC20Wrapper(_address);
    }
    function SetPOT(address _address) external onlyOwner{
        POT = IERC20Wrapper(_address);
    }
    function SetRate(uint _rate) external{
        require(msg.sender == gov, "!gov");
        Rate = _rate;
    }
    function SetDecimal(uint _decimal) external{
        require(msg.sender == gov, "!gov");
        Decimal = _decimal;
    }
    function SetGov(address _address) external onlyOwner{
        gov = _address;
    }
    function SetFee(uint _fee) external{
        require(msg.sender == gov, "!gov");
        require(_fee >= 0 && _fee <= 10000, "fee range: 1 - 10000");
        Fee = _fee;
    }
    function SetFeeRecipient(address _feeRecipient) external{
        require(msg.sender == gov, "!gov");
        FeeRecipient = _feeRecipient;
    }

    function Claim(
        uint _amount
    ) external whenNotPaused returns (uint){
        require(_amount > 0, "Invalid fund");

        POT.safeTransferFrom(msg.sender, address(this), _amount);

        uint returnAmount = Convert(_amount);
        require(returnAmount > 0, "Invalid Conversion");

        // transfer fee USDT to FeeRecipient
        if (Fee > 0 && FeeRecipient != address(0)) {
            uint feeAmount = returnAmount * Fee / 10000;
            returnAmount = returnAmount - feeAmount;
            USDT.safeTransfer(FeeRecipient, feeAmount);
        }

        USDT.safeTransfer(msg.sender, returnAmount);
        POT.burn(_amount);
        emit RedeemedAmount(msg.sender, _amount, returnAmount);

        return returnAmount;
    }

    function Convert(uint _amount) public view returns(uint){
        uint returnAmount = _amount * Rate / Decimal;
        return returnAmount;
    }

    function Save(address _token, uint _amount) external onlyOwner{
        IERC20Wrapper(_token).safeTransfer(msg.sender, _amount);
    }
}
//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {TrusteeContract} from "./TrusteeContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract InheritanceManager {
    using SafeERC20 for IERC20;

    error NotOwner(address);
    error InsufficientBalance();
    error InactivityPeriodNotLongEnough();
    error InvalidBeneficiaries();
    error NotYetInherited();

    address owner;
    address[] beneficiaries;
    mapping(address target => bytes interaction) interactions;
    bool isInherited = false;
    uint256 deadline;


    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    modifier nonReentrant() {
        assembly{
            if tload(0) {revert(0, 0)}
            tstore(0, 1)
        }
        _;
        assembly{
            tstore(0, 0)
        }
    }


    function getDeadline() public view returns(uint256) {
        return deadline;
    }

    /**
     * @dev Sending ERC20 tokens out of the contract. Reentrancy safe, in case we interact with
     * malicious contracts.
     * @param _tokenAddress ERC20 token to send
     * @param _amount Amount of ERC20 to send
     * @param _to Address to send the ERC20 to
     */
    function sendERC20(address _tokenAddress, uint256 _amount, address _to) external nonReentrant onlyOwner {
        if(IERC20(_tokenAddress).balanceOf(address(this)) < _amount){
            revert InsufficientBalance();
        }
        IERC20(_tokenAddress).safeTransfer(_to, _amount);
        _setDeadline();
    }

    /**
     * @dev sends ETH out of the contract. Reentrancy safe, in case we interact with 
     * malicious contracts.
     * @param _amount amount in ETH to send
     * @param _to address to send ETH to
     */
    function sendETH(uint256 _amount, address _to) external nonReentrant onlyOwner {
        (bool success,) = _to.call{value: _amount }("");
        require(success, "Transfer Failed");
        _setDeadline();
    }

    function contractInteractions(address _target, bytes calldata _payload, uint256 _value,  bool _storeTarget) external onlyOwner {
        (bool success, bytes memory data) = _target.call{value: _value}(_payload);
        require(success, "interaction failed");
        if(_storeTarget){
            interactions[_target] = data;
        }
    }

    /**
     * @dev adds a beneficiary for possible inheritance of funds.
     * @param _beneficiary beneficiary address
     */
    function addBeneficiery(address _beneficiary) external onlyOwner {
        beneficiaries.push(_beneficiary);
        _setDeadline();
    }

    function removeBeneficiary(address _beneficiary) external onlyOwner {
        uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
        delete beneficiaries[indexToRemove];
    }

    function inherit() external {
        if(block.timestamp < getDeadline()) {
            revert InactivityPeriodNotLongEnough();
        }
        if(beneficiaries.length == 1) {
            owner = msg.sender;
            _setDeadline();
        } else if(beneficiaries.length > 1) {
            isInherited = true;
        } else {
            revert InvalidBeneficiaries();
        }
    }

    function withdrawInheritedFunds(address _asset) external {
        if(!isInherited) {
            revert NotYetInherited();
        }
        uint256 divisor = beneficiaries.length;
        if(_asset == address(0)) {
            uint256 ethAmountAvailable = address(this).balance;
            uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
            for(uint256 i = 0; i < divisor; i++) {
                address payable beneficiary = payable(beneficiaries[i]);
                (bool success, ) = beneficiary.call{value: amountPerBeneficiary}("");
                require(success, "something went wrong");
            }
        } else {
            uint256 assetAmountAvailable = IERC20(_asset).balanceOf(address(this));
            uint256 amountPerBeneficiary = assetAmountAvailable / divisor;
            for(uint256 i = 0; i < divisor; i++) {
                IERC20(_asset).safeTransfer(beneficiaries[i], amountPerBeneficiary);
            }
        }
    }

    function _setDeadline() internal {
        deadline = block.timestamp + 90 days;
    }

    function _getBeneficiaryIndex(address _beneficiary) internal view returns (uint256 _index) {
        for(uint256 i = 0; i < beneficiaries.length; i++) {
            if(_beneficiary == beneficiaries[i]){
                _index = i;
                break;
            }
        }
    }
}
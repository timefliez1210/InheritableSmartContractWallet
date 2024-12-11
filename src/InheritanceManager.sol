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

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner(msg.sender);
        }
        _;
    }

    /**
     * @dev gas efficient cross-function reentrancy lock using transient storage
     * @notice refer here: https://soliditylang.org/blog/2024/01/26/transient-storage/
     */
    modifier nonReentrant() {
        assembly {
            if tload(1) { revert(0, 0) }
            tstore(0, 1)
        }
        _;
        assembly {
            tstore(0, 0)
        }
    }

    function getDeadline() public view returns (uint256) {
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
        if (IERC20(_tokenAddress).balanceOf(address(this)) < _amount) {
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
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Transfer Failed");
        _setDeadline();
    }

    /**
     * @dev to allow the owner arbitrary calls to other contracts. e.g. deposit assets into Aave to earn yield, or swap tokens on exchanges
     * @notice allows transactions to be stored in interactions[] to make it clear to beneficiaries where to look for funds outside this contract
     * and potentially withdraw those. Obviously swaps would not need to be stored, therefor we give the option.
     * This function should generally only be used by very advanced users, and we assume appropriate diligence has to be done by owner.
     * @param _target address of the target contract
     * @param _payload bytes element with interaction instructions
     * @param _value value of ether to be send with the transaction
     * @param _storeTarget bool to decide if this transaction should be stored
     */
    function contractInteractions(address _target, bytes calldata _payload, uint256 _value, bool _storeTarget)
        external
        onlyOwner
        nonReentrant
    {
        (bool success, bytes memory data) = _target.call{value: _value}(_payload);
        require(success, "interaction failed");
        if (_storeTarget) {
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

    /**
     * @dev removes entries from beneficiaries in case inheritance gets revoked or
     * an address needs to be replaced (lost keys e.g.)
     * @param _beneficiary address to be removed from the array beneficiaries
     */
    function removeBeneficiary(address _beneficiary) external onlyOwner {
        uint256 indexToRemove = _getBeneficiaryIndex(_beneficiary);
        delete beneficiaries[indexToRemove];
    }

    /**
     * @dev manages the inheritance of this wallet either
     * 1. the owner lost his keys and wants to reclaim this contract from beneficiaries slot0
     * 2. the owner was inactive more than 90 days and heirs will claim remaining funds.
     */
    function inherit() external {
        if (block.timestamp < getDeadline()) {
            revert InactivityPeriodNotLongEnough();
        }
        if (beneficiaries.length == 1) {
            owner = msg.sender;
            _setDeadline();
        } else if (beneficiaries.length > 1) {
            isInherited = true;
        } else {
            revert InvalidBeneficiaries();
        }
    }

    /**
     * @dev called by the beneficiaries to disperse remaining assets within the contract in equal parts.
     * @notice use address(0) to disperse ether
     * @param _asset asset address to disperse
     */
    function withdrawInheritedFunds(address _asset) external {
        if (!isInherited) {
            revert NotYetInherited();
        }
        uint256 divisor = beneficiaries.length;
        if (_asset == address(0)) {
            uint256 ethAmountAvailable = address(this).balance;
            uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
            for (uint256 i = 0; i < divisor; i++) {
                address payable beneficiary = payable(beneficiaries[i]);
                (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
                require(success, "something went wrong");
            }
        } else {
            uint256 assetAmountAvailable = IERC20(_asset).balanceOf(address(this));
            uint256 amountPerBeneficiary = assetAmountAvailable / divisor;
            for (uint256 i = 0; i < divisor; i++) {
                IERC20(_asset).safeTransfer(beneficiaries[i], amountPerBeneficiary);
            }
        }
    }

    /**
     * @dev internal helper function to be called at contract creation and every owner controlled event/function call
     * to resett the timer off inactivity.
     */
    function _setDeadline() internal {
        deadline = block.timestamp + 90 days;
    }

    /**
     * @dev takes beneciciary address and returns index as a helper function for removeBeneficiary
     * @param _beneficiary address to fetch the index for
     */
    function _getBeneficiaryIndex(address _beneficiary) internal view returns (uint256 _index) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            if (_beneficiary == beneficiaries[i]) {
                _index = i;
                break;
            }
        }
    }
}

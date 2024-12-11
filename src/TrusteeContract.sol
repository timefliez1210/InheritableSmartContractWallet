//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

abstract contract TrusteeContract {
    error NotTrustee(address);

    address trustee;

    mapping(uint256 NftIndex => uint256 value) nftValue;

    modifier onlyTrustee() {
        if (msg.sender != trustee) {
            revert NotTrustee(msg.sender);
        }
        _;
    }

    function setNftValue(uint256 _index, uint256 _value) external onlyTrustee {
        nftValue[_index] = _value;
    }
}

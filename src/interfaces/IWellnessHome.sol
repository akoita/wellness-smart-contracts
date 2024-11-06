// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IWellnessHome {
    function isPartner(address partner) external view returns (bool);

    function isUser(address user) external view returns (bool);
}
